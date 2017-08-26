defmodule DiscordKuma.Mixfile do
  use Mix.Project

  def project do
    [app: :discord_kuma,
     version: "0.2.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:ex_rated, :nostrum, :logger, :httpoison],
     mod: {DiscordKuma, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_rated, "~> 1.2"},
     {:nostrum, git: "https://github.com/Kraigie/nostrum.git"}]
  end
end
