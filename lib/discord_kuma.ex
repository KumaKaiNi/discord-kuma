defmodule DiscordKuma do
  require Logger

  def start(_type, _args) do
    Logger.debug "Starting HTTPoison..."
    HTTPoison.start

    Logger.debug "Starting bot..."
    DiscordEx.Client.start_link(%{
      token: Application.get_env(:discord_kuma, :discord_token),
      handler: DiscordKuma.Module
    })
  end
end
