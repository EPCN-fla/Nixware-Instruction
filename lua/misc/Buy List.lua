local ToggleList = ui.add_multi_combo_box("Buy List Type", "ToggleList", { "Buy List", "Logs", "In TAB (Soon)" }, { true, false, false })

local color = ui.add_color_edit('color edit', 'color', false, color_t.new(255, 255, 255, 255))

x = 0
y = 600
w = 130
h = 25
custom_w = 130
custom_h = 25
g_Alpha = 0
Timer = 0
MoveIt = 0
StartPos = { 0, 0 }
StickToSide = { 0, 0 }
People_Purchase = { }
Weapon_Purchase = { }

local screen_size = engine.get_screen_size()
local tahoma = renderer.setup_font("C:/windows/fonts/tahoma.ttf", 25, 0)
local icons = renderer.setup_font("C:/windows/fonts/csgo_icons.ttf", 25, 0)

local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")

client.register_callback("paint", function()
	--if not ToggleList:get_value(0) or not engine.is_connected() then return end	
	--ALPHA
	if Timer > globalvars.get_current_time() or ui.is_visible() then
		if g_Alpha ~= 240 then g_Alpha = g_Alpha + 5 end
	else
		if g_Alpha ~= 0 then g_Alpha = g_Alpha - 5 end
	end
	
	if g_Alpha == 0 then return end
	
	if x < 0 then x = 0 end
	if x + custom_w > screen_size.x then
		x = screen_size.x - custom_w
		StickToSide[0] = 1
	end
	if y < 16 then y = 16 end
	if y + custom_h > screen_size.y then
		y = screen_size.y - custom_h
		StickToSide[1] = 1
	end
	if StickToSide[0] == 1 then x = screen_size.x - custom_w end
	if StickToSide[1] == 1 then y = screen_size.y - custom_h end
	
	--MAIN
    renderer.rect_filled(vec2_t.new(x, y - 16), vec2_t.new(x + custom_w, y + custom_h), color_t.new(15, 15, 15, g_Alpha))
	renderer.rect(vec2_t.new(x, y - 16), vec2_t.new(x + custom_w, y + custom_h), color_t.new(75, 75, 75, g_Alpha))
	renderer.rect(vec2_t.new(x + 1, y - 16 + 1), vec2_t.new(x + custom_w - 1, y + custom_h - 1), color_t.new(75, 75, 75, g_Alpha))
	renderer.rect(vec2_t.new(x + 2, y - 16 + 2), vec2_t.new(x + custom_w - 2, y + custom_h - 2), color_t.new(75, 75, 75, g_Alpha))
	--LEBEL
	local colorline = color:get_value()

	local r = colorline.r
	local g = colorline.g
    local b = colorline.b
	
	renderer.text("Buy List", tahoma, vec2_t.new(x + custom_w / 2 - renderer.get_text_size(tahoma, 15, "Buy List").x / 2, y - 14), 15, color_t.new(255, 255, 255, g_Alpha) )
	renderer.rect_filled_fade(vec2_t.new(x + 3, y - 7), vec2_t.new(x + custom_w / 2 - renderer.get_text_size(tahoma, 15, "Buy List").x / 2 - 1, y - 5), color_t.new(r, g, b, 0), color_t.new(r, g, b, g_Alpha), color_t.new(r, g, b, g_Alpha), color_t.new(r, g, b, 0))
	renderer.rect_filled_fade(vec2_t.new(x + custom_w / 2 + renderer.get_text_size(tahoma, 15, "Buy List").x / 2 + 1, y - 7), vec2_t.new(x + custom_w - 3, y - 5), color_t.new(r, g, g, g_Alpha), color_t.new(r, g, b, 0), color_t.new(r, g, b, 0), color_t.new(r, g, b, g_Alpha))
	
	w = 130
	h = 25
	
	for i = 1, #People_Purchase do
		if People_Purchase[i] ~= "" then
			renderer.text(People_Purchase[i], tahoma, vec2_t.new(x + 6, y + i * 18 - 15), 15, color_t.new(255, 255, 255, g_Alpha))
			renderer.text(Weapon_Purchase[i], icons, vec2_t.new(x + 10 + renderer.get_text_size(tahoma, 15, People_Purchase[i]).x, y + i * 18 - 14), 15, color_t.new(255, 255, 255, g_Alpha))
			if w < renderer.get_text_size(tahoma, 15, People_Purchase[i]).x - renderer.get_text_size(tahoma, 15, People_Purchase[i]).x%1 + renderer.get_text_size(icons, 15, Weapon_Purchase[i]).x - renderer.get_text_size(icons, 15, Weapon_Purchase[i]).x%1 + 14 then
				w = renderer.get_text_size(tahoma, 15, People_Purchase[i]).x + renderer.get_text_size(icons, 15, Weapon_Purchase[i]).x + 14 - renderer.get_text_size(tahoma, 15, People_Purchase[i]).x%1 - renderer.get_text_size(icons, 15, Weapon_Purchase[i]).x%1
			end
			h = i * 19 + 5
		end
	end
	
	if custom_w ~= w then
		if custom_w < w then
			custom_w = custom_w + 1
		else
			custom_w = custom_w - 1
		end
	end
	if custom_h ~= h then
		if custom_h < h then
			custom_h = custom_h + 1
		else
			custom_h = custom_h - 1
		end
	end
	
	--MOVE
	if not ui.is_visible() then return end
	
	local mouse_pos = renderer.get_cursor_pos()
	
	if mouse_pos.x >= x and mouse_pos.x <= x + custom_w and mouse_pos.y >= y - 16 and mouse_pos.y <= y + custom_h and MoveIt == 0 and client.is_key_pressed(1) then
		StartPos[0] = mouse_pos.x - x
		StartPos[1] = mouse_pos.y - y
		MoveIt = 1
	end
	
	if MoveIt == 1 then
		x = mouse_pos.x - StartPos[0]
		y = mouse_pos.y - StartPos[1]
		StickToSide[0] = 0
		StickToSide[1] = 0
	end
	
	if client.is_key_pressed(1) then
		if MoveIt == 0 and MoveIt ~= 1 then
			MoveIt = -1
		end
	else
		MoveIt = 0
	end
end)

