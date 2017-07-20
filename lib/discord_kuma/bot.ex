defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.Util
  require Logger

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

  handle :MESSAGE_CREATE do
    match "!hi", :hello
    match ["hello", "hi", "hey", "sup"], :hello

    enforce :admin do
      match "!kuma", do: reply "Kuma~!"
    end
  end

  def hello(msg) do
    replies = ["sup loser", "yo", "ay", "hi", "wassup"]

    if one_to(25) do
      reply Enum.random(replies)
    end
  end

  handle _event, do: nil
end
