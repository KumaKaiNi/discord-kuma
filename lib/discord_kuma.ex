defmodule DiscordKuma do
#  use Application
#  use Supervisor
  require Logger

  def start(_type, _args) do
#    import Supervisor.Spec
    Logger.info "Starting supervisor..."

#    children = for i <- 1..System.schedulers_online, do: worker(DiscordKuma.Worker, [], id: i)
#    Supervisor.start_link(children, strategy: :one_for_all)

    {:ok, _bot_client} = DiscordEx.Client.start_link(%{
      token: Application.get_env(:discord_kuma, :discord_token),
      handler: DiscordKuma.Bot
    })
  end
end
