defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.{Announce, Util}

  handle :message_create do
    match "!ping", do: reply "Pong!"
  end

  handle :presence_update, do: announce(msg, state)

  def handle_event({_event, _msg}, state), do: {:ok, state}

  def admin(msg) do
    user_id = msg.author.id
    rekyuu_id = 107977662680571904

    cond do
      user_id == rekyuu_id -> true
      true ->
        guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]

        case guild_id do
          nil -> false
          guild_id ->
            {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)

            db = query_data("guilds", guild_id)

            cond do
              db == nil -> false
              db.admin_roles == [] -> false
              true -> Enum.member?(for role <- member["roles"] do
                {role_id, _} = role |> Integer.parse
                Enum.member?(db.admin_roles, role_id)
              end, true)
            end
        end
    end
  end

  def dm(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    guild_id == nil
  end

  def nsfw(msg) do
    {:ok, channel} = Nostrum.Api.get_channel(msg.channel_id)
    channel["nsfw"]
  end
end
