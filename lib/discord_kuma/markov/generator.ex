defmodule DiscordKuma.Markov.Generator do
  def generate_words(dictionary, start_word, num_words) do
    generate_words(dictionary, start_word, num_words - 1, [start_word])
  end

  def generate_words(_dictionary, _start_word, 0, generated_words) do
    Enum.reverse(generated_words) |> Enum.join(" ")
  end

  def generate_words(dictionary, start_word, num_words, generated_words) do
    new_word = get_word(dictionary, start_word)
    generate_words(dictionary, new_word, num_words - 1, [new_word | generated_words])
  end

  defp get_word(dictionary, start_word) do
    case DiscordKuma.Markov.Dictionary.next(dictionary, start_word) do
      nil -> nil
      list -> Enum.shuffle(list) |> hd
    end
  end
end
