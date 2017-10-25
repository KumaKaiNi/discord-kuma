defmodule DiscordKuma.Bot do
  use Din.Module
  alias Din.Resources.{Channel, Guild}
  import DiscordKuma.{Announce, Util}

  handle :message_create do
    enforce :private do
      match "!link", :link_twitch_account
    end

    enforce :admin do
      match "!kuma" do
        require Logger

        {guild, channel_name} = get_channel_and_guild_names(data)
        Logger.info "from: #{guild} #{channel_name}"
        IO.inspect data

        reply "Kuma~!"
      end

      match "!announce here", :set_log_channel
      match "!announce stop", :del_log_channel
    end

    make_call(data)
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

  defp make_call(data) do
    require Logger

    channel = Channel.get(data.channel_id)

    guild = cond do
      private(data) -> %{id: nil, name: "private"}
      true -> Guild.get(channel.guild_id)
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
      HTTPoison.post!("http://kuma.riichi.me/api", message, headers)
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

  defp private(data) do
    Map.get(Channel.get(data.channel_id), :guild_id) == nil
  end

  defp nsfw(data) do
    channel = Channel.get(data.channel_id)

    case channel.nsfw do
      nil -> true
      nsfw -> nsfw
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
      map -> Poison.Parser.parse!(map, keys: :atoms)
    end
  end
end
