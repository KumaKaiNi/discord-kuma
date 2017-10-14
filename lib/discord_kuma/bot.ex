defmodule DiscordKuma.Bot do
  use Din.Module
  alias Din.Resources.{Channel, Guild}
  import DiscordKuma.{Announce, Util}

  handle :message_create do
    match "!kuma" do
      require Logger

      channel = Channel.get(data.channel_id)
      guild = Guild.get(channel.guild_id)

      Logger.debug "from: #{guild.name} \##{channel.name}"
      IO.inspect data

      reply "Kuma~!"
    end

    match "!link", do: reply link_twitch_account(data)

    enforce :admin do
      match "!announce here", do: reply set_log_channel(data)
      match "!announce stop", do: reply del_log_channel(data)
    end

    # make_call(data)
  end

  handle :presence_update, do: announce(data)

  handle_fallback()

  defp link_twitch_account(data) do
    case data.content |> String.split |> length do
      1 -> "Usage: `!link <twitch username>`"
      _ ->
        [_ | [twitch_account | _]] = data.content |> String.split
        twitch_account = twitch_account |> String.downcase

        user = query_data(:links, data.author.id)
        all_users = query_data(:links, :users)

        case user do
          nil ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                "That username has already been taken."
              true ->
                all_users = all_users ++ [twitch_account]
                store_data(:links, data.author.id, twitch_account)
                store_data(:links, :users, all_users)
                "Twitch account linked!"
            end
          user ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                "That username has already been taken."
              true ->
                all_users = (all_users -- [user]) ++ [twitch_account]
                store_data(:links, data.author.id, twitch_account)
                store_data(:links, :users, all_users)
                "Twitch account updated!"
            end
        end
    end
  end

  defp make_call(data) do
    require Logger

    channel = Channel.get(data.channel_id)
    guild = Guild.get(channel.guild_id)

    message = %{
      auth: Application.get_env(:discord_kuma, :server_auth),
      type: "message",
      content: %{
        source: %{
          protocol: "discord",
          guild: %{name: guild.name, id: guild.id},
          channel: %{
            name: channel.name,
            id: data.channel_id,
            private: private(data),
            nsfw: nsfw(data)}},
        user: %{
          id: data.author.id,
          avatar: data.author.avatar,
          name: data.author.username,
          moderator: admin(data)},
        message: %{
          text: data.content,
          id: data.id}}} |> Poison.encode!

    conn = :gen_tcp.connect({127,0,0,1}, 5862, [:binary, packet: 0, active: false])

    case conn do
      {:ok, socket} ->
        case :gen_tcp.send(socket, message) do
          :ok ->
            case :gen_tcp.recv(socket, 0) do
              {:ok, response} ->
                case response |> Poison.Parser.parse!(keys: :atoms) do
                  %{reply: true, response: %{text: text, image: image}} ->
                    reply text, embed: %{
                      color: 0x00b6b6,
                      title: image.referrer,
                      url: image.source,
                      description: image.description,
                      image: %{url: image.url},
                      timestamp: "#{DateTime.utc_now() |> DateTime.to_iso8601()}"}
                  %{reply: true, response: %{text: text}} -> reply text
                  _ -> nil
                end
              {:error, reason} -> Logger.error "Receive error: #{reason}"
            end
          {:error, reason} -> Logger.error "Send error: #{reason}"
        end

        :gen_tcp.close(socket)
      {:error, reason} -> Logger.error "Connection error: #{reason}"
    end
  end

  defp admin(data) do
    user_id = data.author.id
    rekyuu_id = 107977662680571904

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
                {role_id, _} = role |> Integer.parse
                Enum.member?(db.admin_roles, role_id)
              end, true)
            end
        end
    end
  end

  defp private(data) do
    Channel.get(data.channel_id).guild_id == nil
  end

  defp nsfw(data) do
    channel = Channel.get(data.channel_id)

    case channel.nsfw do
      nil -> true
      nsfw -> nsfw
    end
  end
end
