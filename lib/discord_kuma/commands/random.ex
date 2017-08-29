defmodule DiscordKuma.Commands.Random do
  import DiscordKuma.{Module, Util}

  def pick(msg) do
    [_ | choices] = msg.content |> String.split

    case choices do
      [] -> nil
      choices ->
        choices_list = choices |> Enum.join(" ") |> String.split(", ")
        case length(choices_list) do
          1 -> reply "What? Okay, #{choices_list |> List.first}, I guess. Didn't really give me a choice there."
          _ -> reply "#{choices_list |> Enum.random}"
        end
    end
  end

  def roll(msg) do
    [_ | roll] = msg.content |> String.split

    case roll do
      [] -> reply "#{Enum.random(1..6)}"
      [roll] ->
        [count | amount] = roll |> String.split("d")

        case amount do
          [] ->
            if String.to_integer(count) > 1 do
              reply "#{Enum.random(1..String.to_integer(count))}"
            end
          [amount] ->
            if String.to_integer(count) > 1 do
              rolls = for _ <- 1..String.to_integer(count) do
                "#{Enum.random(1..String.to_integer(amount))}"
              end

              reply rolls |> Enum.join(", ")
            end
        end
    end
  end

  def prediction(msg) do
    predictions = [
      "It is certain.",
      "It is decidedly so.",
      "Without a doubt.",
      "Yes, definitely.",
      "You may rely on it.",
      "As I see it, yes.",
      "Most likely.",
      "Outlook good.",
      "Yes.",
      "Signs point to yes.",
      "Reply hazy, try again.",
      "Ask again later.",
      "Better not tell you now.",
      "Cannot predict now.",
      "Concentrate and ask again.",
      "Don't count on it.",
      "My reply is no.",
      "My sources say no.",
      "Outlook not so good.",
      "Very doubtful."
    ]

    reply Enum.random(predictions)
  end

  def souls_message(msg) do
    url = "http://souls.riichi.me/api"
    request = HTTPoison.get!(url)
    response = Poison.Parser.parse!((request.body), keys: :atoms)

    reply "#{response.message}"
  end
end
