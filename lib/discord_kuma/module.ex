defmodule DiscordKuma.Module do
  def handle_event({:message_create, payload}, state) do
    IO.puts "[:message_create] #{payload}"
    {:ok, state}
  end

  def handle_event({event, _payload}, state) do
    IO.puts "[#{event}]"
    {:ok, state}
  end
end
