defmodule DiscordKuma.Commands.Casino do
  import DiscordKuma.{Module, Util}

  def link_twitch_account(msg) do
    case msg.content |> String.split |> length do
      1 -> reply "Usage: `!link <twitch username>`"
      _ ->
        [_ | [twitch_account | _]] = msg.content |> String.split
        twitch_account = twitch_account |> String.downcase

        user_id = msg.author.id
        user = query_data(:links, user_id)
        all_users = query_data(:links, :users)

        case user do
          nil ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                reply "That username has already been taken."
              true ->
                all_users = all_users ++ [twitch_account]
                store_data(:links, user_id, twitch_account)
                store_data(:links, :users, all_users)
                reply "Twitch account linked!"
            end
          user ->
            cond do
              Enum.member?(all_users, twitch_account) ->
                reply "That username has already been taken."
              true ->
                all_users = (all_users -- [user]) ++ [twitch_account]
                store_data(:links, user_id, twitch_account)
                store_data(:links, :users, all_users)
                reply "Twitch account updated!"
            end
        end
    end
  end

  def coins(msg) do
    username = query_data(:links, msg.author.id)

    case username do
      nil -> reply "You need to link your Twitch account. Be sure to DM me `!link <twitch username>` first."
      username ->
        bank = query_data(:bank, username)

        amount = case bank do
          nil -> "no"
          bank -> bank
        end

        reply "You have #{amount} coins."
    end
  end

  def gift_all_coins(msg) do
    [_ | [gift | _]] = msg.content |> String.split
    {gift, _} = gift |> Integer.parse

    cond do
      gift <= 0 -> reply "Please gift 1 coin or more."
      true ->
        users = query_all_data(:bank)

        for {username, coins} <- users do
          store_data(:bank, username, coins + gift)
        end

        reply "Gifted everyone #{gift} coins!"
    end
  end

  def slot_machine(msg) do
    username = query_data(:links, msg.author.id)

    case username do
      nil -> reply "You need to link your Twitch account. Be sure to DM me `!link <twitch username>` first."
      username ->
        case msg.content |> String.split |> length do
          1 -> reply "Usage: `!slots <1-25>`"
          _ ->
            [_ | [bet | _]] = msg.content |> String.split
            bet = bet |> Integer.parse

            case bet do
              {bet, _} ->
                cond do
                  bet > 25  -> reply "You must bet between 1 and 25 coins."
                  bet < 1   -> reply "You must bet between 1 and 25 coins."
                  true ->
                    bank = query_data(:bank, username)

                    cond do
                      bank < bet -> reply "You do not have enough coins."
                      true ->
                        reel = ["⚓", "⭐", "🍋", "🍊", "🍒", "🌸"]

                        {col1, col2, col3} = {Enum.random(reel), Enum.random(reel), Enum.random(reel)}

                        bonus = case {col1, col2, col3} do
                          {"🌸", "🌸", "⭐"} -> 2
                          {"🌸", "⭐", "🌸"} -> 2
                          {"⭐", "🌸", "🌸"} -> 2
                          {"🌸", "🌸", _}    -> 1
                          {"🌸", _, "🌸"}    -> 1
                          {_, "🌸", "🌸"}    -> 1
                          {"🍒", "🍒", "🍒"} -> 4
                          {"🍊", "🍊", "🍊"} -> 6
                          {"🍋", "🍋", "🍋"} -> 8
                          {"⚓", "⚓", "⚓"} -> 10
                          _ -> 0
                        end

                        result = case bonus do
                          0 ->
                            {stats, _} = get_user_stats(username)
                            odds =
                              1250 * :math.pow(1.02256518256, -1 * stats.luck)
                              |> round

                            if one_to(odds) do
                              "You didn't win, but the machine gave you your money back."
                            else
                              store_data(:bank, username, bank - bet)

                              kuma = query_data(:bank, "kumakaini")
                              store_data(:bank, "kumakaini", kuma + bet)

                              "Sorry, you didn't win anything."
                            end
                          bonus ->
                            payout = bet * bonus
                            store_data(:bank, username, bank - bet + payout)
                            "Congrats, you won #{payout} coins!"
                        end

                        reply "#{col1} #{col2} #{col3}\n#{result}"
                    end
                end
              :error -> reply "Usage: !slots <bet>, where <bet> is a number between 1 and 25."
            end
        end
    end
  end

  def buy_lottery_ticket(msg) do
    username = query_data(:links, msg.author.id)

    case username do
      nil -> reply "You need to link your Twitch account. Be sure to DM me `!link <twitch username>` first."
      username ->
        ticket = query_data(:lottery, username)

        case ticket do
          nil ->
            bank = query_data(:bank, username)

            cond do
              bank < 50 -> reply "You do not have 50 coins to purchase a lottery ticket."
              true ->
                [_ | choices] = msg.content |> String.split
                {_, safeguard} = choices |> Enum.join |> Integer.parse
                numbers = choices |> Enum.join |> String.length

                case safeguard do
                  "" ->
                    cond do
                      length(choices) == 3 and numbers == 3 ->
                        jackpot = query_data(:bank, "kumakaini")

                        store_data(:bank, username, bank - 50)
                        store_data(:bank, "kumakaini", jackpot + 50)

                        store_data(:lottery, username, choices |> Enum.join(" "))

                        reply "Your lottery ticket of #{choices |> Enum.join(" ")} has been purchased for 50 coins."
                      true -> reply "Please send me three numbers, ranging between 0-9."
                    end
                  _ -> reply "Please only send me three numbers, ranging between 0-9."
                end
            end
          ticket -> reply "You've already purchased a ticket of #{ticket}. Please wait for the next drawing to buy again."
        end
    end
  end

  def lottery_drawing(msg) do
    winning_ticket = "#{Enum.random(0..9)} #{Enum.random(0..9)} #{Enum.random(0..9)}"

    ticket_string = ["The winning numbers today are #{winning_ticket}!"]

    winners = for {username, ticket} <- query_all_data(:lottery) do
      delete_data(:lottery, username)

      cond do
        ticket == winning_ticket -> username
        true -> nil
      end
    end

    jackpot = query_data(:bank, "kumakaini")
    winners = Enum.uniq(winners) -- [nil]

    response = case length(winners) do
      0 -> ["There are no winners today."]
      _ ->
        winnings = jackpot / length(winners) |> round

        winner_strings = for winner <- winners do
          pay_user(winner, winnings)
          "#{winner} has won #{winnings} coins!"
        end

        store_data(:bank, "kumakaini", 0)
        winner_strings ++ ["Congratulations!!"]
    end

    reply (ticket_string ++ response) |> Enum.join("\n")
  end

  # Leveling
  def level_up(msg) do
    username = query_data(:links, msg.author.id)

    case username do
      nil -> reply "You need to link your Twitch account. Be sure to DM me `!link <twitch username>` first."
      username ->
        case msg.content |> String.split |> length do
          1 ->
            bank = query_data(:bank, username)
            {stats, next_lvl_cost} = get_user_stats(username)

            reply "You are Level #{stats.level}. It will cost #{next_lvl_cost} coins to level up. You currently have #{bank} coins. Type `!level <stat>` to do so."
          _ ->
            [_ | [stat | _]] = msg.content |> String.split
            {stats, next_lvl_cost} = get_user_stats(username)
            bank = query_data(:bank, username)

            cond do
              next_lvl_cost > bank -> reply "You do not have enough coins. #{next_lvl_cost} coins are required. You currently have #{bank} coins."
              true ->
                stat = case stat do
                  "vit" -> "vitality"
                  "end" -> "endurance"
                  "str" -> "strength"
                  "dex" -> "dexterity"
                  "int" -> "intelligence"
                  stat -> stat
                end

                stats = case stat do
                  "vitality"      -> %{stats | vit: stats.vit + 1}
                  "endurance"     -> %{stats | end: stats.end + 1}
                  "strength"      -> %{stats | str: stats.str + 1}
                  "dexterity"     -> %{stats | dex: stats.dex + 1}
                  "intelligence"  -> %{stats | int: stats.int + 1}
                  "luck"          -> %{stats | luck: stats.luck + 1}
                  _ -> :error
                end

                case stats do
                  :error -> reply "That is not a valid stat. Valid stats are `vit`, `end`, `str`, `dex`, `int`, `luck`."
                  stats ->
                    stats = %{stats | level: stats.level + 1}

                    store_data(:bank, username, bank - next_lvl_cost)
                    store_data(:stats, username, stats)
                    reply "You are now Level #{stats.level}! You have #{bank - next_lvl_cost} coins left."
                end
            end
        end
    end
  end

  def get_stats(msg) do
    username = query_data(:links, msg.author.id)

    case username do
      nil -> reply "You need to link your Twitch account. Be sure to DM me `!link <twitch username>` first."
      username ->
        bank = query_data(:bank, username)
        bank = case bank do
          nil -> 0
          bank -> bank
        end

        {stats, next_lvl_cost} = get_user_stats(username)

        avatar = "https://cdn.discordapp.com/avatars/#{msg.author.id}/#{msg.author.avatar}"

        reply [content: "", embed: %Nostrum.Struct.Embed{
          color: 0x00b6b6,
          title: "#{msg.author.username}'s Stats",
          description: "Level #{stats.level}",
          fields: [
            %{name: "Coins", value: "#{bank}", inline: true},
            %{name: "Level Up Cost", value: "#{next_lvl_cost}", inline: true},
            %{name: "Vitality", value: "#{stats.vit}", inline: true},
            %{name: "Endurance", value: "#{stats.end}", inline: true},
            %{name: "Strength", value: "#{stats.str}", inline: true},
            %{name: "Dexterity", value: "#{stats.dex}", inline: true},
            %{name: "Intelligence", value: "#{stats.int}", inline: true},
            %{name: "Luck", value: "#{stats.luck}", inline: true}
          ],
          thumbnail: %Nostrum.Struct.Embed.Image{url: avatar}
        }]
    end
  end

  def get_jackpot(msg) do
    jackpot = query_data(:bank, "kumakaini")
    reply "There are #{jackpot} coins in the jackpot."
  end

  def get_top_five(msg) do
    users = query_all_data(:stats)

    top5 = for {username, stats} <- users do
      unless Enum.member?(["rekyuus", "kumakaini", "nightbot"], username) do
        coins = query_data(:bank, username)
        {stats.level, coins, username}
      end
    end |> Enum.sort |> Enum.reverse |> Enum.take(5) |> Enum.uniq
    top5 = top5 -- [nil]

    top5_length = cond do
      length(top5) < 5 -> length(top5) - 1
      true -> 4
    end

    top5_strings = for x <- 0..top5_length do
      {:ok, {level, coins, username}} = Enum.fetch(top5, x)
      "#{x + 1}. #{username} (Level #{level}, #{coins} Coins)"
    end

    leaderboard = top5_strings |> Enum.join("\n")
    reply "```\n#{leaderboard}\n```"
  end
end
