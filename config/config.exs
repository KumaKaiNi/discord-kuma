use Mix.Config

config :porcelain, driver: Porcelain.Driver.Basic

import_config "secret.exs"

config :logger,
  level: :debug
