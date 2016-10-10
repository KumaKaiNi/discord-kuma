defmodule DiscordKuma.Util do
  require Logger

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

      {artist, post_id}
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
end
