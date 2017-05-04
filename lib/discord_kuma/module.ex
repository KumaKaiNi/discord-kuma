defmodule DiscordKuma.Module do
  use Nostrum.Consumer
  alias Nostrum.Api

  defmacro __using__(_opts) do
    quote do
      import DiscordKuma.Module
      use Nostrum.Consumer
      alias Nostrum.Api

      def start_link, do: Consumer.start_link(__MODULE__)
    end
  end

  defmacro handle(event, do: body) do
    quote do
      def handle_event({unquote(event), {var!(msg)}, var!(_ws_state)}, var!(state)) do
        unquote(body)

        {:ok, var!(state)}
      end
    end
  end

  defmacro enforce(do: body) do
    quote do
      var!(guild_id) = Nostrum.Api.get_channel!(var!(msg).channel_id)["guild_id"]
      var!(user_id) = var!(msg).author.id
      {:ok, member} = Nostrum.Api.get_member(var!(guild_id), var!(user_id))

      var!(db) = query_data("guilds", var!(guild_id))

      admin = cond do
        var!(db) == nil -> true
        var!(db).admin_roles == [] -> true
        true -> Enum.member?(for role <- member["roles"] do
          Enum.member?(var!(db).admin_roles, role)
        end, true)
      end

      if admin, do: unquote(body)
    end
  end

  defmacro reply(text) do
    quote do
      Api.create_message(var!(msg).channel_id, unquote(text))
    end
  end

  defmacro log(text) do
    quote do
      var!(db) = query_data("guilds", Nostrum.Api.get_channel!(var!(msg).channel_id)["guild_id"])

      case var!(db).log_channel do
       nil -> nil
       log_channel ->
         Api.create_message(log_channel, unquote(text))
      end
    end
  end
end
