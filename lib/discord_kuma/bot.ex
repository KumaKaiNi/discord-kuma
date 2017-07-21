defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.Util
  require Logger

  # Enforcers
  def admin(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    user_id = msg.author.id
    {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)
    rekyuu_id = 107977662680571904

    db = query_data("guilds", guild_id)

    is_admin = cond do
      db == nil -> false
      db.admin_roles == [] -> false
      true -> Enum.member?(for role <- member["roles"] do
        {role_id, _} = role |> Integer.parse
        Enum.member?(db.admin_roles, role_id)
      end, true)
    end

    cond do
      is_admin -> true
      msg.author.id == rekyuu_id -> true
      true -> false
    end
  end

  def rate_limit(msg) do
    command = msg.content |> String.split |> List.first
    {rate, _} = ExRated.check_rate(command, 10_000, 1)

    case rate do
      :ok    -> true
      :error -> false
    end
  end

  # Event handlers
  handle :MESSAGE_CREATE do
    enforce :rate_limit do
      match "!help", do: reply "https://github.com/KumaKaiNi/discord-kuma"
      match "!uptime", :uptime
      match "!time", :local_time
      match ["!coin", "!flip"], do: reply Enum.random(["Heads.", "Tails."])
      match "!predict", :prediction
      match "!smug", :smug
      match "!np", :lastfm_np
      match "!guidance", :souls_message
      match "!quote", :get_quote
      match ["ty kuma", "thanks kuma", "thank you kuma"], :ty_kuma
      match_all :custom_command
    end

    match ["hello", "hi", "hey", "sup"], :hello

    enforce :admin do
      match "!kuma", :kuma
      match "!setup", :setup
      match "!addrole", :add_role
      match "!delrole", :del_role
      match "!setlog", :set_log_channel
      match "!add", :add_custom_command
      match "!del", :del_custom_command
      match "!addquote", :add_quote
      match "!delquote", :del_quote
    end
  end

  handle :PRESENCE_UPDATE do
    guild_id = msg.guild_id |> Integer.to_string
    user_id = msg.user.id
    {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)
    username = member["user"]["username"]

    if msg.game do
      if msg.game.type do
        if msg.game.type == 1 do
          stream_title = msg.game.name
          stream_url = msg.game.url
          log_chan = query_data("guilds", guild_id).log

          stream_list = query_data("streams", guild_id)

          stream_list = case stream_list do
            nil -> []
            streams -> streams
          end

          unless Enum.member?(stream_list, user_id) do
            store_data("streams", guild_id, stream_list ++ [user_id])

            case user_id do
              107977662680571904 ->
                reply "@here **#{username}** is now live!\n#{stream_title}\n#{stream_url}", chan: log_chan
              _ ->
                reply "**#{username}** is now live!\n#{stream_title}\n#{stream_url}", chan: log_chan
            end
          end
        end
      end
    end

    unless msg.game do
      stream_list = query_data("streams", guild_id)

      stream_list = case stream_list do
        nil -> []
        streams -> streams
      end

      if Enum.member?(stream_list, user_id) do
        store_data("streams", guild_id, stream_list -- [user_id])
      end
    end
  end

  handle _event, do: nil

  # Rate limited user commands
  def help(msg), do: reply "https://github.com/KumaKaiNi/discord-kuma"

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

  def prediction(msg) do
    predictions = [
      "It is certain.",
      "It is decidedly so.",
      "Without a doubt.",
      "Yes, definitely.",
      "You may rely on it.",
      "As I see it, yes.",
      "Most likely.",
      "Outlook good.",
      "Yes.",
      "Signs point to yes.",
      "Reply hazy, try again.",
      "Ask again later.",
      "Better not tell you now.",
      "Cannot predict now.",
      "Concentrate and ask again.",
      "Don't count on it.",
      "My reply is no.",
      "My sources say no.",
      "Outlook not so good.",
      "Very doubtful."
    ]

    reply Enum.random(predictions)
  end

  def smug(msg) do
    url = "https://api.imgur.com/3/album/zSNC1"
    auth = %{"Authorization" => "Client-ID #{Application.get_env(:discord_kuma, :imgur_client_id)}"}

    request = HTTPoison.get!(url, auth)
    response = Poison.Parser.parse!((request.body), keys: :atoms)
    result = response.data.images |> Enum.random

    reply result.link
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

  def souls_message(msg) do
    url = "http://souls.riichi.me/api"
    request = HTTPoison.get!(url)
    response = Poison.Parser.parse!((request.body), keys: :atoms)

    reply "#{response.message}"
  end

  def get_quote(msg) do
    {quote_id, quote_text} = case length(msg.content |> String.split) do
      1 ->
        quotes = query_all_data(:quotes)
        Enum.random(quotes)
      _ ->
        [_ | [quote_id | _]] = msg.content |> String.split

        case quote_id |> Integer.parse do
          {quote_id, _} ->
            case query_data(:quotes, quote_id) do
              nil -> {"65535", "Quote does not exist. - KumaKaiNi, 2017"}
              quote_text -> {quote_id, quote_text}
            end
          :error ->
            quotes = query_all_data(:quotes)
            Enum.random(quotes)
        end
    end

    reply "[\##{quote_id}] #{quote_text}"
  end

  def custom_command(msg) do
    action = query_data(:commands, msg.content |> String.split |> List.first)

    case action do
      nil -> nil
      action -> reply action
    end
  end

  def ty_kuma(msg) do
    replies = ["np", "don't mention it", "anytime", "sure thing", "ye whateva"]
    reply Enum.random(replies)
  end

  # Random replies
  def hello(msg) do
    replies = ["sup loser", "yo", "ay", "hi", "wassup"]

    if one_to(25) do
      reply Enum.random(replies)
    end
  end

  # Administrative commands
  def kuma(msg) do
    IO.inspect msg
    reply [content: "Kuma~!", embed: %Nostrum.Struct.Embed{color: 1, description: "description", footer: "footer", image: %Nostrum.Struct.Embed.Image{url: "https://static-cdn.jtvnw.net/jtv_user_pictures/950f5a7f09073327-profile_image-300x300.png"}, thumbnail: %Nostrum.Struct.Embed.Thumbnail{url: "https://static-cdn.jtvnw.net/jtv_user_pictures/950f5a7f09073327-profile_image-300x300.png"}, title: "title", url: "https://riichi.me"}]
  end

  def setup(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    db = query_data("guilds", guild_id)

    cond do
      db == nil ->
        store_data("guilds", guild_id, %{admin_roles: []})
        reply "Hiya! Be sure to add an admin role to manage my settings using `!addrole <role>`."
      db.admin_roles == [] -> reply "No admin roles set, anyone can edit my settings! Change this with `!addrole <role>`."
      true -> reply "I'm ready to sortie!"
    end
  end

  def add_role(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    db = query_data("guilds", guild_id)
    role_ids = msg.mention_roles

    case role_ids do
      [] -> reply "You didn't specify any roles."
      role_ids ->
        case db.admin_roles do
          [] ->
            db = Map.put(db, :admin_roles, role_ids)
            store_data("guilds", guild_id, db)
            reply "Added roles!"
          admin_roles ->
            db = Map.put(db, :admin_roles, admin_roles ++ role_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Added administrative roles!"
        end
    end
  end

  def del_role(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    role_ids = msg.mention_roles
    db = query_data("guilds", guild_id)

    case role_ids do
      [] -> reply "You didn't specify any roles."
      role_ids ->
        case db.admin_roles do
          [] -> reply "There aren't any roles to remove..."
          admin_roles ->
            db = Map.put(db, :admin_roles, admin_roles -- role_ids |> Enum.uniq)
            store_data("guilds", guild_id, db)
            reply "Removed administrative roles."
        end
    end
  end

  def set_log_channel(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    db = query_data("guilds", guild_id)

    db = Map.put(db, :log, msg.channel_id)
    store_data("guilds", guild_id, db)
    reply "Okay, I will announce streams here!"
  end

  def add_custom_command(msg) do
    [_ | [command | action]] = msg.content |> String.split
    action = action |> Enum.join(" ")

    exists = query_data(:commands, "!#{command}")
    store_data(:commands, "!#{command}", action)

    case exists do
      nil -> reply "Alright! Type !#{command} to use."
      _   -> reply "Done, command !#{command} updated."
    end
  end

  def del_custom_command(msg) do
    [_ | [command | _]] = msg.content |> String.split
    action = query_data(:commands, "!#{command}")

    case action do
      nil -> reply "Command does not exist."
      _   ->
        delete_data(:commands, "!#{command}")
        reply "Command !#{command} removed."
    end
  end

  def add_quote(msg) do
    [_ | quote_text] = msg.content |> String.split
    quote_text = quote_text |> Enum.join(" ")

    quotes = case query_all_data(:quotes) do
      nil -> nil
      quotes -> quotes |> Enum.sort
    end

    quote_id = case quotes do
      nil -> 1
      _ ->
        {quote_id, _} = List.last(quotes)
        quote_id + 1
    end

    store_data(:quotes, quote_id, quote_text)
    reply "Quote added! #{quote_id} quotes total."
  end

  def del_quote(msg) do
    [_ | [quote_id | _]] = msg.content |> String.split

    case quote_id |> Integer.parse do
      {quote_id, _} ->
        case query_data(:quotes, quote_id) do
          nil -> reply "Quote \##{quote_id} does not exist."
          _ ->
            delete_data(:quotes, quote_id)
            reply "Quote removed."
        end
      :error -> reply "You didn't specify an ID number."
    end
  end
end
