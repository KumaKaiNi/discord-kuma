defmodule DiscordKuma.MoonPhase do
  use GenServer
  alias Din.Resources.Guild
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end
  
  def init(:ok) do
    send self(), :update
    {:ok, [phase: nil]}
  end
  
  def handle_info(:update, state) do
    phase = moon_phase(Date.utc_today)
    
    unless phase == state[:phase] do
      set_server_icon(phase)
    end

    :erlang.send_after(1000 * 60 * 60, self(), :update)
    {:noreply, [phase: phase]}
  end
  
  def moon_phase(date) do
    {y, m, d} = cond do
      date.month <= 2 -> {date.year - 1, date.month + 12, date.day}
      true -> {date.year, date.month, date.day}
    end
    
    a = Kernel.trunc(y / 100)
    b = Kernel.trunc(a / 4)
    c = 2 - a + b
    e = Kernel.trunc(365.25 * (y + 4716))
    f = Kernel.trunc(30.6001 * (m + 1))
    
    cycle_length = 29.53
    julian_date = c + d + e + f - 1524.5
    days_since_new_moon = Kernel.trunc(julian_date - 2451549.5)
    new_moons = days_since_new_moon / cycle_length
    Kernel.trunc((new_moons - Kernel.trunc(new_moons)) * cycle_length)
  end
  
  def set_server_icon(phase) do
    icon = File.open!("phases/phase#{phase}.png")
    Guild.modify(214268737887404042, icon: icon)
  end
end