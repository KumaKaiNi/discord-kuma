defmodule DiscordKuma.Module do
  require Logger
  import DiscordKuma.Util
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

  defmacro enforce(do: body) do
    quote do
      var!(user_id) = var!(msg)["author"]["id"]
      var!(guild_id) = Channel.get(var!(state)[:rest_client], var!(msg)["channel_id"])["guild_id"]
      user_roles = Guild.member(var!(state)[:rest_client], var!(guild_id), var!(user_id))["roles"]

      var!(data) = query_data("guilds", var!(guild_id))

      is_admin = cond do
        var!(data) == nil -> true
        var!(data).admin_roles == [] -> true
        true -> Enum.member?(for role <- user_roles do
          Enum.member?(var!(data).admin_roles, role)
        end, true)
      end

      if is_admin, do: unquote(body)
    end
  end

  defmacro command(list, do: func) when is_list(list) do
    for word <- list do
      quote do
        if var!(command) == unquote(word), do: Task.async(fn -> unquote(func) end)
      end
    end
  end

  defmacro command(word, do: func) do
    quote do
      if var!(command) == unquote(word), do: Task.async(fn -> unquote(func) end)
    end
  end

  defmacro match(list, do: func) when is_list(list) do
    for word <- list do
      quote do
        if var!(text) == unquote(word), do: Task.async(fn -> unquote(func) end)
      end
    end
  end

  defmacro match(word, do: func) do
    quote do
      if var!(text) == unquote(word), do: Task.async(fn -> unquote(func) end)
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

  defmacro log(text) do
    quote do
      var!(data) = query_data("guilds", Integer.to_string(var!(msg)["guild_id"]))

      case var!(data).log_channel do
       nil -> Logger.info "#{unquote(text)}"
       log_channel ->
        Channel.send_message(var!(state)[:rest_client], log_channel, %{content: unquote(text)})
      end
    end
  end
end
