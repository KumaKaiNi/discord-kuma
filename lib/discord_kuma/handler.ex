defmodule DiscordKuma.Handler do
  require Logger
  use DiscordKuma.Module
  import DiscordKuma.Util

  handle :message_create do
    enforce do
      command "!kuma", do: reply "Kuma ~"

      command "!setup" do
        cond do
          data == nil ->
            store_data("guilds", guild_id, %{log_channel: nil, admin_roles: []})
            reply "Hiya! Be sure to add an admin role to manage my settings using `!addrole <role>` and set a log channel for me to output messages to using `!setlog <channel>`."
          data.admin_roles == [] -> reply "No admin roles set, anyone can edit my settings! Change this with `!addrole <role>`."
          data.log_channel == nil -> reply "You need to set a log channel! Do this with `!setlog <channel>`."
          true -> reply "I'm ready to sortie!"
        end
      end

      command "!addrole" do
        role_id = pull_id(message)

        case role_id do
          nil -> reply "You didn't specify a role."
          role_id ->
            case data.admin_roles do
              [] ->
                data = Map.put(data, :admin_roles, [role_id])
                store_data("guilds", guild_id, data)
                reply "Added role!"
              admin_roles ->
                cond do
                  Enum.member?(admin_roles, role_id) ->
                    reply "That role is already added."
                  true ->
                    data = Map.put(data, :admin_roles, admin_roles ++ [role_id])
                    store_data("guilds", guild_id, data)
                    reply "Added role!"
                end
            end
        end
      end

      command "!delrole" do
        role_id = pull_id(message)

        case role_id do
          nil -> reply "You didn't specify a role."
          role_id ->
            cond do
              Enum.member?(data.admin_roles, role_id) ->
                data = Map.put(data, :admin_roles, data.admin_roles -- [role_id])
                store_data("guilds", guild_id, data)
                reply "Removed role."
              true ->
                reply "That role is not added."
            end
        end
      end

      command ["!setlog", "!setchan"] do
        channel_id = pull_id(message)

        case channel_id do
          nil -> reply "You didn't specify a channel."
          channel_id ->
            case data.log_channel do
              nil ->
                data = Map.put(data, :log_channel, channel_id)
                store_data("guilds", guild_id, data)
                reply "Set channel!"
              log_channel ->
                cond do
                  log_channel == channel_id ->
                    reply "That's already the channel."
                  true ->
                    data = Map.put(data, :log_channel, channel_id)
                    store_data("guilds", guild_id, data)
                    reply "Set channel!"
                end
            end
        end
      end
    end

    command "!help" do
      reply "First ship of the Kuma-class light cruisers, Kuma, kuma.\n"
      <> "Born in Sasebo, kuma. I got some old parts, but I'll try my best, kuma.\n"
      <> "\n"
      <> "`!coin` - flips a coin.\n"
      <> "`!pick` - picks a random item from a list.\n"
      <> "`!say` - repeats what you say.\n"
      <> "`!dan` - returns a random recent image using a two tags.\n"
      <> "`!safe` - returns a random recent image using a one tag and `rating:safe`.\n"
      <> "`!lewd` - returns a random recent image using a one tag and `-rating:safe`.\n"
      <> "`!smug` - sends a smug anime girl.\n"
      <> "\n"
      <> "Add me to your own server! https://discordapp.com/oauth2/authorize?client_id=234548552053817345&scope=bot&permissions=0\n"
      <> "Source: https://github.com/KumaKaiNi/discord-kuma"
    end

    command "!say", do: reply message
    command "!coin", do: reply Enum.random(["Heads.", "Tails."])

    command ["!pick", "!random"] do
      choices = message_split |> Enum.join(" ") |> String.split(", ")
      reply Enum.random(choices)
    end

    command "!fortune" do
      request = "http://fortunecookieapi.com/v1/cookie" |> HTTPoison.get!
      [response] = Poison.Parser.parse!((request.body), keys: :atoms)
      fortune = response.fortune.message

      reply fortune
    end

    command "!smug" do
      url = "https://api.imgur.com/3/album/zSNC1"
      auth = %{"Authorization" => "Client-ID #{Application.get_env(:discord_kuma, :imgur_client_id)}"}

      request = HTTPoison.get!(url, auth)
      response = Poison.Parser.parse!((request.body), keys: :atoms)

      try do
        result = response.data.images |> Enum.shuffle |> Enum.find(fn post -> is_image?(post.link) == true end)

        file = download result.link

        reply_file file
        File.rm file
      rescue
        error ->
          reply "fsdafsd"
          Logger.log :warn, error
      end
    end

    command ["!dan", "!danbooru"] do
      [tag1 | tag2] = message_split

      dan = cond do
        length(tag2) >= 1 -> danbooru(tag1, List.first(tag2))
        true -> danbooru(tag1, "")
      end

      case dan do
        {artist, post_id} ->
          reply "Artist: #{artist}\nvia https://danbooru.donmai.us/posts/#{post_id}"
        message -> reply message
      end
    end

    command ["!safe", "!sfw"] do
      tag = message_split |> List.first
      dan = danbooru(tag, "rating:safe")

      case dan do
        {artist, post_id} ->
          reply "Artist: #{artist}\nvia https://danbooru.donmai.us/posts/#{post_id}"
        message -> reply message
      end
    end

    command ["!lewd", "!nsfw"] do
      tag = message_split |> List.first
      dan = danbooru(tag, Enum.random(["rating:questionable","rating:explicit"]))

      case dan do
        {artist, post_id} ->
          reply "Artist: #{artist}\nvia https://danbooru.donmai.us/posts/#{post_id}"
        message -> reply message
      end
    end

    match ["hello", "hi", "hey", "sup"] do
      replies = ["sup loser", "yo", "ay", "go away", "hi", "wassup"]
      if one_to(25) do
        reply Enum.random(replies)
      end
    end

    match ["ty kuma", "thanks kuma", "thank you kuma"] do
      replies = ["np", "don't mention it", "anytime", "sure thing", "ye whateva"]
      reply Enum.random(replies)
    end

    match ["same", "Same", "SAME"] do
      if one_to(25) do
        reply "same"
      end
    end
  end

  handle :guild_ban_add do
    username = msg["user"]["username"]
    log "**#{username}** has been banned."
  end

  handle :guild_ban_remove do
    username = msg["user"]["username"]
    log "**#{username}** has been unbanned."
  end

  handle :guild_member_add do
    username = msg["user"]["username"]
    log "**#{username}** has joined the server."
  end

  handle :guild_member_remove do
    username = msg["user"]["username"]
    log "**#{username}** has left the server."
  end

  handle :typing_start, do: nil
  handle :presence_update, do: nil
  handle event, do: Logger.warn "[Unused] :#{event}"
end
