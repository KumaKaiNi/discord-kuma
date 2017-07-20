defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.Util
  require Logger

  # Enforcers
  def admin(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    user_id = msg.author.id
    {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)

    db = query_data("guilds", guild_id)

    cond do
      db == nil -> true
      db.admin_roles == [] -> true
      true -> Enum.member?(for role <- member["roles"] do
        Enum.member?(db.admin_roles, role)
      end, true)
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
      match_all :custom_command
      match ["ty kuma", "thanks kuma", "thank you kuma"], :ty_kuma
    end

    match ["hello", "hi", "hey", "sup"], :hello

    enforce :admin do
      match "!kuma", :kuma
      match "!setup", :setup
      match "!addrole", :add_role
      match "!delrole", :del_role
      match "!add", :add_custom_command
      match "!del", :del_custom_command
      # match "!addquote", :add_quote
      # match "!delquote", :del_quote
    end
  end

  handle _event, do: nil

  # Rate limited user commands
  def help(msg), do: reply "ok"

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
    reply "Kuma~!"
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
            reply "Added #{role_ids |> Enum.join(', ')} as administrative roles!"
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
            reply "Removed #{role_ids |> Enum.join(', ')} from administrative roles."
        end
    end
  end

  def add_custom_command(msg) do
    [_ | [command | action]] = msg.content
    action = action |> Enum.join(" ")

    exists = query_data(:commands, "!#{command}")
    store_data(:commands, "!#{command}", action)

    case exists do
      nil -> reply "Alright! Type !#{command} to use."
      _   -> reply "Done, command !#{command} updated."
    end
  end

  def del_custom_command(msg) do
    [_ | command] = msg.content

    case action do
      nil -> reply "Command does not exist."
      _   ->
        delete_data(:commands, "!#{command}")
        reply "Command !#{command} removed."
    end
  end
end
