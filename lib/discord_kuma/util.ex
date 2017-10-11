defmodule DiscordKuma.Util do
  require Logger

  def pull_id(message) do
    id = Regex.run(~r/([0-9])\w+/, message)

    case id do
      nil -> nil
      id -> List.first(id)
    end
  end

  def one_to(n), do: Enum.random(1..n) <= 1
  def percent(n), do: Enum.random(1..100) <= n

  def pay_user(user, n) do
    bonus = query_data(:casino, :bonus)
    bank = query_data(:bank, user)
    earnings = n * bonus

    coins = case bank do
      nil -> earnings
      bank -> bank + earnings
    end

    store_data(:bank, user, coins)
  end

  def get_user_stats(username) do
    stats = query_data(:stats, username)
    stats = case stats do
      nil -> %{level: 1, vit: 10, end: 10, str: 10, dex: 10, int: 10, luck: 10}
      stats -> stats
    end

    next_lvl = stats.level + 1
    next_lvl_cost =
      :math.pow((3.741657388 * next_lvl), 2) + (100 * next_lvl) |> round

    {stats, next_lvl_cost}
  end

  def store_data(table, key, value) do
    file = '/home/bowan/bots/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])

    :dets.insert(table, {key, value})
    :dets.close(table)
    :ok
  end

  def query_data(table, key) do
    file = '/home/bowan/bots/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.lookup(table, key)

    response =
      case result do
        [{_, value}] -> value
        [] -> nil
      end

    :dets.close(table)
    response
  end

  def query_all_data(table) do
    file = '/home/bowan/bots/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    result = :dets.match_object(table, {:"$1", :"$2"})

    response =
      case result do
        [] -> nil
        values -> values
      end

    :dets.close(table)
    response
  end

  def delete_data(table, key) do
    file = '/home/bowan/bots/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    response = :dets.delete(table, key)

    :dets.close(table)
    response
  end
end
