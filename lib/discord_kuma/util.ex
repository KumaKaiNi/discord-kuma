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

  def danbooru(tag1, tag2) do
    dan = "danbooru.donmai.us"

    tag1 = tag1 |> String.split |> Enum.join("_") |> URI.encode_www_form
    tag2 = tag2 |> String.split |> Enum.join("_") |> URI.encode_www_form

    request = "http://#{dan}/posts.json?limit=50&page=1&tags=#{tag1}+#{tag2}" |> HTTPoison.get!

    try do
      result = Poison.Parser.parse!((request.body), keys: :atoms) |> Enum.random

      artist = result.tag_string_artist |> String.split("_") |> Enum.join(" ")
      post_id = Integer.to_string(result.id)
      image = "http://#{dan}#{result.file_url}"

      {artist, post_id, image}
    rescue
      Enum.EmptyError -> "Nothing found!"
      UndefinedFunctionError -> "Nothing found!"
      error ->
        Logger.log :warn, error
        "fsdafsd"
    end
  end

  def download(url) do
    filename = url |> String.split("/") |> List.last
    filepath = "_tmp/#{filename}"

    Logger.log :info, "Downloading #{filename}..."
    image = url |> HTTPoison.get!
    File.write filepath, image.body

    filepath
  end

  def is_image?(url) do
    Logger.log :info, "Checking if #{url} is an image..."
    image_types = [".jpg", ".jpeg", ".gif", ".png", ".mp4"]
    Enum.member?(image_types, Path.extname(url))
  end

  def store_data(table, key, value) do
    file = '/var/www/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])

    :dets.insert(table, {key, value})
    :dets.close(table)
    :ok
  end

  def query_data(table, key) do
    file = '/var/www/_db/#{table}.dets'
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
    file = '/var/www/_db/#{table}.dets'
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
    file = '/var/www/_db/#{table}.dets'
    {:ok, _} = :dets.open_file(table, [file: file, type: :set])
    response = :dets.delete(table, key)

    :dets.close(table)
    response
  end
end
