
--credits: https://nixware.cc/members/73215/

folder = io.popen('cd'):read('*l') .. '\\nix\\valorant'

firstkill = {

    prefix = "firstkill",
    frames = 49,
    animateframes = {  },
    counter = 1,
}

secondkill = {

    prefix = "secondkill",
    frames = 49,
    animateframes = {  },
    counter = 1,
}

thirdkill = {

    prefix = "thirdkill",
    frames = 49,
    animateframes = {  },
    counter = 1,
}

fourthkill = {

    prefix = "fourthkill",
    frames = 45,
    animateframes = {  },
    counter = 1,
}

fivekill = {

    prefix = "fivekill",
    frames = 81,
    animateframes = {  },
    counter = 1,
}


local killtypes = { firstkill, secondkill, thirdkill, fourthkill, fivekill }

local screensize = engine.get_screen_size()
local timestamp = 0

local totalkills = 0
local startanimate = false

announcer_enabled = ui.add_check_box("enabled", "kill_announcer_enabled", false)
announcer_sound_enabled = ui.add_check_box("sound", "kill_announcer_sound_enabled", false)


for i = 1, #killtypes do 

    for j = 0, killtypes[i]["frames"] do

        table.insert(killtypes[i]["animateframes"], renderer.setup_texture(folder .. '/' .. killtypes[i]["prefix"] .. tostring(j) .. ".png"))
    end
end

function DropFramesData()

    timestamp = 0
    
    startanimate = false

    for i = 1, #killtypes do

        killtypes[i]["counter"] = 1
    end
end

function SetScriptDataToDefault()

    DropFramesData()

    totalkills = 0
end

client.register_callback("fire_game_event", function(event)

    if announcer_enabled:get_value() == false then return end


    if event:get_name() == "client_disconnect" or event:get_name() == "player_connect_full" or event:get_name() == "round_start" then

        SetScriptDataToDefault()
    end

    if event:get_name() == "player_death" then

        local attacker = engine.get_player_for_user_id(event:get_int("attacker", 0))
        local dead = engine.get_player_for_user_id(event:get_int("userid", 0))

        local player = engine.get_local_player()

        if attacker == player and player ~= dead then

            DropFramesData()

            if totalkills < #killtypes then
                totalkills = totalkills + 1
            end

            if announcer_sound_enabled:get_value() then

                engine.execute_client_cmd("play " .. "../../nix/valorant/" .. killtypes[totalkills]["prefix"] .. ".wav")
            end
            
            startanimate = true
        end

        if player == dead then

            SetScriptDataToDefault()
        end
    end
end)

client.register_callback("paint", function()

    if killtypes[totalkills]["counter"] > killtypes[totalkills]["frames"] then

        DropFramesData()
    end

    if startanimate == false then return end

    local width = 280
    local height = 140

    local x = screensize.x / 2 - width / 2
    local y = screensize.y - height - 60

    local curtime = math.floor(globalvars.get_current_time() * 1000)

    
    if timestamp < curtime then

        timestamp = curtime + 30
        killtypes[totalkills]["counter"] = killtypes[totalkills]["counter"] + 1
    end

    renderer.texture(killtypes[totalkills]["animateframes"][killtypes[totalkills]["counter"]], vec2_t.new(x, y), vec2_t.new(x + width, y + height), color_t.new(255, 255, 255, 255))
end)