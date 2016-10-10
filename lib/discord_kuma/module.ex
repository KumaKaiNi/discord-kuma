defmodule DiscordKuma.Module do
  alias DiscordEx.RestClient.Resources.{Channel, Guild, Image, Invite, User}

  defmacro __using__(_opts) do
    quote do
      import DiscordKuma.Module
      alias DiscordEx.RestClient.Resources.{Channel, Guild, Image, Invite, User}
    end
  end

  defmacro handle(:message_create, do: body) do
    quote do
      def handle_event({:message_create, var!(payload)}, var!(state)) do
        var!(msg) = var!(payload).data
        var!(text) = var!(msg)["content"]

        [var!(command) | var!(message_split)] = var!(text) |> String.split
        var!(message) = Enum.join(var!(message_split), " ")

        unquote(body)

        {:ok, var!(state)}
      end
    end
  end

  defmacro handle(event, do: body) do
    quote do
      def handle_event({unquote(event), var!(payload)}, var!(state)) do
        var!(msg) = var!(payload).data

        unquote(body)

        {:ok, var!(state)}
      end
    end
  end

  defmacro command(list, do: func) when is_list(list) do
    for word <- list do
      quote do
        if var!(command) == unquote(word), do: unquote(func)
      end
    end
  end

  defmacro command(word, do: func) do
    quote do
      if var!(command) == unquote(word), do: unquote(func)
    end
  end

  defmacro match(list, do: func) when is_list(list) do
    for word <- list do
      quote do
        if var!(text) == unquote(word), do: unquote(func)
      end
    end
  end

  defmacro match(word, do: func) do
    quote do
      if var!(text) == unquote(word), do: unquote(func)
    end
  end

  defmacro reply(text) do
    quote do
      Channel.send_message(var!(state)[:rest_client], var!(msg)["channel_id"], %{content: unquote(text)})
    end
  end

  defmacro reply_file(filepath, text \\ "") do
    quote do
      Channel.send_file(var!(state)[:rest_client], var!(msg)["channel_id"], %{file: unquote(filepath), content: unquote(text)})
    end
  end
end
