defmodule DiscordKuma.Handler do
  require Logger
  use DiscordKuma.Module

  handle :message_create do
    command "!repeat", do: reply message
  end

  handle event, do: Logger.info "[Unused] :#{event}"
end
