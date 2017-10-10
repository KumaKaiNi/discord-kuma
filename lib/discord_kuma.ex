defmodule DiscordKuma do
  use Application
  use Supervisor
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.info "Starting supervisor..."

    children = for i <- 1..System.schedulers_online, do: worker(DiscordKuma.Worker, [], id: i)
    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
