defmodule DiscordKuma.Commands.Stream do
  import DiscordKuma.{Module, Util}

  def uptime(msg) do
    url = "https://decapi.me/twitch/uptime?channel=rekyuus"
    request =  HTTPoison.get! url

    case request.body do
      "rekyuus is offline" -> reply "Stream is not online!"
      time -> reply "Stream has been live for #{time}."
    end
  end

  def local_time(msg) do
    {{_, _, _}, {hour, minute, _}} = :calendar.local_time

    h = cond do
      hour <= 9 -> "0#{hour}"
      true      -> "#{hour}"
    end

    m = cond do
      minute <= 9 -> "0#{minute}"
      true        -> "#{minute}"
    end

    reply "It is #{h}:#{m} MST rekyuu's time."
  end

  def lastfm_np(msg) do
    timeframe = :os.system_time(:seconds) - 180
    url = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=rekyuu&api_key=#{Application.get_env(:discord_kuma, :lastfm_key)}&format=json&limit=1&from=#{timeframe}"

    request = HTTPoison.get!(url)
    response = Poison.Parser.parse!((request.body), keys: :atoms)
    track = response.recenttracks.track

    case List.first(track) do
      nil -> nil
      song -> reply "#{song.artist.'#text'} - #{song.name} [#{song.album.'#text'}]"
    end
  end
end
