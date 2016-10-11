defmodule DiscordKuma do
  use Application
  use Supervisor
  require Logger

  unless File.exists?("_tmp"), do: File.mkdir("_tmp")
  unless File.exists?("_db"), do: File.mkdir("_db")

  def start(_type, _args) do
    Logger.info "Starting supervisor..."

    children = [supervisor(DiscordKuma.Bot, [[name: DiscordKuma.Bot]])]
    {:ok, _pid} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end
