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

  def rate_limit(msg) do
    command = msg.content |> String.split |> List.first
    {rate, _} = ExRated.check_rate(command, 10_000, 1)

    case rate do
      :ok    -> true
      :error -> false
    end
  end

  handle :MESSAGE_CREATE do
    enforce :rate_limit do
      match "!help", do: reply "https://github.com/KumaKaiNi/discord-kuma"
    end

    match ["hello", "hi", "hey", "sup"], :hello

    enforce :admin do
      match "!kuma", do: reply "Kuma~!"
    end
  end

  def help(msg), do: reply "ok"

  def hello(msg) do
    replies = ["sup loser", "yo", "ay", "hi", "wassup"]

    if one_to(25) do
      reply Enum.random(replies)
    end
  end

  handle _event, do: nil
end
