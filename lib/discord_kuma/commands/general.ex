defmodule DiscordKuma.Commands.General do
  import DiscordKuma.{Module, Util}

  def kuma(msg) do
    IO.inspect msg
    reply "Kuma~!"
  end

  def help(msg), do: reply "https://github.com/KumaKaiNi/discord-kuma"

  def ty_kuma(msg) do
    replies = ["np", "don't mention it", "anytime", "sure thing", "ye whateva"]
    reply Enum.random(replies)
  end

  def hello(msg) do
    replies = ["sup loser", "yo", "ay", "hi", "wassup"]

    if one_to(25) do
      reply Enum.random(replies)
    end
  end

  def same(msg) do
    if one_to(25), do: reply "same"
  end
end
