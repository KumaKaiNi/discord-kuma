defmodule DiscordKuma do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [worker(DiscordKuma.Bot, [], restart: :permanent)]
    opts = [strategy: :one_for_one, name: DiscordKuma.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
