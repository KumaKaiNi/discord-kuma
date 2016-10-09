defmodule DiscordKuma.Bot do
  {:ok, _bot_client} = DiscordEx.Client.start_link(%{
    token: Application.get_env(:discord_kuma, :discord_token),
    handler: DiscordKuma.Module
  })
end
