defmodule DiscordKuma.Commands.Quote do
  import DiscordKuma.{Module, Util}

  def get_quote(msg) do
    {quote_id, quote_text} = case length(msg.content |> String.split) do
      1 ->
        quotes = query_all_data(:quotes)
        Enum.random(quotes)
      _ ->
        [_ | [quote_id | _]] = msg.content |> String.split

        case quote_id |> Integer.parse do
          {quote_id, _} ->
            case query_data(:quotes, quote_id) do
              nil -> {"65535", "Quote does not exist. - KumaKaiNi, 2017"}
              quote_text -> {quote_id, quote_text}
            end
          :error ->
            quotes = query_all_data(:quotes)
            Enum.random(quotes)
        end
    end

    reply "[#{quote_id}] #{quote_text}"
  end

  def add_quote(msg) do
    [_ | quote_text] = msg.content |> String.split
    quote_text = quote_text |> Enum.join(" ")

    quotes = case query_all_data(:quotes) do
      nil -> nil
      quotes -> quotes |> Enum.sort
    end

    quote_id = case quotes do
      nil -> 1
      _ ->
        {quote_id, _} = List.last(quotes)
        quote_id + 1
    end

    store_data(:quotes, quote_id, quote_text)
    reply "Quote added! #{quote_id} quotes total."
  end

  def del_quote(msg) do
    [_ | [quote_id | _]] = msg.content |> String.split

    case quote_id |> Integer.parse do
      {quote_id, _} ->
        case query_data(:quotes, quote_id) do
          nil -> reply "Quote #{quote_id} does not exist."
          _ ->
            delete_data(:quotes, quote_id)
            reply "Quote removed."
        end
      :error -> reply "You didn't specify an ID number."
    end
  end
end
