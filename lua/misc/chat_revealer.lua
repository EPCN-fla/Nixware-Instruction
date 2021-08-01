ffi.cdef[[struct c_color { unsigned char clr[4]; };]]
console_color = ffi.new('struct c_color'); console_color.clr[3] = 255;
engine_cvar = ffi.cast("void***", se.create_interface("vstdlib.dll", "VEngineCvar007"))
console_print = ffi.cast("void(__cdecl*)(void*, const struct c_color&, const char*, ...)", engine_cvar[0][25])
this = ffi.cast("unsigned long**", client.find_pattern("client_panorama.dll", "B9 ? ? ? ? E8 ? ? ? ? 8B 5D 08") + 1)[0]
find_hud_element = ffi.cast("unsigned long(__thiscall*)(void*, const char*)", client.find_pattern("client_panorama.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28"))
function get_vfunc(ptr, typedef, index) 
  return ffi.cast(typedef, ffi.cast("void***", ptr)[0][index])
end
hud_chat = find_hud_element(this, "CHudChat")
chat_print = get_vfunc(hud_chat, "void(__cdecl*)(int, int, int, const char*, ...)", 27)
function print_chat(iplayerindex, ifilter, text)
  chat_print(hud_chat, iplayerindex, ifilter, text)
end

team_msg = ui.add_check_box("Team messages", "team_msg", false)
enemy_msg = ui.add_check_box("Enemy messages", "enemy_msg", false)
in_chat = ui.add_check_box("Local chat message", "in_chat", false)
in_console = ui.add_check_box("Console message", "in_console", false)

se.register_event("player_say")

local function on_events(e) -- e = event
    if e:get_name() == "player_say" then
        local user_id = e:get_int("userid", 0)
        local user = engine.get_player_for_user_id(user_id)
        local message = e:get_string("text", "")
        local name = engine.get_player_info(user).name
        local enemies = entitylist.get_players(0)
        for i = 1, #enemies do
            local enemy_index = enemies[i]:get_index()
            if user == enemy_index then
                is_enemy = true
                break
            else
                is_enemy = false
            end
        end
        if is_enemy then
            if enemy_msg:get_value() then
                console_color.clr[0] = 255 -- R
                console_color.clr[1] = 0 -- G
                console_color.clr[2] = 0 -- B
                if in_chat:get_value() then
                    print_chat(0, 0, " \x02\x02[Enemy] \x01" .. name .. " (#" .. user_id .. "): " .. message)
                end
                if in_console:get_value() then
                    console_print(engine_cvar, console_color, "[Enemy] " .. name .. " (#" .. user_id .. "): " .. message .. "\n")
                end
            end
        else
            if team_msg:get_value() then
                console_color.clr[0] = 0 -- R
                console_color.clr[1] = 255 -- G
                console_color.clr[2] = 0 -- B
                if in_chat:get_value() then
                    print_chat(0, 0, " \x04\x04[Teammate] \x01" .. name .. " (#" .. user_id .. "): " .. message)
                end
                if in_console:get_value() then
                    console_print(engine_cvar, console_color, "[Teammate] " .. name .. " (#" .. user_id .. "): " .. message .. "\n")
                end
            end
        end
    end
end

client.register_callback("fire_game_event", on_events)
