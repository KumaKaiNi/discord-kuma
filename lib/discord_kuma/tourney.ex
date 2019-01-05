defmodule Tourney do
  def bracket(participants) do
    participants_count = participants |> length
    rounds = (participants_count / 2) |> Float.ceil |> Kernel.trunc

    cond do
      participants_count <= 2 -> participants
      true -> for chunk <- Enum.chunk_every(participants, rounds) do
        bracket(chunk)
      end
    end
  end

  def compete(rounds) do
    for round <- rounds do
      cond do
        is_bitstring(round) -> round
        true -> 
          cond do
            is_list(List.first(round)) -> compete(round)
            true ->
              [{_key, rounds_script}] = :ets.lookup(:tourney, "temp")

              winner = Enum.random(round)
              rounds_script = rounds_script ++ ["#{List.first(round)} vs. #{List.last(round)}: #{winner} won!\n"]
              :ets.insert(:tourney, {"temp", rounds_script})

              winner
          end
      end
    end
  end

  def tourney(rounds, round_number \\ 0) do
    [{_key, rounds_script}] = :ets.lookup(:tourney, "temp")

    round_number = round_number + 1
    rounds_script = rounds_script ++ ["#{if round_number != 1, do: "\n"}-- Round #{round_number} --\n"]
    :ets.insert(:tourney, {"temp", rounds_script})

    round_x = compete(rounds)
    
    cond do
      is_bitstring(List.first(round_x)) -> 
        [{_key, rounds_script}] = :ets.lookup(:tourney, "temp")
        winner = Enum.random(round_x)

        rounds_script = rounds_script ++ ["\n-- Final Round --\n#{List.first(round_x)} vs. #{List.last(round_x)}: #{winner} won!"]
        :ets.insert(:tourney, {"temp", rounds_script})
      true -> tourney(round_x, round_number)
    end
  end
end