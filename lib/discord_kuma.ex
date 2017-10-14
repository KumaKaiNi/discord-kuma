defmodule DiscordKuma do
  use Application
  use Supervisor
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.info "starting supervisor"

    children = [worker(DiscordKuma.Bot, [])]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
