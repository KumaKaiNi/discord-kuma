defmodule DiscordKuma do
  use Application
  use Supervisor
  require Logger

  unless File.exists?("/var/www/_db"), do: File.mkdir("/var/www/_db")

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.info "Starting supervisor..."

    children = for i <- 1..System.schedulers_online, do: worker(DiscordKuma.Bot, [], id: i)
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
