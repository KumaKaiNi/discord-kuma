defmodule DiscordKuma.Bot do
  use Din.Module
  alias Din.Resources.{Channel, Guild}
  import DiscordKuma.{Announce, Tourney, Util}

  handle :message_create do
    enforce :private do
      match "!link", :link_twitch_account
    end
    
    match "!avatar", :avatar
    match "!tourney", :tourney_command

    enforce :admin do
      match "!announce here", :set_log_channel
      match "!announce stop", :del_log_channel
    end

    unless data.author.username == "KumaKaiNi" do
      make_call(data)
    end
  end

  handle :presence_update, do: announce(data)

  handle_fallback()

  defp link_twitch_account(data) do
    case data.content |> String.split |> length do
      1 -> reply "Usage: `!link <twitch username>`"
      _ ->
        [_ | [twitch_account | _]] = data.content |> String.split
        twitch_account = twitch_account |> String.downcase

        user = query_data(:links, data.author.id)
        all_users = query_data(:links, :users)

        case user do
          nil ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                reply "That username has already been taken."
              true ->
                all_users = all_users ++ [twitch_account]
                store_data(:links, data.author.id, twitch_account)
                store_data(:links, :users, all_users)
                reply "Twitch account linked!"
            end
          user ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                reply "That username has already been taken."
              true ->
                all_users = (all_users -- [user]) ++ [twitch_account]
                store_data(:links, data.author.id, twitch_account)
                store_data(:links, :users, all_users)
                reply "Twitch account updated!"
            end
        end
    end
  end
  
  defp avatar(data) do
    user = data.mentions |> List.first
    avatar_url = 
      "https://cdn.discordapp.com/avatars/#{user.id}/#{user.avatar}?size=1024"
      
    reply "", embed: %{
      color: 0x00b6b6,
      image: %{url: avatar_url}}
  end

  defp tourney_command(data) do
    [_ | participants_raw] = data.content |> String.split

    case participants_raw do
      [] -> nil
      participants_raw ->
        participants = participants_raw |> Enum.join(" ") |> String.split(", ")

        cond do
          length(participants) <= 2 -> reply "Just use pick??"
          true ->
            :ets.new(:tourney, [:named_table])
            :ets.insert(:tourney, {"temp", []})

            rounds = bracket(participants)
            script = tourney(rounds)

            reply "```\n#{script}\n```"
        end
    end
  end

  defp make_call(data) do
    require Logger

    channel = Channel.get(data.channel_id)

    {guild, channel} = cond do
      private(data) -> {
        %{id: nil, name: nil}, 
        Map.put(channel, :name, data.author.username)
      }
      true -> {Guild.get(channel.guild_id), channel}
    end

    message = %{
      protocol: "discord",
      guild: %{id: guild.id, name: guild.name},
      channel: %{
        id: data.channel_id, 
        name: channel.name, 
        private: private(data), 
        nsfw: nsfw(data)
      },
      user: %{
        id: data.author.id,
        avatar: data.author.avatar,
        name: data.author.username,
        moderator: admin(data)
      },
      message: %{id: data.id, text: data.content, image: nil}
    } |> Poison.encode!

    headers = %{
      "Authorization" => Application.get_env(:discord_kuma, :server_auth),
      "Content-Type"  => "application/json"
    }
    
    request = 
      HTTPoison.post!("http://kuma.riichi.me/api", message, headers, [recv_timeout: 10_000])
      |> Map.fetch!(:body)
      |> parse()

    case request do
      nil  -> nil
      response_data -> 
        case response_data.response do
          %{text: text, image: image} ->
            reply text, embed: %{
              color: 0x00b6b6,
              title: image.referrer,
              url: image.source,
              description: image.description,
              image: %{url: image.url},
              timestamp: "#{DateTime.utc_now() |> DateTime.to_iso8601()}"}
          %{text: text} -> reply text
          response_data -> IO.inspect response_data, label: "unknown response"
        end
    end
  end

  defp admin(data) do
    user_id = data.author.id
    rekyuu_id = "107977662680571904"

    cond do
      user_id == rekyuu_id -> true
      true ->
        cond do
          private(data) -> false
          true ->            
            guild_id = Channel.get(data.channel_id).guild_id

            case guild_id do
              nil -> false
              guild_id ->
                member = Guild.get_member(guild_id, user_id)

                db = query_data("guilds", guild_id)

                cond do
                  db == nil -> false
                  db.admin_roles == [] -> false
                  true -> Enum.member?(for role <- member.roles do
                    Enum.member?(db.admin_roles, role)
                  end, true)
                end
            end
        end
    end
  end

  defp private(data) do
    Map.get(Channel.get(data.channel_id), :guild_id) == nil
  end

  defp nsfw(data) do
    channel = Channel.get(data.channel_id)

    cond do
      private(data) -> true
      true -> 
        case channel.nsfw do
          nil -> true
          nsfw -> nsfw
        end
    end
  end

  def get_channel_and_guild_names(data) do
    channel = Channel.get(data.channel_id)

    cond do
      private(data) -> {"private,", data.author.username}
      true -> {Guild.get(channel.guild_id).name, "\##{channel.name}"}
    end
  end

  def parse(map) do
    case map do
      "" -> nil
      map -> 
        try do
          Poison.Parser.parse!(map, keys: :atoms)
        rescue
          error -> 
            IO.inspect map, label: "error with response"
            IO.inspect error, label: "error"
            nil
        end
    end
  end
end
