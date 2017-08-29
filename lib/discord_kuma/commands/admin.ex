defmodule DiscordKuma.Commands.Admin do
  import DiscordKuma.{Module, Util}

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
end
