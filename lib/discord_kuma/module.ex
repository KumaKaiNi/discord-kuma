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

  defmacro match(texts, do: body) when is_list(texts) do
    for text <- texts do
      make_match(text, body)
    end
  end

  defmacro match(text, body) when is_bitstring(text) do
    make_match(text, body)
  end

  defmacro match(texts, body) when is_list(texts) do
    for text <- texts do
      make_match(text, body)
    end
  end

  defmacro match_all(do: body), do: make_match(body)
  defmacro match_all(body), do: make_match(body)

  defp make_match(text, body) when is_atom(body) do
    quote do
      cond do
        var!(msg).content == unquote(text) -> unquote(body)(var!(msg))
        var!(msg).content |> String.split |> List.first == unquote(text) ->
          unquote(body)(var!(msg))
        true -> nil
      end
    end
  end

  defp make_match(text, body) do
    quote do
      cond do
        var!(msg).content == unquote(text) -> unquote(body)
        var!(msg).content |> String.split |> List.first == unquote(text) ->
          unquote(body)
        true -> nil
      end
    end
  end

  defp make_match(body) when is_atom(body) do
    quote do
      unquote(body)(var!(msg))
    end
  end

  defp make_match(body) do
    quote do
      unquote(body)
    end
  end

  defmacro reply(text, chan: channel_id) do
    quote do
      Api.create_message(unquote(channel_id), unquote(text))
    end
  end

  defmacro reply(text) do
    quote do
      Api.create_message(var!(msg).channel_id, unquote(text))
    end
  end
end
