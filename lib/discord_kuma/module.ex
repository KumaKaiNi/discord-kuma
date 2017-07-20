defmodule DiscordKuma.Module do
  use Nostrum.Consumer
  alias Nostrum.Api

  defmacro __using__(_opts) do
    quote do
      import DiscordKuma.Module
      use Nostrum.Consumer
      alias Nostrum.Api

      def start_link, do: Consumer.start_link(__MODULE__, :state)
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

  defmacro enforce(validator, do: body) do
    quote do
      if unquote(validator)(var!(msg)) do
        unquote(body)
      end
    end
  end

  defmacro match(text, do: body) when is_bitstring(text) do
    make_match(text, body)
  end

  defmacro match([primary_text | alias_texts], do: body) do
    make_match(primary_text)

    for text <- alias_texts do
      make_match(text, body)
    end
  end

  def make_match(text, body) do
    quote do
      if var!(msg).content |> String.split |> List.first == unquote(text) do
        unquote(body)
      end
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
