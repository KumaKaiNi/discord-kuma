defmodule DiscordKuma.Bot do
  use DiscordKuma.Module
  import DiscordKuma.{Announce, Util}
  alias DiscordEx.RestClient.Resources.{Channel, Guild}

  handle :message_create do
    match "!kuma" do
      channel = Channel.get(state[:rest_client], msg.data["channel_id"])
      guild = Guild.get(state[:rest_client], channel["guild_id"])

      IO.inspect msg
      IO.inspect channel
      IO.inspect guild

      reply "Kuma~!"
    end

    match "!announce here", do: set_log_channel(msg, state)
    match "!announce stop", do: del_log_channel(msg, state)

    match_all do: make_call(msg, state)
  end

  handle :presence_update, do: announce(msg, state)

  def handle_event({_event, _msg}, state), do: {:ok, state}

  defp make_call(msg, state) do
    require Logger

    channel = Channel.get(state[:rest_client], msg.data["channel_id"])
    guild = Guild.get(state[:rest_client], channel["guild_id"])

    data = %{
      auth: Application.get_env(:discord_kuma, :server_auth),
      type: "message",
      content: %{
        source: %{
          protocol: "discord",
          guild: %{name: guild["name"], id: guild["id"]},
          channel: %{
            name: channel["name"],
            id: msg.data["channel_id"],
            private: private(msg, state),
            nsfw: nsfw(msg, state)}},
        user: %{
          id: msg.data["author"]["id"],
          avatar: msg.data["author"]["avatar"],
          name: msg.data["author"]["username"],
          moderator: admin(msg, state)},
        message: %{
          text: msg.data["content"],
          id: msg.data["id"]}}} |> Poison.encode!

    conn = :gen_tcp.connect({127,0,0,1}, 5862, [:binary, packet: 0, active: false])

    case conn do
      {:ok, socket} ->
        case :gen_tcp.send(socket, data) do
          :ok ->
            case :gen_tcp.recv(socket, 0) do
              {:ok, response} ->
                IO.inspect(response |> Poison.Parser.parse!(keys: :atoms))

                case response |> Poison.Parser.parse!(keys: :atoms) do
                  %{reply: true, message: text} ->
                    Logger.debug "replying: #{text}"
                    reply text, chan: msg.data["channel_id"]
                  _ ->
                    Logger.debug "no reply"
                    nil
                end
              {:error, reason} -> Logger.error "Receive error: #{reason}"
            end
          {:error, reason} -> Logger.error "Send error: #{reason}"
        end

        :gen_tcp.close(socket)
      {:error, reason} -> Logger.error "Connection error: #{reason}"
    end
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

  defp private(msg, state) do
    Channel.get(state[:rest_client], msg.data["channel_id"])["is_private"]
  end

  defp nsfw(msg, state) do
    channel = Channel.get(state[:rest_client], msg.data["channel_id"])

    case channel["nsfw"] do
      nil -> true
      nsfw -> nsfw
    end
  end
end