client.register_callback("fire_game_event", function(event) 
    if event:get_name() ~= "round_start" then return end
	
	Timer = globalvars.get_current_time() + 20
    People_Purchase = { }
	Weapon_Purchase = { }
	
end)

client.register_callback("fire_game_event", function(event) 
    if event:get_name() ~= "item_purchase" then return end
	if event:get_int( "team", -1 ) == entitylist.get_local_player():get_prop_int( m_iTeamNum ) then return end
	
	if Timer < globalvars.get_current_time() + 3 then
		Timer = globalvars.get_current_time() + 3
	end
	
    nickname = engine.get_player_info(engine.get_player_for_user_id(event:get_int("userid", 0))).name .. " bought"
	nickname2 = nickname
	weapon = event:get_string("weapon", "")
	
	if ToggleList:get_value(1) then
		client.notify(nickname .. " " .. weapon)
	end
	
	local players = entitylist.get_players(2)
	for i = 1, #players do
		if nickname == People_Purchase[i] then
			nickname = nil
		end
	end
	
	for i = 1, #players do
		if People_Purchase[i] == nil and nickname ~= nil then
			People_Purchase[i] = nickname

			break
		end
	end
	
	if weapon == "item_defuser" then
		weapon = "E"
	elseif weapon == "item_kevlar" then
		weapon = "C"
	elseif weapon == "item_assaultsuit" then
		weapon = "D"
	elseif weapon == "weapon_decoy" then
		weapon = "F"
	elseif weapon == "weapon_flashbang" then
		weapon = "G"
	elseif weapon == "weapon_hegrenade" then
		weapon = "H"
	elseif weapon == "weapon_smokegrenade" then
		weapon = "I"
	elseif weapon == "weapon_molotov" then
		weapon = "J"
	elseif weapon == "weapon_incgrenade" then
		weapon = "K"
	elseif weapon == "weapon_taser" then
		weapon = "L"
	elseif weapon == "weapon_hkp2000" then
		weapon = "1"
	elseif weapon == "weapon_usp_silencer" then
		weapon = "2"
	elseif weapon == "weapon_p250" then
		weapon = "3"
	elseif weapon == "weapon_elite" then
		weapon = "4"
	elseif weapon == "weapon_cz75a" then
		weapon = "5"
	elseif weapon == "weapon_tec9" then
		weapon = "6"
	elseif weapon == "weapon_fiveseven" then
		weapon = "7"
	elseif weapon == "weapon_deagle" then
		weapon = "8"
	elseif weapon == "weapon_revolver" then
		weapon = "9"
	elseif weapon == "weapon_glock" then
		weapon = "0"
	elseif weapon == "weapon_mac10" then
		weapon = "a"
	elseif weapon == "weapon_mp9" then
		weapon = "b"
	elseif weapon == "weapon_ump45" then
		weapon = "c"
	elseif weapon == "weapon_mp7" then
		weapon = "d"
	elseif weapon == "weapon_p90" then
		weapon = "e"
	elseif weapon == "weapon_bizon" then
		weapon = "f"
	elseif weapon == "weapon_nova" then
		weapon = "g"
	elseif weapon == "weapon_sawedoff" then
		weapon = "h"
	elseif weapon == "weapon_xm1014" then
		weapon = "j"
	elseif weapon == "weapon_negev" then
		weapon = "k"
	elseif weapon == "weapon_m249" then
		weapon = "l"
	elseif weapon == "weapon_galilar" then
		weapon = "m"
	elseif weapon == "weapon_ak47" then
		weapon = "n"
	elseif weapon == "weapon_sg556" then
		weapon = "o"
	elseif weapon == "weapon_famas" then
		weapon = "p"
	elseif weapon == "weapon_m4a1" then
		weapon = "q"
	elseif weapon == "weapon_m4a1_silencer" then
		weapon = "r"
	elseif weapon == "weapon_aug" then
		weapon = "s"
	elseif weapon == "weapon_ssg08" then
		weapon = "t"
	elseif weapon == "weapon_awp" then
		weapon = "u"
	elseif weapon == "weapon_g3sg1" then
		weapon = "v"
	elseif weapon == "weapon_scar20" then
		weapon = "w"
	elseif weapon == "weapon_mp5sd" then
		weapon = "x"
	end
	
	for i = 1, #players do
		if nickname2 == People_Purchase[i] then
			if Weapon_Purchase[i] == nil then
				Weapon_Purchase[i] = weapon
			else
				Weapon_Purchase[i] = Weapon_Purchase[i] .. weapon
			end
			
			break
		end
	end
end)

se.register_event("round_start")
se.register_event("item_purchase")