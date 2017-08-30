defmodule DiscordKuma.Bot do
  use DiscordKuma.{Module, Commands}
  import DiscordKuma.Util

  handle :MESSAGE_CREATE do
    match "!help", do: reply "https://github.com/KumaKaiNi/discord-kuma"
    match "!avatar", :avatar
    match "!uptime", :uptime
    match "!time", :local_time
    match ["!coin", "!flip"], do: reply Enum.random(["Heads.", "Tails."])
    match ["!pick", "!choose"], :pick
    match "!roll", :roll
    match "!predict", :prediction
    match "!smug", :smug
    match "!np", :lastfm_np
    match "!guidance", :souls_message
    match "!quote", :get_quote
    match "!safe", :safebooru
    match "!jackpot", :get_jackpot
    match "!top5", :get_top_five
    match "!stats", :get_stats
    match "!markov", :get_markov
    match ["ty kuma", "thanks kuma", "thank you kuma"], :ty_kuma
    match_all :custom_command

    enforce :nsfw do
      match "!dan", :danbooru
      match "!ecchi", :ecchibooru
      match "!lewd", :lewdbooru
      match ["!nhen", "!nhentai", "!doujin"], :nhentai
    end

    match ["hello", "hi", "hey", "sup"], :hello
    match ["same", "Same", "SAME"], :same

    enforce :dm do
      match "!link", :link_twitch_account
      match "!coins", :coins
      match "!level", :level_up
      match "!slots", :slot_machine
      match "!lottery", :buy_lottery_ticket
    end

    enforce :admin do
      match "!kuma", :kuma
      match "!setup", :setup
      match "!addrole", :add_role
      match "!delrole", :del_role
      match "!setlog", :set_log_channel
      match "!dellog", :del_log_channel
      match "!add", :add_custom_command
      match "!del", :del_custom_command
      match "!addquote", :add_quote
      match "!delquote", :del_quote
      match "!draw", :lottery_drawing
      match "!giftall", :gift_all_coins
    end
  end

  handle :PRESENCE_UPDATE, do: announce(msg)

  def handle_event(_, state), do: {:ok, state}

  def admin(msg) do
    user_id = msg.author.id
    rekyuu_id = 107977662680571904

    cond do
      user_id == rekyuu_id -> true
      true ->
        guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]

        case guild_id do
          nil -> false
          guild_id ->
            {:ok, member} = Nostrum.Api.get_member(guild_id, user_id)

            db = query_data("guilds", guild_id)

            cond do
              db == nil -> false
              db.admin_roles == [] -> false
              true -> Enum.member?(for role <- member["roles"] do
                {role_id, _} = role |> Integer.parse
                Enum.member?(db.admin_roles, role_id)
              end, true)
            end
        end
    end
  end

  def dm(msg) do
    guild_id = Nostrum.Api.get_channel!(msg.channel_id)["guild_id"]
    guild_id == nil
  end

  def nsfw(msg) do
    {:ok, channel} = Nostrum.Api.get_channel(msg.channel_id)
    channel["nsfw"]
  end
end
