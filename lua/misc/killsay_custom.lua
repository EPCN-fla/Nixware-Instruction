-- updater: StalkeRR
local messages = {
    {
        "Ниже твоего кд только твой iq",
        "Купи себе ПК, хватит играть на компе из школьной библиотеки",
        "Назвать тебя дауном это комплимент, учитыавя то, насколько ты на самом деле туп.",
        "В твоём теле около 37 миллионов клеток, и ты, прямо сейчас, разочаровываешь их всех.",
        "Если бы я спрыгнул с тоего чсв на твой iq я бы умер на полпути от голода.",
        "Я не trashtalk'аю тебя, я просто говорю с trash'эм",
        "Учёные придумали число 0 когда подсчитали твои шансы сделать что-нибудь полезное.",
        "Ты из тех людей которые занимают третье место, играя 1 v 1",
        "Ты причина легализации абортов.",
        "Кто поставил сложность ботов на мирную?",
        "Я бы назвал тебя раком, но рак убивает.",
        "Я бы спросил сколько тебе лет, но я знаю что ты не умеешь считать до таких больших чисел.",
        "Некоторым  платят за оральный cekc, но ты делаешь это бесплатно.",
        "Две ошибки всегда приводят к третьей. Твои родители наглядный тому пример.",
        "Я бы посоветовал тебе застрелиться, но уверен что ты промажешь.",
        "Посоветуй сайт где можно скинуться тебе на лечение.",
        "Дешевле тебя был только тот рваный гандон который использовал твой отец.",
        "Бог юморист: не веришь — посмотри на себя в зеркало.",
        "Любое сходство между тобой и человеком является чисто случайным.",
        "Твой плейстайл доказательство того, что мастурбация вызывает слепоту",
        "Сразу видно: мать не хотела, отец не старался.",
        "Я уверен что твоя дакимакура гордиться тобой",
        "Некоторых детей роняли на голову, но тебя явно кидали об стену.",
        "Даже если ты выстрелишь в землю, ты промажешь.",
        "Ты знаешь что акулы убивают 5 человек за год? Похоже у тебя есть серьёзные конкуренты.",
        "Выключи кс. Просто выйди на улицу и подойди к ближайшему дереву и извинись за то, что тратишь кислород.",

    },
    {
        "The only thing lower than your k/d ratio is your I.Q.",
        "Your aim is so poor that people held a fundraiser for it",
        "Better buy PC, stop playing at school library",
        "The only thing more unreliable than you is the condom your dad used.",
        "Calling you a retard is a compliment in comparison to how stupid you actually are.",
        "I didnt know dying was a special ability.",
        "If I jumped from your ego to your intelligence, Id die of starvation half-way down.",
        "Studies show that aiming gives you better chances of hitting your target.",
        "You should let your chair play, at least it knows how to support.",
        "There are about 37 trillion cells working together in your body right now, and you are disappointing every single one of them.",
        "I'd call you a tool, but that would imply you were useful in at least one way.",
        "Youre the human equivalent of a participation award.",
        "I'd love to see things from your perspective, but I dont think I could shove my head that far up my ass.",
        "I'm not trash talking, Im talking to trash",
        "Legend has it that the number 0 was first invented after scientists calculated your chance of doing something useful.",
        "You're the type of player to get 3rd place in a 1v1 match",
        "I'm not saying I hate you, but I would unplug your life support to charge my phone.",
        "You're an inspiration for birth control.",
        "Does your ass ever get jealous of the amount of shit that comes out of your mouth",
        "You should turn the game off. Just walk outside and find the nearest tree, then apologise to it for wasting so much oxygen.",
        "I'd tell you to shoot yourself, but I bet youd miss",
        "Did you know sharks only kill 5 people each year? Looks like you got some competition",
        "Some babies were dropped on their heads but you were clearly thrown at a wall",
        "To which foundation do I need to donate to help you?",
        "I'm sure your bodypillow is very proud of you.",
        "Two wrongs dont make a right, take your parents as an example.",
        "I bet the last time u felt a breast was in a kfc bucket",
        "Maybe God made you a bit too special.",
        "I bet your brain feels as good as new, seeing that you never use it.",
        "It must be difficult for you, exhausting your entire vocabulary in one sentence.",
        "You have some big balls on you. Too bad they belong to the guy fucking you from behind.",
        "If only you could hit an enemy as much as your dad hits you.",
        "I'm surprised that you were able hit the Install button",
        "Some people get paid to suck, you do it for free.",
        "I would ask you how old you are but I know you can't count that high.",
        "I'm okay with this team. I work in the city as a garbage collector. I'm used to carrying trash.",
        "You're as dense as a brick, but honestly a less useful one.",
        "I'd call you cancer, but at least cancer gets kills",
        "Who set the bots to passive?",
        "You're the reason abortion was legalized",

    }
}

local kill_spam = ui.add_combo_box("kill spam", "misc_killsay", {
    "nothing",
    "russian",
    "english",
    "custom"
}, 0)

local text_input = ui.add_text_input("custom_killsay", "lua_text", "you killsay")

 local include = ui.add_check_box("include name", "misc_killsay_name", false)


function Killsay(event)
local kill_spamn = kill_spam:get_value()
local includpe = include:get_value()
local custom_say = text_input:get_value()


    if kill_spamn == 0 then
        return
    end
	
	if event:get_name() ~= "player_death" then 
		return 
	end	
   
    local attacker_index = engine.get_player_for_user_id(event:get_int("attacker",0))
	local died_index = engine.get_player_for_user_id(event:get_int("userid",1))
	local me = engine.get_local_player()	
	local died_info = engine.get_player_info(died_index)
	
	
	
        if attacker_index == me and died_index ~= me then
		
            local text = ""			
			
            if includpe then
               text = died_info.name .. ", "
            end			
			
            if messages[kill_spamn] then
                local message = messages[kill_spamn]

                text = text .. message[client.random_int(1, #message)]
            else
                text = text .. custom_say
            end

            engine.execute_client_cmd("say " .. text)
        
		end
end

client.register_callback("fire_game_event",Killsay)