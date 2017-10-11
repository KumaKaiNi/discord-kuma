defmodule DiscordKuma.Module do
  alias DiscordEx.RestClient.Resources.Channel

  defmacro __using__(_opts) do
    quote do
      import DiscordKuma.Module
    end
  end

  defmacro handle(event, do: body) do
    quote do
      def handle_event({unquote(event), var!(msg)}, var!(state)) do
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
      unless var!(msg).data["author"]["id"] == DiscordEx.RestClient.Resources.User.get(var!(state)[:rest_client]) do
        cond do
          var!(msg).data["content"] == unquote(text) -> unquote(body)(var!(msg))
          var!(msg).data["content"] |> String.split |> List.first == unquote(text) ->
            unquote(body)(var!(msg), var!(state))
          true -> nil
        end
      end
    end
  end

  defp make_match(text, body) do
    quote do
      cond do
        var!(msg).data["content"] == unquote(text) -> unquote(body)
        var!(msg).data["content"] |> String.split |> List.first == unquote(text) ->
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

  defmacro reply(text, chan: channel_id) when is_bitstring(text) do
    quote do
      Channel.send_message(var!(state)[:rest_client], unquote(channel_id), %{content: unquote(text)})
    end
  end

  defmacro reply(text) when is_bitstring(text) do
    quote do
      Channel.send_message(var!(state)[:rest_client], var!(msg).data["channel_id"], %{content: unquote(text)})
    end
  end

  defmacro reply_embed(struct) do
    quote do
      Channel.send_message(var!(state)[:rest_client], var!(msg).data["channel_id"], unquote(struct))
    end
  end

  defmacro reply_embed(struct, chan: channel_id) do
    quote do
      Channel.send_message(var!(state)[:rest_client], unquote(channel_id), unquote(struct))
    end
  end
end
