defmodule DiscordKuma.Announce do
  import DiscordKuma.Util
  import Din.Module, only: [reply: 1]
  alias Din.Resources.{Channel, Guild}

  def announce(data) do
    guild_id = data.guild_id
    user_id = data.user.id
    member = Guild.get_member(guild_id, user_id)
    username = member.user.username

    if data.game do
      if data.game.type do
        case data.game.type do
          0 -> remove_streamer(guild_id, user_id)
          1 ->
            {rate, _} = ExRated.check_rate({guild_id, user_id}, 3_600_000, 1)

            case rate do
              :ok ->
                stream_title = data.game.name
                stream_url = data.game.url
                twitch_username = stream_url |> String.split("/") |> List.last
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

                  Channel.create_message log_chan, message, embed: %{
                    color: 0x4b367c,
                    title: "#{twitch_username} #{game}",
                    url: "#{stream_url}",
                    description: "#{stream_title}",
                    thumbnail: %{url: "#{user.logo}"},
                    timestamp: "#{DateTime.utc_now() |> DateTime.to_iso8601()}"
                  }
                end
              :error -> nil
            end
        end
      end
    end

    unless data.game, do: remove_streamer(guild_id, user_id)
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

  def set_log_channel(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, data.channel_id)
    store_data("guilds", guild_id, db)
    reply "Okay, I will announce streams here!"
  end

  def del_log_channel(data) do
    guild_id = Channel.get(data.channel_id).guild_id
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, nil)
    store_data("guilds", guild_id, db)
    reply "Okay, I will no longer announce streams."
  end
end
