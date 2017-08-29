defmodule DiscordKuma.Commands.Announce do
  import DiscordKuma.{Module, Util}

  def announce(msg) do
    guild_id = msg.guild_id |> Integer.to_string
    user_id = msg.user.id
    {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)
    username = member["user"]["username"]

    if msg.game do
      if msg.game.type do
        case msg.game.type do
          0 -> remove_streamer(guild_id, user_id)
          1 ->
            stream_title = msg.game.name
            stream_url = msg.game.url
            twitch_username = msg.game.url |> String.split("/") |> List.last
            log_chan = query_data("guilds", guild_id).log

            stream_list = query_data("streams", guild_id)

            stream_list = case stream_list do
              nil -> []
              streams -> streams
            end

            unless Enum.member?(stream_list, user_id) do
              store_data("streams", guild_id, stream_list ++ [user_id])

              message = case user_id do
                107977662680571904 -> "**#{username}** is now live on Twitch! @here"
                _ -> "**#{username}** is now live on Twitch!"
              end

              twitch_user = "https://api.twitch.tv/kraken/users?login=#{twitch_username}"
              headers = %{"Accept" => "application/vnd.twitchtv.v5+json", "Client-ID" => "#{Application.get_env(:discord_kuma, :twitch_client_id)}"}

              request = HTTPoison.get!(twitch_user, headers)
              response = Poison.Parser.parse!((request.body), keys: :atoms)
              user = response.users |> List.first

              user_channel = "https://api.twitch.tv/kraken/channels/#{user._id}"
              user_info_request = HTTPoison.get!(user_channel, headers)
              user_info_response = Poison.Parser.parse!((user_info_request.body), keys: :atoms)

              game = case user_info_response.game do
                nil -> "streaming on Twitch.tv"
                game -> "playing #{game}"
              end

              reply [content: message, embed: %Nostrum.Struct.Embed{
                color: 0x4b367c,
                title: "#{twitch_username} #{game}",
                url: "#{stream_url}",
                description: "#{stream_title}",
                thumbnail: %Nostrum.Struct.Embed.Thumbnail{url: "#{user.logo}"},
                timestamp: "#{DateTime.utc_now() |> DateTime.to_iso8601()}"
              }], chan: log_chan
            end
        end
      end
    end

    unless msg.game, do: remove_streamer(guild_id, user_id)
  end

  defp remove_streamer(guild_id, user_id) do
    stream_list = query_data("streams", guild_id)

    stream_list = case stream_list do
      nil -> []
      streams -> streams
    end

    if Enum.member?(stream_list, user_id) do
      store_data("streams", guild_id, stream_list -- [user_id])
    end
  end

  def set_log_channel(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, msg.channel_id)
    store_data("guilds", guild_id, db)
    reply "Okay, I will announce streams here!"
  end

  def del_log_channel(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, nil)
    store_data("guilds", guild_id, db)
    reply "Okay, I will no longer announce streams."
  end
end
