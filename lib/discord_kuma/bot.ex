defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.Util
  require Logger

  handle :MESSAGE_CREATE do
    command = msg.content |> String.split |> List.first

    enforce do
      case command do
        "!kuma" ->
          IO.inspect msg
          reply "Kuma~!"

        "!setup" ->
          cond do
            db == nil ->
              store_data("guilds", guild_id, %{log_channel: nil, admin_roles: []})
              reply "Hiya! Be sure to add an admin role to manage my settings using `!addrole <role>` and set a log channel for me to output messages to using `!setlog <channel>`."
            db.admin_roles == [] -> reply "No admin roles set, anyone can edit my settings! Change this with `!addrole <role>`."
            db.log_channel == nil -> reply "You need to set a log channel! Do this with `!setlog <channel>`."
            true -> reply "I'm ready to sortie!"
          end

        "!addrole" ->
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
                  reply "Updated roles!"
              end
          end

        "!delrole" ->
          role_ids = msg.mention_roles

          case role_ids do
            [] -> reply "You didn't specify any roles."
            role_ids ->
              case db.admin_roles do
                [] -> reply "There aren't any roles to remove..."
                admin_roles ->
                  db = Map.put(db, :admin_roles, admin_roles -- role_ids |> Enum.uniq)
                  store_data("guilds", guild_id, db)
                  reply "Updated roles!"
              end
          end

        "!setlog" ->
          channel_id = pull_id(msg.content)

          case channel_id do
            nil -> reply "You didn't specify a channel."
            channel_id ->
              case db.log_channel do
                nil ->
                  db = Map.put(db, :log_channel, channel_id)
                  store_data("guilds", guild_id, db)
                  reply "Set channel!"
                log_channel ->
                  cond do
                    log_channel == channel_id ->
                      reply "That's already the channel."
                    true ->
                      db = Map.put(db, :log_channel, channel_id)
                      store_data("guilds", guild_id, db)
                      reply "Set channel!"
                  end
              end
          end

        _ -> :ignore
      end
    end

    case command do
      "!coin" -> reply Enum.random(["Heads.", "Tails."])

      "!predict" ->
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

      "!smug" ->
        url = "https://api.imgur.com/3/album/zSNC1"
        auth = %{"Authorization" => "Client-ID #{Application.get_env(:discord_kuma, :imgur_client_id)}"}

        request = HTTPoison.get!(url, auth)
        response = Poison.Parser.parse!((request.body), keys: :atoms)
        result = response.data.images |> Enum.random

        reply result.link

      "!message" ->
        url = "http://souls.riichi.me/api"
        request = HTTPoison.get!(url)
        response = Poison.Parser.parse!((request.body), keys: :atoms)

        reply "#{response.message}"
      _ -> :ignore
    end

    cond do
      msg.content in ["hello", "hi", "hey", "sup"] ->
        replies = ["sup loser", "yo", "ay", "hi", "wassup"]
        if one_to(25) do
          reply Enum.random(replies)
        end
      msg.content in ["same", "Same", "SAME"] ->
        if one_to(25) do
          reply "same"
        end
      msg.content in ["ty kuma", "thanks kuma", "thank you kuma"] ->
        replies = ["np", "don't mention it", "anytime", "sure thing", "ye whateva"]
        reply Enum.random(replies)
      true -> nil
    end
  end

  handle :TYPING_START, do: nil

  handle :PRESENCE_UPDATE, do
    IO.inspect msg
    # Logger.info "[presence] #{msg.game.name}"
  end

  handle event do
    Logger.info "[event] :#{event}"
    IO.inspect msg
  end
end
