defmodule DiscordKuma.Module do
  require Logger

  def handle_event({event, payload}, state) do
    Logger.info "[#{event}]"
    {:ok, state}
  end
end
