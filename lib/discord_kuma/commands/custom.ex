defmodule DiscordKuma.Commands.Custom do
  import DiscordKuma.{Module, Util}

  def custom_command(msg) do
    action = query_data(:commands, msg.content |> String.split |> List.first)

    case action do
      nil -> nil
      action -> reply action
    end
  end

  def add_custom_command(msg) do
    [_ | [command | action]] = msg.content |> String.split
    action = action |> Enum.join(" ")

    exists = query_data(:commands, "!#{command}")
    store_data(:commands, "!#{command}", action)

    case exists do
      nil -> reply "Alright! Type !#{command} to use."
      _   -> reply "Done, command !#{command} updated."
    end
  end

  def del_custom_command(msg) do
    [_ | [command | _]] = msg.content |> String.split
    action = query_data(:commands, "!#{command}")

    case action do
      nil -> reply "Command does not exist."
      _   ->
        delete_data(:commands, "!#{command}")
        reply "Command !#{command} removed."
    end
  end
end
