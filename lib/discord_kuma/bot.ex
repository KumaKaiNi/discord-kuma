defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.{Announce, Util}
  alias DiscordEx.RestClient.Resources.{Channel, Guild}

  handle :message_create do
    match "!kuma", do: kuma(msg, state)
    match "!announce here", do: set_log_channel(msg, state)
    match "!announce stop", do: del_log_channel(msg, state)

    match_all do: make_call(msg, state)
  end

  handle :presence_update, do: announce(msg, state)

  def handle_event({_event, _msg}, state), do: {:ok, state}

  defp kuma(msg, state) do
    IO.inspect msg
    reply "Kuma~!"
  end

  defp make_call(msg, state) do
    nil
  end

  defp admin(msg, state) do
    user_id = msg.data["author"]["id"]
    rekyuu_id = 107977662680571904

    cond do
      user_id == rekyuu_id -> true
      true ->
        guild_id = Channel.get(state[:rest_client], msg.data["channel_id"])["guild_id"]

        case guild_id do
          nil -> false
          guild_id ->
            member = Guild.member(state[:rest_client], guild_id, user_id)

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

  defp dm(msg, state) do
    guild_id = Channel.get(state[:rest_client], msg.data["channel_id"])["guild_id"]
    guild_id == nil
  end

  defp nsfw(msg, state) do
    channel = Channel.get(state[:rest_client], msg.data["channel_id"])

    case channel["nsfw"] do
      nil -> true
      nsfw -> nsfw
    end
  end
end
