defmodule DiscordKuma.Commands.Markov do
  import DiscordKuma.Module

  def get_markov(msg) do
    reply gen_markov("/home/bowan/bots/_db/twitch.log")
  end

  defp gen_markov(input_file, word_count \\ 0, start_word \\ nil) do
    alias DiscordKuma.Markov.Dictionary
    alias DiscordKuma.Markov.Generator

    :random.seed(:os.timestamp)

    filepath = input_file
    file = File.read!(filepath)

    lines = file |> String.split("\n")
    lines = (for line <- lines do
      case Regex.named_captures(~r/\[.*\] \w+\: (?<capture>.*)/, line) do
        nil -> nil
        %{"capture" => capture} -> capture
      end
    end |> Enum.uniq) -- [nil]

    words = lines |> Enum.join(" ")

    markov_length = case word_count do
      0 ->
        avg = round(length(words |> String.split) / length(lines))
        avg + :random.uniform(avg * 3)
      count -> count
    end

    markov_start = case start_word do
      nil -> words |> String.split |> Enum.random
      literally_anything_else -> literally_anything_else
    end

    Dictionary.new
    |> Dictionary.parse(file)
    |> Generator.generate_words(markov_start, markov_length)
  end
end
