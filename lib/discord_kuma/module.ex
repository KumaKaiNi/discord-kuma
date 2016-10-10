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
        text = var!(msg)["content"]

        var!(command) = text |> String.split |> List.first
        var!(message) = text |> String.split |> List.delete(var!(command)) |> Enum.join(" ")

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

  defmacro reply(text) do
    quote do
      Channel.send_message(var!(state)[:rest_client], var!(msg)["channel_id"], %{content: unquote(text)})
    end
  end
end
