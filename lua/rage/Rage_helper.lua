--[[
    # Author: Fla1337
    # Description: Just for rage.
    # Reference:
		RageEssentials.lua(https://nixware.cc/threads/16812/);
		Indicators.lua(https://nixware.cc/threads/12008/);
		simple_hitlist.lua(https://nixware.cc/threads/14831/);
		DT Helper.lua(https://nixware.cc/threads/15098/);
		watermark.lua(https://nixware.cc/threads/14858/);
		Indicators.lua(https://nixware.cc/threads/17596/);
		Thirdperson.lua(https://nixware.cc/threads/15966/);
		and many other scripts
--]]

require 'AdvancedAPI'

local m_bSpotted = se.get_netvar("DT_BaseEntity", "m_bSpotted")
local m_vecOrigin = se.get_netvar("DT_BaseEntity", "m_vecOrigin")
local m_fLastShotTime = se.get_netvar("DT_WeaponCSBase", "m_fLastShotTime")
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")
local m_vecVelocity = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]")
local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")
local m_iItemDefinitionIndex = se.get_netvar("DT_BaseAttributableItem", "m_iItemDefinitionIndex")
local m_flDuckAmount = se.get_netvar("DT_BasePlayer", "m_flDuckAmount");

local sv_maxunlag = se.get_convar("sv_maxunlag")
local sv_maxunlag_original = sv_maxunlag:get_float()

--[[

local m_vecViewOffset = se.get_netvar("DT_BasePlayer", "m_vecViewOffset[0]")

local function get_eyes_pos()
	local local_player = entitylist.get_local_player()
	local origin = local_player:get_prop_vector(m_vecOrigin)
	local view_offset = local_player:get_prop_vector(m_vecViewOffset)
	return vec3_t.new(origin.x + view_offset.x, origin.y + view_offset.y, origin.z + view_offset.z)
end

local function get_aim_angle(entity)
	local pos = entity:get_player_hitbox_pos(8)
	local eyes = get_eyes_pos()
	local vec = vec3_t.new(pos.x - eyes.x, pos.y - eyes.y, pos.z - eyes.z)
	local hyp = math.sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z)
	
	local pitch = -math.asin(vec.z / hyp) * 57.29578
	if pitch > 89.0 then pitch = 89.0 end
	if pitch < -89.0 then pitch = -89.0 end
	
	local yaw = math.atan2(vec.y, vec.x) * 57.29578
	while yaw < -180.0 do angle = angle + 360.0 end
	while yaw > 180.0 do angle = angle - 360.0 end
	
	return angle_t.new(pitch, yaw, 0)
end

local knifebot_attack_time = 0.0
local knifebot_target = 0

]]--

-- Hitboxes

local hitboxes = 
{
	"head",
	"neck",
	"pelvis",
	"stomach",
	"thorax",
	"lower chest",
	"upper chest",
	"right thigh",
	"left thigh",
	"right calf",
	"left calf",
	"right foot",
	"left foot",
	"right hand",
	"left hand",
	"right upper arm",
	"right forearm",
	"left upper arm",
	"left forearm"
}

local hitscan =
{
	"Head",
	"Pelvis",
	"Stomach",
	"Chest",
	"Legs",
	"Foot"
}

local hitboxes_hit = {
	"head",
	"neck",
	"pelvis",
	"stomach",
	"low chest",
	"chest",
	"up chest",
	"r thigh",
	"l thigh",
	"r calf",
	"l calf",
	"r foot",
	"l foot",
	"r hand",
	"left hand",
	"r up arm", 
	"r forearm",
	"r left arm", 
    "l forearm"
}

local SCAN_HEAD = 0
local SCAN_CHEST = 1
local SCAN_PELVIS = 2
local SCAN_STOMACH = 3
local SCAN_LEGS = 4
local SCAN_FOOT = 5

--Main
local lua_re_menu = ui.add_combo_box("Menu", "lua_menu", { "Rage", "MinDmg", "DT/HS/FL/FD", "Visuals" }, 0)

local lua_re_ragelogs = ui.add_check_box("Rage Logs", "lua_re_ragelogs", false)
local lua_re_votelogs = ui.add_check_box("Vote Logs", "lua_re_votelogs", false)
local lua_re_buylogs = ui.add_check_box("Buy Logs", "lua_re_buylogs", false)

local lua_re_autopeek = ui.add_key_bind("Autopeek", "lua_re_autopeek", 0, 1)
local lua_re_autopeek_circle = ui.add_color_edit("Autopeek Circle", "lua_re_autopeek_circle", true, color_t.new(255, 0, 0, 120))

local scale_thirdperson = ui.add_check_box("Thirdperson Distance", "scale_thirdperson", false)
local thirdperson_scale = ui.add_slider_int("Thirdperson Scale", "thirdperson_scale", 65, 200, 120)

local lua_re_thirdperson_bind = ui.add_key_bind("Thirdperson", "lua_re_thirdperson_bind", 0, 2)
local lua_re_onlyhead_bind = ui.add_key_bind("Only Head", "lua_re_onlyhead_bind", 0, 2)
local lua_re_baim_bind = ui.add_key_bind("Force BAIM", "lua_re_baim_bind", 0, 2)
local lua_re_laim_bind = ui.add_key_bind("Wash Legs", "lua_re_laim_bind", 0, 2)
local lua_re_safepoints_bind = ui.add_key_bind("Force Safepoints", "lua_re_safepoints_bind", 0, 2)
local lua_re_lethal_bind = ui.add_key_bind("Force Lethal Shots", "lua_re_lethal_bind", 0, 2)
local lua_re_mindmg_bind = ui.add_key_bind("Min Damage", "lua_re_mindmg_bind", 0, 2)
local lua_re_pingspike_bind = ui.add_key_bind("Ping Spike", "lua_re_pingspike_bind", 0, 2)
local lua_re_pingspike = ui.add_slider_int("Ping Spike Value", "lua_re_pingspike", 0, 200, 0)
local lua_re_resolver_override_bind = ui.add_key_bind("Resolver Override", "lua_re_resolver_override_bind", 0, 2)

local lua_re_dmgoverride_bind = ui.add_key_bind("Damage Override", "lua_re_dmgoverride_bind", 0, 2)
local lua_re_dmgoverride = ui.add_slider_int("Damage Override Value", "lua_re_dmgoverride", 0, 100, 0)

local lua_re_switchexploit = ui.add_key_bind("Switch Exploit", "lua_re_switchexploit", 0, 1)

local lua_re_bt = ui.add_slider_float("Backtrack", "lua_re_bt", 0, 0.2, 0)
local lua_re_bt_onxploit = ui.add_slider_float("Backtrack On Exploit", "lua_re_bt_onxploit", 0, 0.2, 0)


-- Rage

	-- Global variate

	local switching_exploit = false

	local autopeek_accuracy = 10.0
	local autopeek_pos = vec3_t.new(0, 0, 0)
	local autopeek_return = false
	local autopeek_last_shot = 0

	local once_thirdperson = false

	local vote_options = {}

	local player_shots = {}
	for i = 0, 64 do player_shots[i] = 0.0 end

	local function get_team_name(team)
		if team == 3 then
			return "CT"
		elseif team == 2 then
			return "T"
		else
			return "Spectator"
		end
	end
	
	se.register_event("vote_cast")
	se.register_event("vote_options")
	se.register_event("weapon_fire")
	se.register_event("player_death")
	se.register_event("player_spawn")
	se.register_event("item_purchase")
	se.register_event("player_hurt")

	--

	local function keybinds(cmd)
		local entity = entitylist.get_players(0)

		for i = 1, #entity do
			local player = entity[i]
			--binds
			if lua_re_onlyhead_bind:is_active() then

				ragebot.override_hitscan(player:get_index(), SCAN_HEAD, true)
				ragebot.override_hitscan(player:get_index(), SCAN_CHEST, false)
				ragebot.override_hitscan(player:get_index(), SCAN_PELVIS, false)
				ragebot.override_hitscan(player:get_index(), SCAN_STOMACH, false)
				ragebot.override_hitscan(player:get_index(), SCAN_LEGS, false)
				ragebot.override_hitscan(player:get_index(), SCAN_FOOT, false)

			end

			if lua_re_baim_bind:is_active() then

				ragebot.override_hitscan(player:get_index(), SCAN_HEAD, false)
				ragebot.override_hitscan(player:get_index(), SCAN_CHEST, true)
				ragebot.override_hitscan(player:get_index(), SCAN_PELVIS, true)
				ragebot.override_hitscan(player:get_index(), SCAN_STOMACH, true)
				ragebot.override_hitscan(player:get_index(), SCAN_LEGS, false)
				ragebot.override_hitscan(player:get_index(), SCAN_FOOT, false)

			end

			if lua_re_laim_bind:is_active() then

				ragebot.override_hitscan(player:get_index(), SCAN_HEAD, false)
				ragebot.override_hitscan(player:get_index(), SCAN_CHEST, false)
				ragebot.override_hitscan(player:get_index(), SCAN_PELVIS, false)
				ragebot.override_hitscan(player:get_index(), SCAN_STOMACH, false)
				ragebot.override_hitscan(player:get_index(), SCAN_LEGS, true)
				ragebot.override_hitscan(player:get_index(), SCAN_FOOT, true)
			end

			if lua_re_safepoints_bind:is_active() then
				ragebot.override_safe_point(player:get_index(), 2)
			end

			if lua_re_lethal_bind:is_active() then
				local health = entity:get_prop_int(m_iHealth)
				if ui.get_combo_box("rage_active_exploit"):get_value() == 2 and ui.get_key_bind("rage_active_exploit_bind"):is_active() then
					ragebot.override_min_damage(player:get_index(), (health / 2) + 1)
				else
					ragebot.override_min_damage(player:get_index(), health + 1)
				end
			end

			if lua_re_dmgoverride_bind:is_active() then
				ragebot.override_min_damage(player:get_index(), lua_re_dmgoverride:get_value())
			end
		end
			
		if lua_re_resolver_override_bind:is_active() then
			ui.get_check_box("rage_desync_correction"):set_value(false)
		else
			ui.get_check_box("rage_desync_correction"):set_value(true)
		end
		
		if lua_re_pingspike_bind:is_active() then
			ui.get_slider_int("misc_ping_spike_amount"):set_value(200)
		else
			ui.get_slider_int("misc_ping_spike_amount"):set_value(0)
		end

		if scale_thirdperson:get_value() then 
			se.get_convar("cam_idealdist"):set_int(scale_thirdperson:get_value() and thirdperson_scale:get_value() or 120) 
		end
		if scale_thirdperson:get_value() and not once_thirdperson then 
			once_thirdperson = not once_thirdperson 
		end
		if not scale_thirdperson:get_value() and once_thirdperson then 
			once_thirdperson = not once_thirdperson 
			se.get_convar("cam_idealdist"):set_int(120) 
		end
	end

	local old_counter = 20
	local counter = 20

	ui.get_key_bind("visuals_other_thirdperson_bind"):set_key(0x00)
	ui.get_key_bind("visuals_other_thirdperson_bind"):set_type(0)
	ui.get_check_box("visuals_other_thirdperson"):set_value(false)
	ui.get_check_box("visuals_other_force_thirdperson"):set_value(false)

	local function thirdperson_smooth()
		if lua_re_thirdperson_bind:is_active() then
	
			if counter ~= 150 then
				 counter = counter + 2
			end
	
		else
	
			if counter ~= 20 then
				counter = counter - 2
		   end
	
		end
		
		if old_counter ~= counter then
			engine.execute_client_cmd("cam_idealdist " .. counter .. "")
			old_counter = counter
		end
	
		if counter >= 40 then
			ui.get_check_box("visuals_other_thirdperson"):set_value(true)
			ui.get_check_box("visuals_other_force_thirdperson"):set_value(true)
		else
			ui.get_check_box("visuals_other_thirdperson"):set_value(false)
			ui.get_check_box("visuals_other_force_thirdperson"):set_value(false)
		end
	end

	local function ping_spike()
		local ping_spike_amount = ui.get_slider_int("misc_ping_spike_amount")
		local ping_spike_backup = ping_spike_amount:get_value()

		if lua_re_pingspike_bind:is_active() then
			ping_spike_amount:set_value(lua_re_pingspike:get_value())
		else
			ping_spike_amount:set_value(ping_spike_backup)
		end
	end

	local function autopeek(cmd)
		if not autopeek_return then
			local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
			local last_shot = weapon:get_prop_float(m_fLastShotTime)
			if last_shot > autopeek_last_shot then
				autopeek_last_shot = last_shot
				autopeek_return = true
			end
		end
		if lua_re_autopeek:is_active() then
			if autopeek_pos:length() == 0 then
				autopeek_pos = entitylist.get_local_player():get_prop_vector(m_vecOrigin)
			end
		else
			autopeek_return = false
			autopeek_pos = vec3_t.new(0, 0, 0)
		end
		if autopeek_return then
			local pos = entitylist.get_local_player():get_prop_vector(m_vecOrigin)
			if pos:dist_to(autopeek_pos) > autopeek_accuracy then
				local direction = vec3_t.new(pos.x - autopeek_pos.x, pos.y - autopeek_pos.y, pos.z - autopeek_pos.z)
				direction = vec3_t.new(direction.x / direction:length(), direction.y / direction:length(), direction.z / direction:length())
				local rx = direction.x * math.cos(engine.get_view_angles().yaw / 180.0 * math.pi) + direction.y * math.sin(engine.get_view_angles().yaw / 180.0 * math.pi)
				local ry = direction.y * math.cos(engine.get_view_angles().yaw / 180.0 * math.pi) - direction.x * math.sin(engine.get_view_angles().yaw / 180.0 * math.pi)
				cmd.forwardmove = -rx * 450.0
				cmd.sidemove = ry * 450.0
			else
				if entitylist.get_local_player():get_prop_vector(m_vecVelocity):length() < 130.0 then
					autopeek_return = false
				end
			end
		end
	end

	local function switch_exploit()
		if lua_re_switchexploit:is_active() then
			if not switching_exploit then
				if ui.get_combo_box("rage_active_exploit"):get_value() == 1 then
					ui.get_combo_box("rage_active_exploit"):set_value(2)
				elseif ui.get_combo_box("rage_active_exploit"):get_value() == 2 then
					ui.get_combo_box("rage_active_exploit"):set_value(1)
				end
				switching_exploit = true
			end
		else
			switching_exploit = false
		end
	end

	local function backtracking()
		if ui.get_combo_box("rage_active_exploit"):get_value() ~= 0 and ui.get_key_bind("rage_active_exploit_bind"):is_active() then 
			sv_maxunlag:set_float(lua_re_bt_onxploit:get_value())
		else
			sv_maxunlag:set_float(lua_re_bt:get_value())
		end
	end

	local function on_events(event)
		if event:get_name() == "vote_cast" then
			if lua_re_votelogs:get_value() == true then
				local entity_id = event:get_int("entityid", 0)
				local vote_option = vote_options[event:get_int("vote_option", 0) + 1]
				local team = get_team_name(event:get_int("team", 0))
				local player_info = engine.get_player_info(entity_id)
				local line = "[Vote] [" .. team .. "] " .. tostring(player_info.name) .. " has voted " .. string.lower(tostring(vote_option)) .. "."
				client.notify(line)
			end
		end
		if event:get_name() == "vote_options" then
			if lua_re_votelogs:get_value() == true then
				local size = event:get_int("count", 0)
				vote_options = {}
				for i = 1, size do
					local event_name = "option" .. tostring(i)
					table.insert(vote_options, event:get_string(event_name, "?"))
				end
			end
		end
		if event:get_name() == "weapon_fire" then
			player_shots[engine.get_player_for_user_id(event:get_int("userid", 0))] = globalvars.get_current_time()
		end
		if event:get_name() == "player_death" then
			local local_player_userid = engine.get_player_info(engine.get_local_player()).user_id
			local event_userid = event:get_int("userid", 0)
			
			if local_player_userid == event_userid then 
				autopeek_return = false
				autopeek_pos = vec3_t.new(0, 0, 0)
				autopeek_last_shot = 0
			end
		end
		if event:get_name() == "player_spawn" then
			local local_player_userid = engine.get_player_info(engine.get_local_player()).user_id
			local event_userid = event:get_int("userid", 0)
			if local_player_userid == event_userid then 
				knifebot_target = 0
				knifebot_attack_time = 0.0
				autopeek_return = false
				autopeek_pos = vec3_t.new(0, 0, 0)
				autopeek_last_shot = 0
			end
		end
		if event:get_name() == "item_purchase" then
			if lua_re_buylogs:get_value() then
				local entity_id = engine.get_player_for_user_id(event:get_int("userid", 0))
				local lpteam = entitylist.get_local_player():get_prop_int(m_iTeamNum)
				local entteam = entitylist.get_entity_by_index(entity_id):get_prop_int(m_iTeamNum)
				if lpteam ~= entteam then
					local player_name = engine.get_player_info(entity_id).name
					client.notify("[Buy] " .. player_name .. " has bought " .. event:get_string("weapon", "") .. ".")
				end
			end
		end
	end

	local circle_points = 20.0
	local function on_paint_autopeek()
		if autopeek_pos:length() ~= 0 then
			local circle_radius = autopeek_accuracy
			local points = { }
			for i = 1, circle_points do
				local item = vec3_t.new(
					autopeek_pos.x + circle_radius * math.cos(i * (360.0 / circle_points) * 0.017453),
					autopeek_pos.y + circle_radius * math.sin(i * (360.0 / circle_points) * 0.017453),
					autopeek_pos.z + 0.0
				)
				table.insert(points, se.world_to_screen(item))
			end
			
			renderer.filled_polygon(points, lua_re_autopeek_circle:get_value())
			
			local outline = lua_re_autopeek_circle:get_value()
			outline.a = 255
			for i = 1, #points - 1 do
				renderer.line(points[i], points[i + 1], outline)
			end
			renderer.line(points[#points], points[1], outline)
		end
	end

	local function on_create_move(cmd)
		keybinds(cmd)
		ping_spike()
		autopeek(cmd)
		switch_exploit()
		backtracking()
	end

	local function on_shot_fired(shot_info) 
		if lua_re_ragelogs:get_value() then
			if shot_info.result == "hit" and not shot_info.manual then
				client.notify("[Rage] Hit " ..  engine.get_player_info(shot_info.target:get_index()).name .. " in " .. hitboxes[shot_info.server_hitgroup + 1] .. " for " .. tostring(shot_info.server_damage) .. " (" .. tostring(shot_info.client_damage) .. ") (hitchance " .. tostring(shot_info.hitchance) .."%) (bt for " .. tostring(shot_info.backtrack) .. " ticks).")
			end
			if shot_info.result ~= "hit" and not shot_info.manual then
				client.notify("[Rage] Missed shot due to " .. shot_info.result .. " into " .. hitboxes[shot_info.hitbox + 1] .." (hitchance " .. tostring(shot_info.hitchance) .."%) (bt for " .. tostring(shot_info.backtrack) .. " ticks).")
			end
		end
	end

	local function on_unload()
		sv_maxunlag:set_float(sv_maxunlag_original)
		ui.get_check_box("misc_autostrafer"):set_value(true)
		engine.execute_client_cmd("cam_idealdist 150")
	end
	
	client.register_callback("unload", on_unload)
	client.register_callback("paint", on_paint_autopeek)
	client.register_callback("fire_game_event", on_events)
	client.register_callback("frame_stage_notify",thirdperson_smooth)
	client.register_callback("shot_fired", on_shot_fired)
	client.register_callback("create_move", on_create_move)


--MinDmg for all weapons

local lua_re_mindmg_enable = ui.add_check_box('Enable MinDmg', 'lua_re_mindmg_enable', false)
local lua_re_mindmg_weaponconfig = ui.add_multi_combo_box("Weapon Configs","lua_re_mindmg_weaponconfig", {'Pistols', 'Deagle', 'Revolver', 'Smg', 'Rifle', 'Shotguns', 'Scout', 'Auto', 'Awp', 'Taser'}, { false, false, false, false, false, false, false, false, false, false })

--[[
local weapon_groups = {
    'Pistols', 'Deagle', 'Revolver', 'Smg', 'Rifle', 'Shotguns', 'Scout', 'Auto', 'Awp', 'Taser'
}
]]--

pistols_mindmg = ui.add_slider_int('Pistols MinDmg', 'pistols_mindmg', 0, 100, 5)
deagle_mindmg = ui.add_slider_int('Deagle MinDmg', 'deagle_mindmg', 0, 100, 5)
revolver_mindmg = ui.add_slider_int('Revolver MinDmg', 'revolver_mindmg', 0, 100, 5)
smg_mindmg = ui.add_slider_int('Smg MinDmg', 'smg_mindmg', 0, 100, 5)
rifle_mindmg = ui.add_slider_int('Rifle MinDmg', 'rifle_mindmg', 0, 100, 5)
shotguns_mindmg = ui.add_slider_int('Shotguns MinDmg', 'shotguns_mindmg', 0, 100, 5)
scout_mindmg = ui.add_slider_int('Scout MinDmg', 'scout_mindmg', 0, 100, 5)
auto_mindmg = ui.add_slider_int('Auto MinDmg', 'auto_mindmg', 0, 100, 5)
awp_mindmg = ui.add_slider_int('Awp MinDmg', 'awp_mindmg', 0, 100, 5)
taser_mindmg = ui.add_slider_int('Taser MinDmg', 'taser_mindmg', 0, 100, 5)

local function mindmg_override()
	local entity = entitylist.get_players(0)

	for i = 1, #entity do
		local player = entity[i]
		if lua_re_mindmg_enable:get_value() and lua_re_mindmg_bind:is_active() then
			if lua_re_mindmg_weaponconfig:get_value(0) then
				ragebot.override_min_damage(player:get_index(), pistols_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(1) then
				ragebot.override_min_damage(player:get_index(), deagle_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(2) then
				ragebot.override_min_damage(player:get_index(), revolver_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(3) then
				ragebot.override_min_damage(player:get_index(), smg_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(4) then
				ragebot.override_min_damage(player:get_index(), rifle_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(5) then
				ragebot.override_min_damage(player:get_index(), shotguns_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(6) then
				ragebot.override_min_damage(player:get_index(), scout_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(7) then
				ragebot.override_min_damage(player:get_index(), auto_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(8) then
				ragebot.override_min_damage(player:get_index(), awp_mindmg:get_value())
			elseif lua_re_mindmg_weaponconfig:get_value(9) then
				ragebot.override_min_damage(player:get_index(), taser_mindmg:get_value())
			end
		end
	end
end

client.register_callback('create_move', mindmg_override)

local function mindmg_weapon_switch()
	if lua_re_menu:get_value() == 1 then
		if lua_re_mindmg_weaponconfig:get_value(0) then
			pistols_mindmg:set_visible(true)
		else
			pistols_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(1) then
			deagle_mindmg:set_visible(true)
		else
			deagle_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(2) then
			revolver_mindmg:set_visible(true)
		else
			revolver_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(3) then
			smg_mindmg:set_visible(true)
		else
			smg_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(4) then
			rifle_mindmg:set_visible(true)
		else
			rifle_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(5) then
			shotguns_mindmg:set_visible(true)
		else
			shotguns_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(6) then
			scout_mindmg:set_visible(true)
		else
			scout_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(7) then
			auto_mindmg:set_visible(true)
		else
			auto_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(8) then
			awp_mindmg:set_visible(true)
		else
			awp_mindmg:set_visible(false)
		end

		if lua_re_mindmg_weaponconfig:get_value(9) then
			taser_mindmg:set_visible(true)
		else
			taser_mindmg:set_visible(false)
		end
	else
		pistols_mindmg:set_visible(false)
		deagle_mindmg:set_visible(false)
		revolver_mindmg:set_visible(false)
		smg_mindmg:set_visible(false)
		rifle_mindmg:set_visible(false)
		shotguns_mindmg:set_visible(false)
		scout_mindmg:set_visible(false)
		auto_mindmg:set_visible(false)
		awp_mindmg:set_visible(false)
		taser_mindmg:set_visible(false)
	end
end

client.register_callback('paint', mindmg_weapon_switch)


--DT/HS/FL/FD

rage_active_exploit = ui.get_combo_box("rage_active_exploit")
antihit_extra_fakeduck_bind = ui.get_key_bind("antihit_extra_fakeduck_bind")
rage_active_exploit_bind = ui.get_key_bind("rage_active_exploit_bind")
local lua_re_weaponconfig = ui.add_combo_box("Weapon Configs","lua_weaponconfig", {"Auto", "Scout", "Pistols", "Deagle"}, 0)


--Auto
local scar_enable = ui.add_check_box("Enable Superior Auto", "scar_enable", false)
scar_hitscan_hs = ui.add_multi_combo_box('Auto HS/FL/FD Hitscan', 'scar_hitscan_hs', hitscan, { false, false, false, false, false, false })
scar_hitscan_noscope_dt = ui.add_multi_combo_box('Auto DT NoScope Hitscan', 'scar_hitscan_noscope_dt', hitscan, { false, false, false, false, false, false })
scar_hitscan_dt = ui.add_multi_combo_box('Auto DT Hitscan', 'scar_hitscan_dt', hitscan, { false, false, false, false, false, false })
scar_safepoint_hs = ui.add_combo_box('Auto HS/FL/FD Safepoints', 'scar_safepoint_hs', {'default', 'prefer', 'force'}, 0)
scar_headscale_hs = ui.add_slider_int('Auto HS/FL/FD Head Scale', 'scar_headscale_hs', 0, 100, 0)
scar_bodyscale_hs = ui.add_slider_int('Auto HS/FL/FD Body Scale', 'scar_bodyscale_hs', 0, 100, 0)
scar_hitchance_hs = ui.add_slider_int('Auto HS/FL/FD HitChance', 'scar_hitchance_hs', 0, 100, 0)
scar_safepoint_noscope_dt = ui.add_combo_box('Auto DT NoScope Safepoints', 'scar_safepoint_noscope_dt', {'default', 'prefer', 'force'}, 0)
scar_headscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Head Scale', 'scar_headscale_noscope_dt', 0, 100, 0)
scar_bodyscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Body Scale', 'scar_bodyscale_noscope_dt', 0, 100, 0)
scar_hitchance_noscope_dt = ui.add_slider_int('Auto DT NoScope HitChance', 'scar_hitchance_noscope_dt', 0, 100, 0)
scar_safepoint_dt = ui.add_combo_box('Auto DT Safepoints', 'scar_safepoint_dt', {'default', 'prefer', 'force'}, 0)
scar_headscale_dt = ui.add_slider_int('Auto DT Head Scale', 'scar_headscale_dt', 0, 100, 0)
scar_bodyscale_dt = ui.add_slider_int('Auto DT Body Scale', 'scar_bodyscale_dt', 0, 100, 0)
scar_hitchance_dt = ui.add_slider_int('Auto DT HitChance', 'scar_hitchance_dt', 0, 100, 0)

auto_hitscan = ui.get_multi_combo_box("rage_auto_hitscan")
auto_head = ui.get_slider_int("rage_auto_head_pointscale") 
auto_body = ui.get_slider_int("rage_auto_body_pointscale")
auto_sp = ui.get_combo_box("rage_auto_safepoints")
auto_hitchance = ui.get_slider_int("rage_auto_hitchance")
auto_autoscope = ui.get_check_box("rage_auto_autoscope")

auto_hitscan_backup ={}
auto_head_backup = auto_head:get_value()
auto_body_backup = auto_body:get_value()
auto_sp_backup = auto_sp:get_value()
auto_hitchance_backup = auto_hitchance:get_value()
auto_autoscope_backup = auto_autoscope:get_value()
for i = 0, #hitscan - 1 do
	auto_hitscan_backup[i] = auto_hitscan:get_value(i)
end

--Scout
local scout_enable = ui.add_check_box("Enable Superior Scout", "scout_enable", false)
scout_hitscan_hs = ui.add_multi_combo_box('Scout HS/FL/FD Hitscan', 'scout_hitscan_hs', hitscan, { false, false, false, false, false, false })
scout_hitscan_noscope_dt = ui.add_multi_combo_box('Scout DT NoScope Hitscan', 'scout_hitscan_noscope_dt', hitscan, { false, false, false, false, false, false })
scout_hitscan_dt = ui.add_multi_combo_box('Scout DT Hitscan', 'scout_hitscan_dt', hitscan, { false, false, false, false, false, false })
scout_safepoint_hs = ui.add_combo_box('Scout HS/FL/FD Safepoints', 'scout_safepoint_hs', {'default', 'prefer', 'force'}, 0)
scout_headscale_hs = ui.add_slider_int('Scout HS/FL/FD Head Scale', 'scout_headscale_hs', 0, 100, 0)
scout_bodyscale_hs = ui.add_slider_int('Scout HS/FL/FD Body Scale', 'scout_bodyscale_hs', 0, 100, 0)
scout_hitchance_hs = ui.add_slider_int('Scout HS/FL/FD HitChance', 'scout_hitchance_hs', 0, 100, 0)
scout_safepoint_noscope_dt = ui.add_combo_box('Scout DT NoScope Safepoints', 'scout_safepoint_noscope_dt', {'default', 'prefer', 'force'}, 0)
scout_headscale_noscope_dt = ui.add_slider_int('Scout DT NoScope Head Scale', 'scout_headscale_noscope_dt', 0, 100, 0)
scout_bodyscale_noscope_dt = ui.add_slider_int('Scout DT NoScope Body Scale', 'scout_bodyscale_noscope_dt', 0, 100, 0)
scout_hitchance_noscope_dt = ui.add_slider_int('Scout DT NoScope HitChance', 'scout_hitchance_noscope_dt', 0, 100, 0)
scout_safepoint_dt = ui.add_combo_box('Scout DT Safepoints', 'scout_safepoint_dt', {'default', 'prefer', 'force'}, 0)
scout_headscale_dt = ui.add_slider_int('Scout DT Head Scale', 'scout_headscale_dt', 0, 100, 0)
scout_bodyscale_dt = ui.add_slider_int('Scout DT Body Scale', 'scout_bodyscale_dt', 0, 100, 0)
scout_hitchance_dt = ui.add_slider_int('Scout DT HitChance', 'scout_hitchance_dt', 0, 100, 0)

scout_hitscan = ui.get_multi_combo_box("rage_scout_hitscan")
scout_head = ui.get_slider_int("rage_scout_head_pointscale")
scout_body = ui.get_slider_int("rage_scout_body_pointscale")
scout_sp = ui.get_combo_box("rage_scout_safepoints")
scout_hitchance = ui.get_slider_int("rage_scout_hitchance")
scout_autoscope = ui.get_check_box("rage_scout_autoscope")

scout_hitscan_backup ={}
scout_head_backup = scout_head:get_value()
scout_body_backup = scout_body:get_value()
scout_sp_backup = scout_sp:get_value()
scout_hitchance_backup = scout_hitchance:get_value()
scout_autoscope_backup = scout_autoscope:get_value()
for i = 0, #hitscan - 1 do
	scout_hitscan_backup[i] = scout_hitscan:get_value(i)
end

--Pistols
local pistols_enable = ui.add_check_box("Enable Superior Pistols", "pistols_enable", false)
pistols_hitscan_hs = ui.add_multi_combo_box('Pistols HS/FL/FD Hitscan', 'pistols_hitscan_hs', hitscan, { false, false, false, false, false, false })
pistols_hitscan_dt = ui.add_multi_combo_box('Pistols DT Hitscan', 'pistols_hitscan_dt', hitscan, { false, false, false, false, false, false })
pistols_safepoint_hs = ui.add_combo_box('Pistols HS/FL/FD Safepoints', 'pistols_safepoint_hs', {'default', 'prefer', 'force'}, 0)
pistols_headscale_hs = ui.add_slider_int('Pistols HS/FL/FD Head Scale', 'pistols_headscale_hs', 0, 100, 0)
pistols_bodyscale_hs = ui.add_slider_int('Pistols HS/FL/FD Body Scale', 'pistols_bodyscale_hs', 0, 100, 0)
pistols_hitchance_hs = ui.add_slider_int('Pistols HS/FL/FD HitChance', 'pistols_hitchance_hs', 0, 100, 0)
pistols_safepoint_dt = ui.add_combo_box('Pistols DT Safepoints', 'pistols_safepoint_dt', {'default', 'prefer', 'force'}, 0)
pistols_headscale_dt = ui.add_slider_int('Pistols DT Head Scale', 'pistols_headscale_dt', 0, 100, 0)
pistols_bodyscale_dt = ui.add_slider_int('Pistols DT Body Scale', 'pistols_bodyscale_dt', 0, 100, 0)
pistols_hitchance_dt = ui.add_slider_int('Pistols DT HitChance', 'pistols_hitchance_dt', 0, 100, 0)

pistols_hitscan = ui.get_multi_combo_box("rage_pistols_hitscan")
pistols_head = ui.get_slider_int("rage_pistols_head_pointscale")
pistols_body = ui.get_slider_int("rage_pistols_body_pointscale")
pistols_sp = ui.get_combo_box("rage_pistols_safepoints")
pistols_hitchance = ui.get_slider_int("rage_pistols_hitchance")

pistols_hitscan_backup ={}
pistols_head_backup = pistols_head:get_value()
pistols_body_backup = pistols_body:get_value()
pistols_sp_backup = pistols_sp:get_value()
pistols_hitchance_backup = pistols_hitchance:get_value()
for i = 0, #hitscan - 1 do
	pistols_hitscan_backup[i] = pistols_hitscan:get_value(i)
end

--Deagle
local deagle_enable = ui.add_check_box("Enable Superior Deagle", "deagle_enable", false)
deagle_hitscan_hs = ui.add_multi_combo_box('Deagle HS/FL/FD Hitscan', 'deagle_hitscan_hs', hitscan, { false, false, false, false, false, false })
deagle_hitscan_dt = ui.add_multi_combo_box('Deagle DT Hitscan', 'deagle_hitscan_dt', hitscan, { false, false, false, false, false, false })
deagle_safepoint_hs = ui.add_combo_box('Deagle HS/FL/FD Safepoints', 'deagle_safepoint_hs', {'default', 'prefer', 'force'}, 0)
deagle_headscale_hs = ui.add_slider_int('Deagle HS/FL/FD Head Scale', 'deagle_headscale_hs', 0, 100, 0)
deagle_bodyscale_hs = ui.add_slider_int('Deagle HS/FL/FD Body Scale', 'deagle_bodyscale_hs', 0, 100, 0)
deagle_hitchance_hs = ui.add_slider_int('Deagle HS/FL/FD HitChance', 'deagle_hitchance_hs', 0, 100, 0)
deagle_safepoint_dt = ui.add_combo_box('Deagle DT Safepoints', 'deagle_safepoint_dt', {'default', 'prefer', 'force'}, 0)
deagle_headscale_dt = ui.add_slider_int('Deagle DT Head Scale', 'deagle_headscale_dt', 0, 100, 0)
deagle_bodyscale_dt = ui.add_slider_int('Deagle DT Body Scale', 'deagle_bodyscale_dt', 0, 100, 0)
deagle_hitchance_dt = ui.add_slider_int('Deagle DT HitChance', 'deagle_hitchance_dt', 0, 100, 0)

deagle_hitscan = ui.get_multi_combo_box("rage_deagle_hitscan")
deagle_head = ui.get_slider_int("rage_deagle_head_pointscale")
deagle_body = ui.get_slider_int("rage_deagle_body_pointscale")
deagle_sp = ui.get_combo_box("rage_deagle_safepoints")
deagle_hitchance = ui.get_slider_int("rage_deagle_hitchance")

deagle_hitscan_backup ={}
deagle_head_backup = deagle_head:get_value()
deagle_body_backup = deagle_body:get_value()
deagle_sp_backup = deagle_sp:get_value()
deagle_hitchance_backup = deagle_hitchance:get_value()
for i = 0, #hitscan - 1 do
	deagle_hitscan_backup[i] = deagle_hitscan:get_value(i)
end


local function weapon_switch()
	if lua_re_menu:get_value() == 2 then
		if lua_re_weaponconfig:get_value() == 0 then

			scar_enable:set_visible(true)
			scar_hitscan_hs:set_visible(true)
			scar_hitscan_noscope_dt:set_visible(true)
			scar_hitscan_dt:set_visible(true)
			scar_safepoint_hs:set_visible(true)
			scar_headscale_hs:set_visible(true)
			scar_bodyscale_hs:set_visible(true)
			scar_hitchance_hs:set_visible(true)
			scar_safepoint_noscope_dt:set_visible(true)
			scar_headscale_noscope_dt:set_visible(true)
			scar_bodyscale_noscope_dt:set_visible(true)
			scar_hitchance_noscope_dt:set_visible(true)
			scar_safepoint_dt:set_visible(true)
			scar_headscale_dt:set_visible(true)
			scar_bodyscale_dt:set_visible(true)
			scar_hitchance_dt:set_visible(true)

			scout_enable:set_visible(false)
			scout_hitscan_hs:set_visible(false)
			scout_hitscan_noscope_dt:set_visible(false)
			scout_hitscan_dt:set_visible(false)
			scout_safepoint_hs:set_visible(false)
			scout_headscale_hs:set_visible(false)
			scout_bodyscale_hs:set_visible(false)
			scout_hitchance_hs:set_visible(false)
			scout_safepoint_noscope_dt:set_visible(false)
			scout_headscale_noscope_dt:set_visible(false)
			scout_bodyscale_noscope_dt:set_visible(false)
			scout_hitchance_noscope_dt:set_visible(false)
			scout_safepoint_dt:set_visible(false)
			scout_headscale_dt:set_visible(false)
			scout_bodyscale_dt:set_visible(false)
			scout_hitchance_dt:set_visible(false)

			pistols_enable:set_visible(false)
			pistols_hitscan_hs:set_visible(false)
			pistols_hitscan_dt:set_visible(false)
			pistols_safepoint_hs:set_visible(false)
			pistols_headscale_hs:set_visible(false)
			pistols_bodyscale_hs:set_visible(false)
			pistols_hitchance_hs:set_visible(false)
			pistols_safepoint_dt:set_visible(false)
			pistols_headscale_dt:set_visible(false)
			pistols_bodyscale_dt:set_visible(false)
			pistols_hitchance_dt:set_visible(false)

			deagle_enable:set_visible(false)
			deagle_hitscan_hs:set_visible(false)
			deagle_hitscan_dt:set_visible(false)
			deagle_safepoint_hs:set_visible(false)
			deagle_headscale_hs:set_visible(false)
			deagle_bodyscale_hs:set_visible(false)
			deagle_hitchance_hs:set_visible(false)
			deagle_safepoint_dt:set_visible(false)
			deagle_headscale_dt:set_visible(false)
			deagle_bodyscale_dt:set_visible(false)
			deagle_hitchance_dt:set_visible(false)

		elseif lua_re_weaponconfig:get_value() == 1 then

			scar_enable:set_visible(false)
			scar_hitscan_hs:set_visible(false)
			scar_hitscan_noscope_dt:set_visible(false)
			scar_hitscan_dt:set_visible(false)
			scar_safepoint_hs:set_visible(false)
			scar_headscale_hs:set_visible(false)
			scar_bodyscale_hs:set_visible(false)
			scar_hitchance_hs:set_visible(false)
			scar_safepoint_noscope_dt:set_visible(false)
			scar_headscale_noscope_dt:set_visible(false)
			scar_bodyscale_noscope_dt:set_visible(false)
			scar_hitchance_noscope_dt:set_visible(false)
			scar_safepoint_dt:set_visible(false)
			scar_headscale_dt:set_visible(false)
			scar_bodyscale_dt:set_visible(false)
			scar_hitchance_dt:set_visible(false)

			scout_enable:set_visible(true)
			scout_hitscan_hs:set_visible(true)
			scout_hitscan_noscope_dt:set_visible(true)
			scout_hitscan_dt:set_visible(true)
			scout_safepoint_hs:set_visible(true)
			scout_headscale_hs:set_visible(true)
			scout_bodyscale_hs:set_visible(true)
			scout_hitchance_hs:set_visible(true)
			scout_safepoint_noscope_dt:set_visible(true)
			scout_headscale_noscope_dt:set_visible(true)
			scout_bodyscale_noscope_dt:set_visible(true)
			scout_hitchance_noscope_dt:set_visible(true)
			scout_safepoint_dt:set_visible(true)
			scout_headscale_dt:set_visible(true)
			scout_bodyscale_dt:set_visible(true)
			scout_hitchance_dt:set_visible(true)

			pistols_enable:set_visible(false)
			pistols_hitscan_hs:set_visible(false)
			pistols_hitscan_dt:set_visible(false)
			pistols_safepoint_hs:set_visible(false)
			pistols_headscale_hs:set_visible(false)
			pistols_bodyscale_hs:set_visible(false)
			pistols_hitchance_hs:set_visible(false)
			pistols_safepoint_dt:set_visible(false)
			pistols_headscale_dt:set_visible(false)
			pistols_bodyscale_dt:set_visible(false)
			pistols_hitchance_dt:set_visible(false)

			deagle_enable:set_visible(false)
			deagle_hitscan_hs:set_visible(false)
			deagle_hitscan_dt:set_visible(false)
			deagle_safepoint_hs:set_visible(false)
			deagle_headscale_hs:set_visible(false)
			deagle_bodyscale_hs:set_visible(false)
			deagle_hitchance_hs:set_visible(false)
			deagle_safepoint_dt:set_visible(false)
			deagle_headscale_dt:set_visible(false)
			deagle_bodyscale_dt:set_visible(false)
			deagle_hitchance_dt:set_visible(false)

		elseif lua_re_weaponconfig:get_value() == 2 then

			scar_enable:set_visible(false)
			scar_hitscan_hs:set_visible(false)
			scar_hitscan_noscope_dt:set_visible(false)
			scar_hitscan_dt:set_visible(false)
			scar_safepoint_hs:set_visible(false)
			scar_headscale_hs:set_visible(false)
			scar_bodyscale_hs:set_visible(false)
			scar_hitchance_hs:set_visible(false)
			scar_safepoint_noscope_dt:set_visible(false)
			scar_headscale_noscope_dt:set_visible(false)
			scar_bodyscale_noscope_dt:set_visible(false)
			scar_hitchance_noscope_dt:set_visible(false)
			scar_safepoint_dt:set_visible(false)
			scar_headscale_dt:set_visible(false)
			scar_bodyscale_dt:set_visible(false)
			scar_hitchance_dt:set_visible(false)

			scout_enable:set_visible(false)
			scout_hitscan_hs:set_visible(false)
			scout_hitscan_noscope_dt:set_visible(false)
			scout_hitscan_dt:set_visible(false)
			scout_safepoint_hs:set_visible(false)
			scout_headscale_hs:set_visible(false)
			scout_bodyscale_hs:set_visible(false)
			scout_hitchance_hs:set_visible(false)
			scout_safepoint_noscope_dt:set_visible(false)
			scout_headscale_noscope_dt:set_visible(false)
			scout_bodyscale_noscope_dt:set_visible(false)
			scout_hitchance_noscope_dt:set_visible(false)
			scout_safepoint_dt:set_visible(false)
			scout_headscale_dt:set_visible(false)
			scout_bodyscale_dt:set_visible(false)
			scout_hitchance_dt:set_visible(false)

			pistols_enable:set_visible(true)
			pistols_hitscan_hs:set_visible(true)
			pistols_hitscan_dt:set_visible(true)
			pistols_safepoint_hs:set_visible(true)
			pistols_headscale_hs:set_visible(true)
			pistols_bodyscale_hs:set_visible(true)
			pistols_hitchance_hs:set_visible(true)
			pistols_safepoint_dt:set_visible(true)
			pistols_headscale_dt:set_visible(true)
			pistols_bodyscale_dt:set_visible(true)
			pistols_hitchance_dt:set_visible(true)

			deagle_enable:set_visible(false)
			deagle_hitscan_hs:set_visible(false)
			deagle_hitscan_dt:set_visible(false)
			deagle_safepoint_hs:set_visible(false)
			deagle_headscale_hs:set_visible(false)
			deagle_bodyscale_hs:set_visible(false)
			deagle_hitchance_hs:set_visible(false)
			deagle_safepoint_dt:set_visible(false)
			deagle_headscale_dt:set_visible(false)
			deagle_bodyscale_dt:set_visible(false)
			deagle_hitchance_dt:set_visible(false)

		elseif lua_re_weaponconfig:get_value() == 3 then

			scar_enable:set_visible(false)
			scar_hitscan_hs:set_visible(false)
			scar_hitscan_noscope_dt:set_visible(false)
			scar_hitscan_dt:set_visible(false)
			scar_safepoint_hs:set_visible(false)
			scar_headscale_hs:set_visible(false)
			scar_bodyscale_hs:set_visible(false)
			scar_hitchance_hs:set_visible(false)
			scar_safepoint_noscope_dt:set_visible(false)
			scar_headscale_noscope_dt:set_visible(false)
			scar_bodyscale_noscope_dt:set_visible(false)
			scar_hitchance_noscope_dt:set_visible(false)
			scar_safepoint_dt:set_visible(false)
			scar_headscale_dt:set_visible(false)
			scar_bodyscale_dt:set_visible(false)
			scar_hitchance_dt:set_visible(false)

			scout_enable:set_visible(false)
			scout_hitscan_hs:set_visible(false)
			scout_hitscan_noscope_dt:set_visible(false)
			scout_hitscan_dt:set_visible(false)
			scout_safepoint_hs:set_visible(false)
			scout_headscale_hs:set_visible(false)
			scout_bodyscale_hs:set_visible(false)
			scout_hitchance_hs:set_visible(false)
			scout_safepoint_noscope_dt:set_visible(false)
			scout_headscale_noscope_dt:set_visible(false)
			scout_bodyscale_noscope_dt:set_visible(false)
			scout_hitchance_noscope_dt:set_visible(false)
			scout_safepoint_dt:set_visible(false)
			scout_headscale_dt:set_visible(false)
			scout_bodyscale_dt:set_visible(false)
			scout_hitchance_dt:set_visible(false)

			pistols_enable:set_visible(false)
			pistols_hitscan_hs:set_visible(false)
			pistols_hitscan_dt:set_visible(false)
			pistols_safepoint_hs:set_visible(false)
			pistols_headscale_hs:set_visible(false)
			pistols_bodyscale_hs:set_visible(false)
			pistols_hitchance_hs:set_visible(false)
			pistols_safepoint_dt:set_visible(false)
			pistols_headscale_dt:set_visible(false)
			pistols_bodyscale_dt:set_visible(false)
			pistols_hitchance_dt:set_visible(false)

			deagle_enable:set_visible(true)
			deagle_hitscan_hs:set_visible(true)
			deagle_hitscan_dt:set_visible(true)
			deagle_safepoint_hs:set_visible(true)
			deagle_headscale_hs:set_visible(true)
			deagle_bodyscale_hs:set_visible(true)
			deagle_hitchance_hs:set_visible(true)
			deagle_safepoint_dt:set_visible(true)
			deagle_headscale_dt:set_visible(true)
			deagle_bodyscale_dt:set_visible(true)
			deagle_hitchance_dt:set_visible(true)
		end
	else
		scar_enable:set_visible(false)
		scar_hitscan_hs:set_visible(false)
		scar_hitscan_noscope_dt:set_visible(false)
		scar_hitscan_dt:set_visible(false)
		scar_safepoint_hs:set_visible(false)
		scar_headscale_hs:set_visible(false)
		scar_bodyscale_hs:set_visible(false)
		scar_hitchance_hs:set_visible(false)
		scar_safepoint_noscope_dt:set_visible(false)
		scar_headscale_noscope_dt:set_visible(false)
		scar_bodyscale_noscope_dt:set_visible(false)
		scar_hitchance_noscope_dt:set_visible(false)
		scar_safepoint_dt:set_visible(false)
		scar_headscale_dt:set_visible(false)
		scar_bodyscale_dt:set_visible(false)
		scar_hitchance_dt:set_visible(false)

		scout_enable:set_visible(false)
		scout_hitscan_hs:set_visible(false)
		scout_hitscan_noscope_dt:set_visible(false)
		scout_hitscan_dt:set_visible(false)
		scout_safepoint_hs:set_visible(false)
		scout_headscale_hs:set_visible(false)
		scout_bodyscale_hs:set_visible(false)
		scout_hitchance_hs:set_visible(false)
		scout_safepoint_noscope_dt:set_visible(false)
		scout_headscale_noscope_dt:set_visible(false)
		scout_bodyscale_noscope_dt:set_visible(false)
		scout_hitchance_noscope_dt:set_visible(false)
		scout_safepoint_dt:set_visible(false)
		scout_headscale_dt:set_visible(false)
		scout_bodyscale_dt:set_visible(false)
		scout_hitchance_dt:set_visible(false)

		pistols_enable:set_visible(false)
		pistols_hitscan_hs:set_visible(false)
		pistols_hitscan_dt:set_visible(false)
		pistols_safepoint_hs:set_visible(false)
		pistols_headscale_hs:set_visible(false)
		pistols_bodyscale_hs:set_visible(false)
		pistols_hitchance_hs:set_visible(false)
		pistols_safepoint_dt:set_visible(false)
		pistols_headscale_dt:set_visible(false)
		pistols_bodyscale_dt:set_visible(false)
		pistols_hitchance_dt:set_visible(false)

		deagle_enable:set_visible(false)
		deagle_hitscan_hs:set_visible(false)
		deagle_hitscan_dt:set_visible(false)
		deagle_safepoint_hs:set_visible(false)
		deagle_headscale_hs:set_visible(false)
		deagle_bodyscale_hs:set_visible(false)
		deagle_hitchance_hs:set_visible(false)
		deagle_safepoint_dt:set_visible(false)
		deagle_headscale_dt:set_visible(false)
		deagle_bodyscale_dt:set_visible(false)
		deagle_hitchance_dt:set_visible(false)
	end
end

client.register_callback('paint', weapon_switch)

local function scar_override()
	if scar_enable:get_value() then
		player = entitylist.get_local_player()
		is_scoped = player:get_prop_bool( se.get_netvar( "DT_CSPlayer", "m_bIsScoped" ) )

		if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
			auto_head:set_value(scar_headscale_noscope_dt:get_value())
			auto_body:set_value(scar_bodyscale_noscope_dt:get_value())
			auto_sp:set_value(scar_safepoint_noscope_dt:get_value())
			auto_hitchance:set_value(scar_hitchance_noscope_dt:get_value())
			auto_autoscope:set_value(false)
		elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
			auto_head:set_value(scar_headscale_dt:get_value())
			auto_body:set_value(scar_bodyscale_dt:get_value())
			auto_sp:set_value(scar_safepoint_dt:get_value())
			auto_hitchance:set_value(scar_hitchance_dt:get_value())
			auto_autoscope:set_value(false)
		elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			auto_head:set_value(scar_headscale_hs:get_value())
			auto_body:set_value(scar_bodyscale_hs:get_value())
			auto_sp:set_value(scar_safepoint_hs:get_value())
			auto_hitchance:set_value(scar_hitchance_hs:get_value())
			auto_autoscope:set_value(true)
		elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			auto_head:set_value(scar_headscale_hs:get_value())
			auto_body:set_value(scar_bodyscale_hs:get_value())
			auto_sp:set_value(scar_safepoint_hs:get_value())
			auto_hitchance:set_value(scar_hitchance_hs:get_value())
			auto_autoscope:set_value(true)
		elseif antihit_extra_fakeduck_bind:is_active() then
			auto_head:set_value(scar_headscale_hs:get_value())
			auto_body:set_value(scar_bodyscale_hs:get_value())
			auto_sp:set_value(scar_safepoint_hs:get_value())
			auto_hitchance:set_value(scar_hitchance_hs:get_value())
			auto_autoscope:set_value(true)
		end
	else
		auto_head:set_value(auto_head_backup)
		auto_body:set_value(auto_body_backup)
		auto_sp:set_value(auto_sp_backup)
		auto_hitchance:set_value(auto_hitchance_backup)
		auto_autoscope:set_value(auto_autoscope_backup)
	end
end

local function scar_hitscan()
	if scar_enable:get_value() then
		for i = 0, #hitscan - 1 do
			if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
				auto_hitscan:set_value(i, (scar_hitscan_noscope_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
				auto_hitscan:set_value(i, (scar_hitscan_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
			elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
			elseif antihit_extra_fakeduck_bind:is_active() then
				auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
			end
		end
	else
		for i = 0, #hitscan - 1 do
			auto_hitscan:set_value(i, auto_hitscan_backup[i])
		end
	end
end

client.register_callback('create_move', scar_override)
client.register_callback('create_move', scar_hitscan)


local function scout_override()
	if scout_enable:get_value() then
		player = entitylist.get_local_player()
		is_scoped = player:get_prop_bool( se.get_netvar( "DT_CSPlayer", "m_bIsScoped" ) )

		if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
			scout_head:set_value(scout_headscale_noscope_dt:get_value())
			scout_body:set_value(scout_bodyscale_noscope_dt:get_value())
			scout_sp:set_value(scout_safepoint_noscope_dt:get_value())
			scout_hitchance:set_value(scout_hitchance_noscope_dt:get_value())
			scout_autoscope:set_value(false)
		elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
			scout_head:set_value(scout_headscale_dt:get_value())
			scout_body:set_value(scout_bodyscale_dt:get_value())
			scout_sp:set_value(scout_safepoint_dt:get_value())
			scout_hitchance:set_value(scout_hitchance_dt:get_value())
			scout_autoscope:set_value(false)
		elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			scout_head:set_value(scout_headscale_hs:get_value())
			scout_body:set_value(scout_bodyscale_hs:get_value())
			scout_sp:set_value(scout_safepoint_hs:get_value())
			scout_hitchance:set_value(scout_hitchance_hs:get_value())
			scout_autoscope:set_value(true)
		elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			scout_head:set_value(scout_headscale_hs:get_value())
			scout_body:set_value(scout_bodyscale_hs:get_value())
			scout_sp:set_value(scout_safepoint_hs:get_value())
			scout_hitchance:set_value(scout_hitchance_hs:get_value())
			scout_autoscope:set_value(true)
		elseif antihit_extra_fakeduck_bind:is_active() then
			scout_head:set_value(scout_headscale_hs:get_value())
			scout_body:set_value(scout_bodyscale_hs:get_value())
			scout_sp:set_value(scout_safepoint_hs:get_value())
			scout_hitchance:set_value(scout_hitchance_hs:get_value())
			scout_autoscope:set_value(true)
		end
	else
		scout_head:set_value(scout_head_backup)
		scout_body:set_value(scout_body_backup)
		scout_sp:set_value(scout_sp_backup)
		scout_hitchance:set_value(scout_hitchance_backup)
		scout_autoscope:set_value(scout_autoscope_backup)
	end
end

local function scouthit_hitscan()
	if scout_enable:get_value() then
		for i = 0, #hitscan - 1 do
			if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
				scout_hitscan:set_value(i, (scout_hitscan_noscope_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
				scout_hitscan:set_value(i, (scout_hitscan_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				scout_hitscan:set_value(i, (scout_hitscan_hs):get_value(i))
			elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				scout_hitscan:set_value(i, (scout_hitscan_hs):get_value(i))
			elseif antihit_extra_fakeduck_bind:is_active() then
				scout_hitscan:set_value(i, (scout_hitscan_hs):get_value(i))
			end
		end
	else
		for i = 0, #hitscan - 1 do
			scout_hitscan:set_value(i, scout_hitscan_backup[i])
		end
	end
end

client.register_callback('create_move', scout_override)
client.register_callback('create_move', scouthit_hitscan)



local function pistols_override()
	if pistols_enable:get_value() then
		if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			pistols_head:set_value(pistols_headscale_dt:get_value())
			pistols_body:set_value(pistols_bodyscale_dt:get_value())
			pistols_sp:set_value(pistols_safepoint_dt:get_value())
			pistols_hitchance:set_value(pistols_hitchance_dt:get_value())
		elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			pistols_head:set_value(pistols_headscale_hs:get_value())
			pistols_body:set_value(pistols_bodyscale_hs:get_value())
			pistols_sp:set_value(pistols_safepoint_hs:get_value())
			pistols_hitchance:set_value(pistols_hitchance_hs:get_value())
		elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			pistols_head:set_value(pistols_headscale_hs:get_value())
			pistols_body:set_value(pistols_bodyscale_hs:get_value())
			pistols_sp:set_value(pistols_safepoint_hs:get_value())
			pistols_hitchance:set_value(pistols_hitchance_hs:get_value())
		elseif antihit_extra_fakeduck_bind:is_active() then
			pistols_head:set_value(pistols_headscale_hs:get_value())
			pistols_body:set_value(pistols_bodyscale_hs:get_value())
			pistols_sp:set_value(pistols_safepoint_hs:get_value())
			pistols_hitchance:set_value(pistols_hitchance_hs:get_value())
		end
	else
		pistols_head:set_value(pistols_head_backup)
		pistols_body:set_value(pistols_body_backup)
		pistols_sp:set_value(pistols_sp_backup)
		pistols_hitchance:set_value(pistols_hitchance_backup)
	end
end

local function pistolshit_hitscan()
	if pistols_enable:get_value() then
		for i = 0, #hitscan - 1 do
			if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				pistols_hitscan:set_value(i, (pistols_hitscan_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				pistols_hitscan:set_value(i, (pistols_hitscan_hs):get_value(i))
			elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				pistols_hitscan:set_value(i, (pistols_hitscan_hs):get_value(i))
			elseif antihit_extra_fakeduck_bind:is_active() then
				pistols_hitscan:set_value(i, (pistols_hitscan_hs):get_value(i))
			end
		end
	else
		for i = 0, #hitscan - 1 do
			pistols_hitscan:set_value(i, pistols_hitscan_backup[i])
		end
	end
end

client.register_callback('create_move', pistols_override)
client.register_callback('create_move', pistolshit_hitscan)


local function deagle_override()
	if deagle_enable:get_value() then
		if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			deagle_head:set_value(deagle_headscale_dt:get_value())
			deagle_body:set_value(deagle_bodyscale_dt:get_value())
			deagle_sp:set_value(deagle_safepoint_dt:get_value())
			deagle_hitchance:set_value(deagle_hitchance_dt:get_value())
		elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			deagle_head:set_value(deagle_headscale_hs:get_value())
			deagle_body:set_value(deagle_bodyscale_hs:get_value())
			deagle_sp:set_value(deagle_safepoint_hs:get_value())
			deagle_hitchance:set_value(deagle_hitchance_hs:get_value())
		elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
			deagle_head:set_value(deagle_headscale_hs:get_value())
			deagle_body:set_value(deagle_bodyscale_hs:get_value())
			deagle_sp:set_value(deagle_safepoint_hs:get_value())
			deagle_hitchance:set_value(deagle_hitchance_hs:get_value())
		elseif antihit_extra_fakeduck_bind:is_active() then
			deagle_head:set_value(deagle_headscale_hs:get_value())
			deagle_body:set_value(deagle_bodyscale_hs:get_value())
			deagle_sp:set_value(deagle_safepoint_hs:get_value())
			deagle_hitchance:set_value(deagle_hitchance_hs:get_value())
		end
	else
		deagle_head:set_value(deagle_head_backup)
		deagle_body:set_value(deagle_body_backup)
		deagle_sp:set_value(deagle_sp_backup)
		deagle_hitchance:set_value(deagle_hitchance_backup)
	end
end

local function deaglehit_hitscan()
	if deagle_enable:get_value() then
		for i = 0, #hitscan - 1 do
			if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				deagle_hitscan:set_value(i, (deagle_hitscan_dt):get_value(i))
			elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				deagle_hitscan:set_value(i, (deagle_hitscan_hs):get_value(i))
			elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
				deagle_hitscan:set_value(i, (deagle_hitscan_hs):get_value(i))
			elseif antihit_extra_fakeduck_bind:is_active() then
				deagle_hitscan:set_value(i, (deagle_hitscan_hs):get_value(i))
			end
		end
	else
		for i = 0, #hitscan - 1 do
			deagle_hitscan:set_value(i, deagle_hitscan_backup[i])
		end
	end
end

client.register_callback('create_move', deagle_override)
client.register_callback('create_move', deaglehit_hitscan)




--Visuals

	-- Indicators

	local screen = engine.get_screen_size()

	local indicators_switch = ui.add_check_box("Indicators", "indicators_switch", false)
	local x_slider = ui.add_slider_int('Indicators position x', 'og_indicators_pos_x', 0, screen.x, 10)
	local y_slider = ui.add_slider_int('Indicators position y', 'og_indicators_pos_y', 0, screen.y, 260)

	local fonts = {
		verdana = renderer.setup_font('c:/windows/fonts/verdana.ttf', 12, 0),
		verdana_watermark = renderer.setup_font('c:/windows/fonts/verdana.ttf', 13, 0),
		tohomabd = renderer.setup_font('C:/windows/fonts/tahomabd.ttf', 30, 0)
	}

	local indicators = {}

	local exploit_names = {
		'none',
		'HS',
		'DT'
	}

	local binds = {
		{ name = 'PING',                cfg = ui.get_slider_int('misc_ping_spike_amount'),      type = 'slider_int', disable_val = 0 },
		{ name = 'FD',                  cfg = ui.get_key_bind('antihit_extra_fakeduck_bind'),   type = 'key_bind' },
		{ name = 'AP',                  cfg = lua_re_autopeek,               type = 'key_bind' },
		{ name = 'Only Head',           cfg = lua_re_onlyhead_bind,          type = 'key_bind' },
		{ name = 'BAIM',                cfg = lua_re_baim_bind,              type = 'key_bind' },
		{ name = 'LAIM',                cfg = lua_re_laim_bind,              type = 'key_bind' },
		{ name = 'SP',    			 	cfg = lua_re_safepoints_bind,        type = 'key_bind' },
		{ name = 'Lethal',              cfg = lua_re_lethal_bind,            type = 'key_bind' },
		{ name = 'Resolver Override',   cfg = lua_re_resolver_override_bind, type = 'key_bind' },
		{ name = exploit_names,         cfg = ui.get_key_bind('rage_active_exploit_bind'),      type = 'key_bind' },
		{ name = 'Weapon ->',           type = 'static' },
		{ name = 'DMG  ->',             type = 'static' },
		{ name = 'FL',                  type = 'static' },
	}

	-- get the weapon
	ffi.cdef[[

		struct WeaponInfo_t
		{
			char _0x0000[20];
			__int32 max_clip;   
			char _0x0018[12];
			__int32 max_reserved_ammo;
			char _0x0028[96];
			char* hud_name;           
			char* weapon_name;       
			char _0x0090[60];
			__int32 type;           
			__int32 price;           
			__int32 reward;           
			char _0x00D8[20];
			bool full_auto;       
			char _0x00ED[3];
			__int32 damage;           
			float armor_ratio;         
			__int32 bullets;   
			float penetration;   
			char _0x0100[8];
			float range;           
			float range_modifier;   
			char _0x0110[16];
			bool silencer;           
			char _0x0121[15];
			float max_speed;       
			float max_speed_alt;
			char _0x0138[76];
			__int32 recoil_seed;
			char _0x0188[32];
		};
	]]

	local weapon_info_pattern = ffi.cast("int*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04"))
	local m_hActiveWeapon = se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")

	function utils_get_weapon_info(weapon)
		return ffi.cast("struct WeaponInfo_t*", weapon_info_pattern(ffi.cast("void*", weapon:get_address())))
	end

	local function get_current_weapon()
		if not entitylist.get_local_player() or not entitylist.get_local_player():is_alive() then return end

		local current_weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(m_hActiveWeapon))
		local current_weapon_name = ffi.string(utils_get_weapon_info(current_weapon).weapon_name)
		
		return current_weapon_name
	end

	--Some accidents
	local function is_deagle()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 262145 then return false end
		return true
	end

	local function is_revolver()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 262208 then return false end
		return true
	end

	local function is_USP_SILENCER()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 262205 then return false end
		return true
	end

	local function is_P2000()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 32 then return false end
		return true
	end

	local function is_CZ75A()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 262207 then return false end
		return true
	end

	local function is_P250()
		local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
		local active_weapon = entitylist.get_entity_from_handle(handle)
		if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= 36 then return false end
		return true
	end

	local Weapon_value = ''
	local lua_re_defdmg_value = 0
	local lua_re_mindmg_value = 0

	local function show_current_weapon()
		if get_current_weapon() == nil then
			Weapon_value = 'None'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif is_deagle() then
			Weapon_value = 'Deagle'
			lua_re_defdmg_value = ui.get_slider_int("rage_deagle_min_damage"):get_value()
			lua_re_mindmg_value = deagle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_elite' then
			Weapon_value = 'Duals'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_fiveseven' then
			Weapon_value = 'Fiveseven'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_glock' then
			Weapon_value = 'Glock'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_ak47' then
			Weapon_value = 'AK47'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_aug' then
			Weapon_value = 'AUG'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_awp' then
			Weapon_value = 'AWP'
			lua_re_defdmg_value = ui.get_slider_int("rage_awp_min_damage"):get_value()
			lua_re_mindmg_value = awp_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_famas' then
			Weapon_value = 'Famas'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_g3sg1' then
			Weapon_value = 'G3SG1'
			lua_re_defdmg_value = ui.get_slider_int("rage_auto_min_damage"):get_value()
			lua_re_mindmg_value = auto_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_galilar' then
			Weapon_value = 'GalilAR'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_m249' then
			Weapon_value = 'M249'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_m4a1' then
			Weapon_value = 'M4A1-S'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_mac10' then
			Weapon_value = 'MAC10'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_p90' then
			Weapon_value = 'P90'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_mp5sd' then
			Weapon_value = 'MP5SD'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_ump45' then
			Weapon_value = 'UMP-45'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_xm1014' then
			Weapon_value = 'XM1014'
			lua_re_defdmg_value = ui.get_slider_int("rage_shotguns_min_damage"):get_value()
			lua_re_mindmg_value = shotguns_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_bizon' then
			Weapon_value = 'Bizon'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_mag7' then
			Weapon_value = 'MAG-7'
			lua_re_defdmg_value = ui.get_slider_int("rage_shotguns_min_damage"):get_value()
			lua_re_mindmg_value = shotguns_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_negev' then
			Weapon_value = 'Negev'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_sawedoff' then
			Weapon_value = 'Sawedoff'
			lua_re_defdmg_value = ui.get_slider_int("rage_shotguns_min_damage"):get_value()
			lua_re_mindmg_value = shotguns_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_tec9' then
			Weapon_value = 'Tec-9'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_taser' then
			Weapon_value = 'Taser'
			lua_re_defdmg_value = ui.get_slider_int("rage_taser_min_damage"):get_value()
			lua_re_mindmg_value = taser_mindmg:get_value()
		elseif is_P2000() then
			Weapon_value = 'P2000'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_mp7' then
			Weapon_value = 'MP7'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_mp9' then
			Weapon_value = 'MP9'
			lua_re_defdmg_value = ui.get_slider_int("rage_smg_min_damage"):get_value()
			lua_re_mindmg_value = smg_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_nova' then
			Weapon_value = 'Nova'
			lua_re_defdmg_value = ui.get_slider_int("rage_shotguns_min_damage"):get_value()
			lua_re_mindmg_value = shotguns_mindmg:get_value()
		elseif is_P250() then
			Weapon_value = 'P250'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_scar20' then
			Weapon_value = 'SCAR-20'
			lua_re_defdmg_value = ui.get_slider_int("rage_auto_min_damage"):get_value()
			lua_re_mindmg_value = auto_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_sg556' then
			Weapon_value = 'SG 553'
			lua_re_defdmg_value = ui.get_slider_int("rage_rifle_min_damage"):get_value()
			lua_re_mindmg_value = rifle_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_ssg08' then
			Weapon_value = 'SSG 08'
			lua_re_defdmg_value = ui.get_slider_int("rage_scout_min_damage"):get_value()
			lua_re_mindmg_value = scout_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_flashbang' then
			Weapon_value = 'Flashbang'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_hegrenade' then
			Weapon_value = 'HE Grenade'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_smokegrenade' then
			Weapon_value = 'Smoke Grenade'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_molotov' then
			Weapon_value = 'Molotov'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_decoy' then
			Weapon_value = 'Decoy'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_incgrenade' then
			Weapon_value = 'Inc Grenade'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_c4' then
			Weapon_value = 'C4'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif get_current_weapon() == 'weapon_healthshot' then
			Weapon_value = 'Healthshot'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		elseif is_USP_SILENCER() then
			Weapon_value = 'USP-S'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif is_CZ75A() then
			Weapon_value = 'CZ75'
			lua_re_defdmg_value = ui.get_slider_int("rage_pistols_min_damage"):get_value()
			lua_re_mindmg_value = pistols_mindmg:get_value()
		elseif is_revolver() then
			Weapon_value = 'Revolver'
			lua_re_defdmg_value = ui.get_slider_int("rage_revolver_min_damage"):get_value()
			lua_re_mindmg_value = revolver_mindmg:get_value()
		elseif get_current_weapon() == 'weapon_knife' or get_current_weapon() == 'weapon_knife_t' or get_current_weapon() == 'weapon_knifegg'then
			Weapon_value = 'Knife'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		else
			Weapon_value = 'Other'
			lua_re_defdmg_value = 0
			lua_re_mindmg_value = 0
		end
	end

	local function add_indicator(indicator)
		table.insert(indicators, indicator)
	end

	local function render_text(text, x, y, color)
		renderer.text(tostring(text), fonts.tohomabd, vec2_t.new(x, y + 1), 30, color_t.new(0, 0, 0, 255))
		renderer.text(tostring(text), fonts.tohomabd, vec2_t.new(x, y), 30, color)
	end

	local function render_filled_rect(x, y, w, h, color)
		renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x+w, y+h), color)
	end

	local function render_arc(x, y, radius, radius_inner, start_angle, end_angle, segments, color)
        local segments = 360 / segments;
        for i = start_angle,start_angle + end_angle,segments / 2 do
            local rad = -i * math.pi / 180;
            local rad2 = -(i + segments) * math.pi / 180;
            local rad_cos = math.cos(rad);
            local rad_sin = math.sin(rad);
            local rad2_cos = math.cos(rad2);
            local rad2_sin = math.sin(rad2);
            local x1_inner = x + rad_cos * radius_inner;
            local y1_inner = y + rad_sin * radius_inner;
            local x1_outer = x + rad_cos * radius;
            local y1_outer = y + rad_sin * radius;
            local x2_inner = x + rad2_cos * radius_inner;
            local y2_inner = y + rad2_sin * radius_inner;
            local x2_outer = x + rad2_cos * radius;
            local y2_outer = y + rad2_sin * radius;
			
            renderer.filled_polygon({ vec2_t.new(x1_outer, y1_outer),vec2_t.new(x2_outer, y2_outer),vec2_t.new(x1_inner, y1_inner) },color)
            renderer.filled_polygon({ vec2_t.new(x1_inner, y1_inner),vec2_t.new(x2_outer, y2_outer),vec2_t.new(x2_inner, y2_inner) },color)
    	end
	end

	local function draw_indicators()
		local x = x_slider:get_value()
		local h = screen.y - 50 - y_slider:get_value()

		local y = 30 * #indicators

		for key, value in pairs(indicators) do
			local addition = 6

			local sizes = renderer.get_text_size(fonts.tohomabd, 30, value.text)

			render_text(value.text, x, h - y, value.color)

			addition = addition + sizes.y

			if value.Weapon then
				local Weapon = value.Weapon
				render_text(Weapon.value, x + 150, h - y, Weapon.color)
			end
			
			if value.CHOKE then
				local CHOKE = value.CHOKE
				renderer.text(string.format('%i-%i-%i-%i-%i',CHOKE.choked5,CHOKE.choked4,CHOKE.choked3,CHOKE.choked2,CHOKE.choked1), fonts.tohomabd, vec2_t.new(x, h - y + addition + 6), 30, color_t.new(0, 0, 0, 255))
				renderer.text(string.format('%i-%i-%i-%i-%i',CHOKE.choked5,CHOKE.choked4,CHOKE.choked3,CHOKE.choked2,CHOKE.choked1), fonts.tohomabd, vec2_t.new(x, h - y + addition + 5), 30, CHOKE.color)
			end

			if value.bar then
				local bar = value.bar
				local fill = (sizes.x - 2) / (bar.max - bar.min) * (bar.value - bar.min)
			
				render_arc(x + 58, h - y + addition - 20, 12, 8, 0, 360, 50, color_t.new(0, 0, 0, 150))
				render_arc(x + 58, h - y + addition - 20, 11.5, 8, 90, fill * 13, 50, bar.color)
			end

			if value.DMG then
				local DMG = value.DMG

				if lua_re_mindmg_bind:is_active() and not lua_re_dmgoverride_bind:is_active() then
					render_text(DMG.Value2, x + 118, h - y, DMG.color1)
					render_text('(MinDmg)', x + 156, h - y, DMG.color2)
				elseif lua_re_dmgoverride_bind:is_active() then
					render_text(DMG.Value3, x + 118, h - y, DMG.color1)
					render_text('(Override)', x + 156, h - y, DMG.color3)
				else
					render_text(DMG.Value1, x + 118, h - y, DMG.color1)
					render_text('(Default)', x + 156, h - y, DMG.color1)
				end
			end

			y = y - addition
		end
	end

	local function to_percent(a, b)
		return a * 100 / b
	end

	local function p2c(per, alpha)
		local red = per < 50 and 255 or math.floor(255 - (per * 2 - 100) * 255 / 100);
		local green = per > 50 and 255 or math.floor((per * 2) * 255 / 100);

		return color_t.new(red, green, 13, alpha or 255);
	end

	local chocked_fl = clientstate.get_choked_commands()
	local First_CK = chocked_fl
	local choked_1,choked_2,choked_3,choked_4,choked_5 = 0,0,0,0,0
	local choked_1_backup = {0, 0, 0, 0, 0}
	local choked_2_backup = {0, 0, 0, 0, 0}
	local choked_3_backup = {0, 0, 0, 0, 0}
	local choked_4_backup = {0, 0, 0, 0, 0}
	local choked_5_backup = {0, 0, 0, 0, 0}

	local time_start = math.floor(globalvars.get_tick_count())

	local function fakelag_chock()
		local function get_fakelag_bysec()
			for i = 1, 64 do
				chocked_fl = clientstate.get_choked_commands()

				local time_current = math.floor(globalvars.get_tick_count())
				local time = time_current - time_start

				if time > 320 then
					time_start = time_current - 1
				end

				if chocked_fl <= First_CK then
					if time == 320 then
						choked_5_backup[1] = choked_4_backup[1]
						choked_4_backup[2] = choked_3_backup[2]
						choked_3_backup[3] = choked_2_backup[3]
						choked_2_backup[4] = choked_1_backup[4]
						choked_1_backup[5] = First_CK

						choked_1 = choked_1_backup[5]
						choked_2 = choked_2_backup[4]
						choked_3 = choked_3_backup[3]
						choked_4 = choked_4_backup[2]
						choked_5 = choked_5_backup[1]
					end
					if time == 256 then
						choked_5_backup[5] = choked_4_backup[5]
						choked_4_backup[1] = choked_3_backup[1]
						choked_3_backup[2] = choked_2_backup[2]
						choked_2_backup[3] = choked_1_backup[3]
						choked_1_backup[4] = First_CK

						choked_1 = choked_1_backup[4]
						choked_2 = choked_2_backup[3]
						choked_3 = choked_3_backup[2]
						choked_4 = choked_4_backup[1]
						choked_5 = choked_5_backup[5]
					end
					if time == 192 then
						choked_5_backup[4] = choked_4_backup[4]
						choked_4_backup[5] = choked_3_backup[5]
						choked_3_backup[1] = choked_2_backup[1]
						choked_2_backup[2] = choked_1_backup[2]
						choked_1_backup[3] = First_CK

						choked_1 = choked_1_backup[3]
						choked_2 = choked_2_backup[2]
						choked_3 = choked_3_backup[1]
						choked_4 = choked_4_backup[5]
						choked_5 = choked_5_backup[4]
					end
					if time == 128 then
						choked_5_backup[3] = choked_4_backup[3]
						choked_4_backup[4] = choked_3_backup[4]
						choked_3_backup[5] = choked_2_backup[5]
						choked_2_backup[1] = choked_1_backup[1]
						choked_1_backup[2] = First_CK

						choked_1 = choked_1_backup[2]
						choked_2 = choked_2_backup[1]
						choked_3 = choked_3_backup[5]
						choked_4 = choked_4_backup[4]
						choked_5 = choked_5_backup[3]
					end
					if time == 64 then
						choked_5_backup[2] = choked_4_backup[2]
						choked_4_backup[3] = choked_3_backup[3]
						choked_3_backup[4] = choked_2_backup[4]
						choked_2_backup[5] = choked_1_backup[5]
						choked_1_backup[1] = First_CK

						choked_1 = choked_1_backup[1]
						choked_2 = choked_2_backup[5]
						choked_3 = choked_3_backup[4]
						choked_4 = choked_4_backup[3]
						choked_5 = choked_5_backup[2]
					end
				end
				
				First_CK = chocked_fl
			end
		end

		local player = entitylist.get_local_player()
		if engine.is_in_game() and player:is_alive() then
			get_fakelag_bysec()
		end
	end

	local antihit_fakelag_limit = ui.get_slider_int('antihit_fakelag_limit')
	local rage_active_exploit = ui.get_combo_box('rage_active_exploit')
	local antihit_extra_fakeduck_bind = ui.get_key_bind('antihit_extra_fakeduck_bind')

	local function on_paint_indicators()
		if not engine.is_in_game() then return end

		-- Indicators
		if indicators_switch:get_value() then
			local chocked = clientstate.get_choked_commands()
			local limit = antihit_fakelag_limit:get_value()
			local player = entitylist.get_local_player()
			local e = rage_active_exploit:get_value()

			indicators = {}

			if not player or not player:is_alive() then return end

			for i = 1, #binds do
				local bind = binds[i]

				local name = bind.name
					
				if type(name) == 'table' then
					name = name[e + 1]
				end

				local information = {}
			
				if bind.type == 'static' then
					if name == 'FL' then
						information = {
							text = name,
							color = color_t.new(30, 144, 255, 255),
							bar = {
								color = p2c(to_percent(chocked, limit)),
								max = limit,
								min = 0,
								value = chocked
							},
							CHOKE = {
								color = color_t.new(30, 144, 255, 255),
								choked1 = choked_1,
								choked2 = choked_2,
								choked3 = choked_3,
								choked4 = choked_4,
								choked5 = choked_5
							}
						}
					end
					
					if name == 'Weapon ->' then
						information = {
							text = name,
							color = color_t.new(30, 144, 255, 255),
							Weapon = {
								color = color_t.new(30, 144, 255, 255),
								value = Weapon_value
							}
						}
					end

					if name == 'DMG  ->' then
						local lua_re_dmgoverride_value = lua_re_dmgoverride:get_value()

						information = {
							text = name,
							color = color_t.new(30, 144, 255, 255),
							DMG = {
								color1 = color_t.new(30, 144, 255, 255),
								color2 = color_t.new(0, 255, 0, 255),
								color3 = color_t.new(230, 0, 0, 255),
								Value1 = lua_re_defdmg_value,
								Value2 = lua_re_mindmg_value,
								Value3 = lua_re_dmgoverride_value
							}
						}
					end

					

				elseif bind.type == 'slider_int' then
					if bind.cfg:get_value() > bind.disable_val then
						information = {
							text = name,
							color = color_t.new(255, 170, 0, 255)
						}
					end
				elseif bind.type == 'key_bind' then
					if bind.cfg:is_active() and name ~= 'none' then
						information = {
							text = name,
							color = color_t.new(0, 255, 0, 255)
						}

						if name == 'DT' then
							local active_weapon = player:get_prop_int(m_hActiveWeapon)
							local weapon = entitylist.get_entity_from_handle(active_weapon)

							local recharge = math.floor(GetExploitCharge(player, weapon, e) * 100)

							if not antihit_extra_fakeduck_bind:is_active() then
								local value = clamp(40 - recharge, 0, 40)

								information.bar = {
									color = p2c(to_percent(value, 40)),
									max = 40,
									min = 0,
									value = value
								}
							else
								information.color = color_t.new(255, 0, 0, 255)
							end
						end
					end
				end

				if information.text then
					add_indicator(information)
				end
			end

			draw_indicators()
		end
	end


	-- Hitlist
	local screensize = engine.get_screen_size()

	local hitlist_switch = ui.add_check_box("Hitlist", "hitlist_switch", false)
	local color_hitlist = ui.add_color_edit("line color", "color_hitlist", true, color_t.new(0, 255, 255, 255))
	local style = ui.add_combo_box("hitlist style", "style", {"super minimal", "informative"}, 0)
	local hitlog_clear = ui.add_check_box("Hitlist clear table", "hitlog_clear", false)
	local hitlog_pos_x = ui.add_slider_int("Hitlist position x", "hitlog_pos_x", 0, screensize.x, 0)
	local hitlog_pos_y = ui.add_slider_int("Hitlist position y", "hitlog_pos_y", 0, screensize.y, 0)

	local utils = {
		to_rgba = function (params)
			return params[1], params[2], params[3], params[4]
		end,
	}

	local gui = {
		rect_filled = function(x, y, w, h, color)
			renderer.rect_filled(vec2_t.new(x,y), vec2_t.new(x+w,y+h), color_t.new(utils.to_rgba(color)))
		end,

		draw_text = function (x, y, text)
			renderer.text(tostring(text), fonts.verdana, vec2_t.new(x,y), 12, color_t.new(255, 255, 255, 255))
		end
	}

	local id = 0
	local hitlog = {}

	local function clear()
		id = 0
		hitlog = {}
	end

	local function get_damage_color(damage)
		if damage > 90 then
			return { 255, 0, 0, 255 }
		elseif damage > 70 then
			return { 255, 89, 0, 255 }
		elseif damage > 40 then
			return { 255, 191, 0, 255 }
		elseif damage > 1 then
			return { 9, 255, 0, 255 }
		else
			return { 0, 140, 255, 255 }
		end
	end

	local function get_size()
		if #hitlog > 8 then
			return 8
		end

		return #hitlog
	end

	local WINDOW_WIDTH = 210

	local function get_hitgroup(index)
	
		if index == 1 then
			return "head"
		elseif index == 6 or index == 7 then
			return "leg"
		elseif index == 4 or index == 5 then
			return "arm"
		end
	
		return "body"
	end

	local function on_paint_hitlist()
		if not engine.is_in_game() then return end

		-- Hitlist
		if hitlist_switch:get_value() then
			if hitlog_clear:get_value() or not engine.is_in_game() then
				clear()
				hitlog_clear:set_value(false)
			end

			local pos_x = hitlog_pos_x:get_value()
			local pos_y = hitlog_pos_y:get_value()

			local size = 18 + 18 * get_size()


			gui.rect_filled(pos_x, pos_y, WINDOW_WIDTH, size, { 22, 20, 26, 100 })
			gui.rect_filled(pos_x, pos_y, WINDOW_WIDTH, 18, { 22, 20, 26, 170 })
			renderer.line(vec2_t.new(pos_x,pos_y), vec2_t.new(pos_x+WINDOW_WIDTH,pos_y), color_hitlist:get_value())


			local text_pos = pos_x + 7
			if style:get_value() == 0 then
				gui.draw_text(text_pos, pos_y + 3, "player")
				text_pos = text_pos + 80
				gui.draw_text(text_pos, pos_y + 3, "result")
				WINDOW_WIDTH = 210
			elseif style:get_value() == 1 then 
				gui.draw_text(text_pos, pos_y + 3, "id")
				text_pos = text_pos + 20
			
				gui.draw_text(text_pos, pos_y + 3, "player")
				text_pos = text_pos + 73
			
				gui.draw_text(text_pos, pos_y + 3, "damage")
				text_pos = text_pos + 50
			
				gui.draw_text(text_pos, pos_y + 3, "hitbox")
				text_pos = text_pos + 78
			
				gui.draw_text(text_pos, pos_y + 3, "hit.c")
				text_pos = text_pos + 35  
			
				gui.draw_text(text_pos, pos_y + 3, "left")
				text_pos = text_pos + 30
			
				gui.draw_text(text_pos, pos_y + 3, "result")
				text_pos = text_pos + 48
			
				gui.draw_text(text_pos, pos_y + 3, "bt")
				text_pos = text_pos + 20
				WINDOW_WIDTH = 358
			end

			for i = 1, get_size(), 1 do
				local data = hitlog[i]

				if data then
					local pitch = pos_x + 10
					local yaw = pos_y + 18 + (i - 1) * 18 + 1

					if style:get_value() == 0 then

						gui.rect_filled(pos_x, yaw - 1, 2, 17, get_damage_color(data.server_damage))

						text_pos = pitch - 3

						gui.draw_text(text_pos, yaw, data.player)
						text_pos = text_pos + 80

						
						if data.server_damage > 0 then
							gui.draw_text(text_pos, yaw, "-" .. data.server_damage)
						else
							gui.draw_text(text_pos, yaw, data.result .. " in " .. data.client_hitbox .. " (-" .. data.client_damage .. ")")
						end
					
					elseif style:get_value() == 1 then
						gui.rect_filled(pos_x, yaw - 1, 2, 17, get_damage_color(data.server_damage))
		
						text_pos = pitch - 3
						gui.draw_text(text_pos, yaw, data.id)
						text_pos = text_pos + 20
			
						gui.draw_text(text_pos, yaw, data.player)
						text_pos = text_pos + 73
			
						gui.draw_text(text_pos, yaw, tostring(data.server_damage) .. (data.server_damage == data.client_damage and "" or "(" .. tostring(data.client_damage) .. ")"))
						text_pos = text_pos + 50
					
						gui.draw_text(text_pos, yaw, tostring(data.client_hitbox) .. (data.client_hitbox == data.server_hit and "" or "(" .. tostring(data.server_hit) .. ")"))
						text_pos = text_pos + 78
			
						gui.draw_text(text_pos, yaw, data.hitchance .. "%")
						text_pos = text_pos + 35
			
						gui.draw_text(text_pos, yaw, data.HPrem)
						text_pos = text_pos + 30
			
						gui.draw_text(text_pos, yaw, data.result)
						text_pos = text_pos + 48
					
						gui.draw_text(text_pos, yaw, data.backtrack)
						text_pos = text_pos + 20
					end

				end 
			end
		end
	end

	local function hitlist(shot)
		if shot.manual then
			return
		end    
	
		local client_hitbox = hitboxes_hit[shot.hitbox + 1]
		local server_hit = shot.server_damage > 0 and get_hitgroup(shot.server_hitgroup) or "-"
	
		for i = 8, 2, -1 do
			hitlog[i] = hitlog[i-1]
		end
	
		id = id + 1
	
		hitlog[1] = {
			["id"] = id,
			["player"] = string.sub(engine.get_player_info(shot.target:get_prop_int(0x64)).name, 0, 14),
			["client_damage"] = shot.client_damage,
			["server_damage"] = shot.server_damage,
			["HPrem"] = shot.target:get_prop_int(m_iHealth),
			["client_hitbox"] = client_hitbox,
			["server_hit"] = server_hit,
			["hitchance"] = shot.hitchance,
			["safepoint"] = shot.safe_point,
			["result"] = shot.result,
			["backtrack"] = shot.backtrack,
		}
	end

	--Keybinds & Watermark with Fake Angle
	--Nixware watermark
	local lua_re_watermark_enabled = ui.add_check_box("Enable Watermark", "lua_re_watermark_enabled", false)

	local pos, pos2 = vec2_t.new(screen.x - 325, 5), vec2_t.new(screen.x - 5, 30)
	local pos3, pos4 = vec2_t.new(screen.x - 125, 40), vec2_t.new(screen.x - 5, 65)
	
	local function get_fps()
		frametime = globalvars.get_frame_time()
		local fps = math.floor(1000 / (frametime * 1000))
		if fps < 10 then fps = "   " .. tostring(fps)
		elseif fps < 100 then fps = "  " .. tostring(fps) end
		return fps
	end

	local function get_time()
		local hours, minutes, seconds = client.get_system_time()
		if hours < 10 then hours = "0" .. tostring(hours) end
		if minutes < 10 then minutes = "0" .. tostring(minutes) end
		if seconds < 10 then seconds = "0" .. tostring(seconds) end
		return hours .. ":" .. minutes .. ":" .. seconds
	end

	local function get_ping()
		local ping = math.floor(se.get_latency())
		if ping < 10 then ping = " " .. tostring(ping) end
		return ping
	end

	--[[
	local function get_username()
		local username = client.get_username()
		return username
	end
	this fucking robs, but I removed it because of the unknown size of your nickname
	 ]]--

	local function get_tickr()
		local tickr = 1.0 / globalvars.get_interval_per_tick()
		return tickr
	end

	--Fake Angle
	local function lua_re_fake_angle()
		ffi.cdef[[

			struct Animstate_t
			{
				char pad[ 3 ];
				char m_bForceWeaponUpdate; //0x4
				char pad1[ 91 ];
				void* m_pBaseEntity; //0x60
				void* m_pActiveWeapon; //0x64
				void* m_pLastActiveWeapon; //0x68
				float m_flLastClientSideAnimationUpdateTime; //0x6C
				int m_iLastClientSideAnimationUpdateFramecount; //0x70
				float m_flAnimUpdateDelta; //0x74
				float m_flEyeYaw; //0x78
				float m_flPitch; //0x7C
				float m_flGoalFeetYaw; //0x80
				float m_flCurrentFeetYaw; //0x84
				float m_flCurrentTorsoYaw; //0x88
				float m_flUnknownVelocityLean; //0x8C
				float m_flLeanAmount; //0x90
				char pad2[ 4 ];
				float m_flFeetCycle; //0x98
				float m_flFeetYawRate; //0x9C
				char pad3[ 4 ];
				float m_fDuckAmount; //0xA4
				float m_fLandingDuckAdditiveSomething; //0xA8
				char pad4[ 4 ];
				float m_vOriginX; //0xB0
				float m_vOriginY; //0xB4
				float m_vOriginZ; //0xB8
				float m_vLastOriginX; //0xBC
				float m_vLastOriginY; //0xC0
				float m_vLastOriginZ; //0xC4
				float m_vVelocityX; //0xC8
				float m_vVelocityY; //0xCC
				char pad5[ 4 ];
				float m_flUnknownFloat1; //0xD4
				char pad6[ 8 ];
				float m_flUnknownFloat2; //0xE0
				float m_flUnknownFloat3; //0xE4
				float m_flUnknown; //0xE8
				float m_flSpeed2D; //0xEC
				float m_flUpVelocity; //0xF0
				float m_flSpeedNormalized; //0xF4
				float m_flFeetSpeedForwardsOrSideWays; //0xF8
				float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
				float m_flTimeSinceStartedMoving; //0x100
				float m_flTimeSinceStoppedMoving; //0x104
				bool m_bOnGround; //0x108
				bool m_bInHitGroundAnimation; //0x109
				float m_flTimeSinceInAir; //0x10A
				float m_flLastOriginZ; //0x10E
				float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
				float m_flStopToFullRunningFraction; //0x116
				char pad7[ 4 ]; //0x11A
				float m_flMagicFraction; //0x11E
				char pad8[ 60 ]; //0x122
				float m_flWorldForce; //0x15E
				char pad9[ 462 ]; //0x162
				float m_flMaxYaw; //0x334
			};
		]]


		function UTILS_GetAnimState()

			return ffi.cast("struct Animstate_t**", entitylist.get_local_player():get_address() + 0x3914)[0]
		end


		function ANTIAIM_GetMaxDesyncDelta(entity)
			
			local animstate = UTILS_GetAnimState()

			if (not animstate) then

				return 0
			end
			
			local flRunningSpeed = math.max(0, math.min(animstate.m_flFeetSpeedForwardsOrSideWays))
			local flYawModifier = (((animstate.m_flStopToFullRunningFraction * -0.3) - 0.2) * flRunningSpeed) + 1.0

			if (animstate.m_fDuckAmount > 0) then
				
				local speedfactor = math.max(0, math.min(1, animstate.m_flFeetSpeedUnknownForwardOrSideways))
				flYawModifier = flYawModifier + ((animstate.m_fDuckAmount * speedfactor) * (0.5 - flYawModifier))
			end
			
			return ffi.cast("float*", ffi.cast("int*", entity:get_address() + 0x3914)[0] + 0x334)[0] * flYawModifier
		end
	end

	local function watermark()
		renderer.filled_polygon({ vec2_t.new(screen.x - 360, 6), vec2_t.new(screen.x - 325, 30), vec2_t.new(screen.x - 325, 6) }, color_t.new(30,30,30,255)) --0 25 25
		local inner_pos1, inner_pos2 = vec2_t.new(screen.x - 300, 15), vec2_t.new(screen.x - 100, 65)
		renderer.rect_filled(pos, pos2, color_t.new(30,30,30,255))
			
		--renderer.rect(pos, pos2, color_t.new(15,15,15,255)) --drawing shit frame
		--renderer.rect_filled(inner_pos1, inner_pos2, color_t.new(20,20,20,255))
		--renderer.rect(inner_pos1, inner_pos2, color_t.new(15,15,15,255))
		
		local fpos1, fpos2 = vec2_t.new(screen.x - 360, 3), vec2_t.new(screen.x - 5, 6) -- drawing a different line
		renderer.rect_filled_fade(fpos1, fpos2, color_t.new(243, 0, 255, 255), color_t.new(255, 243, 77, 255), color_t.new(255, 243, 77, 255), color_t.new(243, 0, 255, 255))
				
		--local npos, nposs = vec2_t.new(screen.x - 160, 17), vec2_t.new(screen.x - 159, 18) --drawing the cheat tag
		--renderer.text("NIXWARE", fonts.verdana_watermark, nposs, 13, color_t.new(0, 0, 0, 255))
		--renderer.text("NIXWARE", fonts.verdana_watermark, npos, 13, color_t.new(255, 255, 255, 255))
		
		local fpos_1 = vec2_t.new(screen.x - 325, 10) -- cord drawing text
		renderer.text("nixware.cc | " .. get_tickr() .. " tick | " .. get_time() ..  " | PING: " .. get_ping() .. " | FPS:" .. get_fps(), fonts.verdana_watermark, fpos_1, 13, color_t.new(255, 255, 255, 255))
		
		if engine.is_in_game() then
			renderer.filled_polygon({ vec2_t.new(screen.x - 160, 41), vec2_t.new(screen.x - 125, 65), vec2_t.new(screen.x - 125, 41) }, color_t.new(30,30,30,255))
			renderer.rect_filled(pos3, pos4, color_t.new(30,30,30,255))

			local fpos3, fpos4 = vec2_t.new(screen.x - 160, 38), vec2_t.new(screen.x - 5, 41)
			renderer.rect_filled_fade(fpos3, fpos4, color_t.new(243, 0, 255, 255), color_t.new(255, 243, 77, 255), color_t.new(255, 243, 77, 255), color_t.new(243, 0, 255, 255))

			local fpos_2 = vec2_t.new(screen.x - 125, 45)
			local fake_angle_value = math.ceil(ANTIAIM_GetMaxDesyncDelta(entitylist.get_local_player()))
			if ANTIAIM_GetMaxDesyncDelta(entitylist.get_local_player()) < 0 then
				fake_angle_value = 0
			end
			
			local fpos_3 = vec2_t.new(screen.x - 64, 45)
			local fakelag_value = clientstate.get_choked_commands()
			renderer.text("Fake: " .. tostring(fake_angle_value) .. "°", fonts.verdana_watermark, fpos_2, 13, color_t.new(255, 255, 255, 255))
			renderer.text("| FL: " .. fakelag_value, fonts.verdana_watermark, fpos_3, 13, color_t.new(255, 255, 255, 255))
		end
	end

	
	local screen_ind = ui.add_multi_combo_box("Screen indicators", "screen_ind", { "Keybinds", "Watermark" }, { false, false })
	local animation_type = ui.add_combo_box("Animation type", "animation_type", { "Skeet", "Neverlose" }, 0)
	local auto_resize_width = ui.add_check_box("Auto resize width", "auto_resize_width", false)
	local style_line = ui.add_combo_box("Style line", "style_line", { "Static", "Fade", "Reverse fade", "Gradient", "Skeet", "Chroma" }, 0)
	local chroma_dir = ui.add_combo_box("Chroma direction", "chroma_dir", { "Left", "Right", "Static" }, 0)
	local color_line = ui.add_color_edit("Color line", "color_line", true, color_t.new(0, 255, 255, 255))
	local lua_re_keybinds_x = ui.add_slider_int("keybind_x", "lua_re_keybinds_x", 0, engine.get_screen_size().x, 345)
	local lua_re_keybinds_y = ui.add_slider_int("keybind_y", "lua_re_keybinds_y", 0, engine.get_screen_size().y, 215)

	local types = { "always", "hold", "toggle", "disabled" }

	local function hsv2rgb(h, s, v, a)
		local r, g, b

		local i = math.floor(h * 6);
		local f = h * 6 - i;
		local p = v * (1 - s);
		local q = v * (1 - f * s);
		local t = v * (1 - (1 - f) * s);

		i = i % 6

		if i == 0 then r, g, b = v, t, p
		elseif i == 1 then r, g, b = q, v, p
		elseif i == 2 then r, g, b = p, v, t
		elseif i == 3 then r, g, b = p, q, v
		elseif i == 4 then r, g, b = t, p, v
		elseif i == 5 then r, g, b = v, p, q
		end

		return color_t.new(r * 255, g * 255, b * 255, a * 255)
	end

	function math.lerp(a, b, t) return a + (b - a) * t end

	local function drag(x, y, width, height, xmenu, ymenu, item)
		local cursor = renderer.get_cursor_pos()
		if (cursor.x >= x) and (cursor.x <= x + width) and (cursor.y >= y) and (cursor.y <= y + height) then
			if client.is_key_pressed(1) and item[1] == 0 then
				item[1] = 1
				item[2] = x - cursor.x
				item[3] = y - cursor.y
			end
		end
		if not client.is_key_pressed(1) then item[1] = 0 end
		if item[1] == 1 and ui.is_visible() then
			xmenu:set_value(cursor.x + item[2])
			ymenu:set_value(cursor.y + item[3])
		end
	end

	local function filledbox(x, y, w, h, al)
		local rgb = hsv2rgb(globalvars.get_real_time() / 4, 0.9, 1, 1)
		local chromd = chroma_dir:get_value()
		local col = color_line:get_value()
		local stl = style_line:get_value()

		if stl ~= 4 then
		renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(15, 15, 15, col.a * al))
		else
		renderer.rect_filled(vec2_t.new(x, y - 2), vec2_t.new(x + w, y + h), color_t.new(30, 30, 30, col.a * al))
		renderer.rect_filled_fade(vec2_t.new(x + 1, y - 1), vec2_t.new(x + w / 2, y), color_t.new(0, 213, 255, 255 * al), color_t.new(204, 18, 204, 255 * al), color_t.new(204, 18, 204, 255 * al), color_t.new(0, 213, 255, 255 * al))
		renderer.rect_filled_fade(vec2_t.new(x + (w / 2), y - 1), vec2_t.new(x + w - 1, y), color_t.new(204, 18, 204, 255 * al), color_t.new(255, 250, 0, 255 * al), color_t.new(255, 250, 0, 255 * al), color_t.new(204, 18, 204, 255 * al))
		end
		
		gradient_color = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(0, 0, 0, 255 * al) or stl == 2 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 3 and color_t.new(0, 213, 255, 255 * al) or stl == 5 and color_t.new(chromd==1 and rgb.g or rgb.r, chromd==1 and rgb.b or rgb.g, chromd ==1 and rgb.g or rgb.b, 255 * al) or color_t.new(0, 0, 0, 0)
		gradient_color1 = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 2 and color_t.new(0, 0, 0, 255 * al) or stl == 3 and color_t.new(204, 18, 204, 255 * al) or stl == 5 and color_t.new(chromd==2 and rgb.r or rgb.b, chromd==2 and rgb.g or rgb.r, chromd==2 and rgb.b or rgb.g, 255 * al) or color_t.new(0, 0, 0, 0)
		gradient_color2 = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(0, 0, 0, 255 * al) or stl == 2 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 3 and color_t.new(255, 250, 0, 255 * al) or stl == 5 and color_t.new(chromd==0 and rgb.g or rgb.r, chromd==0 and rgb.b or rgb.g, chromd ==0 and rgb.g or rgb.b, 255 * al) or color_t.new(0, 0, 0, 0)

		if stl ~= 4 then
			renderer.rect_filled_fade(vec2_t.new(x, y - 2), vec2_t.new(x + w / 2, y), gradient_color, gradient_color1, gradient_color1, gradient_color)
			renderer.rect_filled_fade(vec2_t.new(x + (w / 2), y - 2), vec2_t.new(x + w, y), gradient_color1, gradient_color2, gradient_color2, gradient_color1)
		end
	end


	local item = { 0, 0, 0 }
	local animwidth = 0;
	local alpha = { 0 }
	local bind = {
	["Double tap"] = {reference = ui.get_key_bind("rage_active_exploit_bind"), exploit = 2, add = 0, multiply = 0},
	["Hide shots"] = {reference = ui.get_key_bind("rage_active_exploit_bind"), exploit = 1, add = 0, multiply = 0},
	["Inverter"] = {reference = ui.get_key_bind("antihit_antiaim_flip_bind"), exploit = 0, add = 0, multiply = 0},
	["Auto peek"] = {reference = ui.get_key_bind("antihit_extra_autopeek_bind"), exploit = 0, add = 0, multiply = 0},
	["Slow walk"] = {reference = ui.get_key_bind("antihit_extra_slowwalk_bind"), exploit = 0, add = 0, multiply = 0},
	["Fake duck"] = {reference = ui.get_key_bind("antihit_extra_fakeduck_bind"), exploit = 0, add = 0, multiply = 0},
	["Jump bug"] = {reference = ui.get_key_bind("misc_jump_bug_bind"), exploit = 0, add = 0, multiply = 0},
	["Edge jump"] = {reference = ui.get_key_bind("misc_edge_jump_bind"), exploit = 0, add = 0, multiply = 0},
	["Thirdperson"] = {reference = lua_re_thirdperson_bind, exploit = 0, add = 0, multiply = 0},
	}

	local function draw_watermark()
		--ui visible
		if lua_re_menu:get_value() == 3 then
			local screen = screen_ind:get_value(1) or screen_ind:get_value(0)
			animation_type:set_visible(screen_ind:get_value(0))
			auto_resize_width:set_visible(screen_ind:get_value(0))
			style_line:set_visible(screen) chroma_dir:set_visible(style_line:get_value() == 5) color_line:set_visible(screen)
			lua_re_keybinds_x:set_visible(false) lua_re_keybinds_y:set_visible(false)
		else
			animation_type:set_visible(false)
			auto_resize_width:set_visible(false)
			style_line:set_visible(false) chroma_dir:set_visible(false) color_line:set_visible(false)
			lua_re_keybinds_x:set_visible(false) lua_re_keybinds_y:set_visible(false)
		end

		--watermark
		local function show_watermark()
			if screen_ind:get_value(1) then
				watermark()
			end
		end

		--keybinds
		local function watermark_keybinds()
			if screen_ind:get_value(0) and engine.is_connected() then
				local pos = {x = lua_re_keybinds_x:get_value(), y = lua_re_keybinds_y:get_value()}
				local alphak, keybinds = {}, {}
				local width, maxwidth = 25, 0;
				local height = 17;
				local bind_y = height + 4
					
				for i,v in pairs(bind) do
					local exploits = ui.get_combo_box("rage_active_exploit"):get_value(); v.add = math.lerp(v.add, v.reference:is_active() and 255 or 0, 0.1); v.multiply = v.add > 4 and 1 or 0;
					if v.add > 4 then if v.exploit == 0 then table.insert(keybinds, i) end; if v.exploit ~= 0 and exploits == v.exploit then table.insert(keybinds, i) end; end;
					if v.exploit == 0 and v.reference:is_active() then table.insert(alphak, i) end; if v.exploit ~= 0 and exploits == v.exploit and v.reference:is_active() then table.insert(alphak, i) end;
					end
				if #alphak ~= 0 or ui.is_visible() then alpha[1] = math.lerp(alpha[1], 255, 0.1) end; if #alphak == 0 and not ui.is_visible() then alpha[1] = math.lerp(alpha[1], 0, 0.1) end		
				for k,f in pairs(keybinds) do if renderer.get_text_size(fonts.verdana, 12, f .. "["..types[bind[f].reference:get_type() + 1].."]").x > maxwidth then maxwidth = renderer.get_text_size(fonts.verdana, 12, f .. "["..types[bind[f].reference:get_type() + 1].."]").x; end; end
				if maxwidth == 0 then maxwidth = 50 end; width = width + maxwidth; if width < 130 then width = 130 end if animwidth == 0 then animwidth = width end; animwidth = math.lerp(animwidth, width, 0.1)
				w = auto_resize_width:get_value() and (animation_type:get_value() == 1 and animwidth or width) or 150
				for k,f in pairs(keybinds) do  
					local v = bind[f]; bind_y = bind_y + (animation_type:get_value() == 1 and 20 * (v.add / 255) or 20 * v.multiply); plus = bind_y - (animation_type:get_value() == 1 and 20 * (v.add / 255) or 20 * v.multiply);
					renderer.text(f, fonts.verdana, vec2_t.new(pos.x + 5, pos.y + plus + 1), 12, color_t.new(0, 0, 0, 255 * (v.add / 255)))
					renderer.text(f, fonts.verdana, vec2_t.new(pos.x + 4, pos.y + plus), 12, color_t.new(255, 255, 255, 255 * (v.add / 255)))
					renderer.text("["..types[v.reference:get_type() + 1].."]", fonts.verdana, vec2_t.new(pos.x + w - renderer.get_text_size(fonts.verdana, 12, "["..types[v.reference:get_type() + 1].."]").x - 3, pos.y + plus + 1), 12, color_t.new(0, 0, 0, 255 * (v.add / 255)))
					renderer.text("["..types[v.reference:get_type() + 1].."]", fonts.verdana, vec2_t.new(pos.x + w - renderer.get_text_size(fonts.verdana, 12, "["..types[v.reference:get_type() + 1].."]").x - 4, pos.y + plus), 12, color_t.new(255, 255, 255, 255 * (v.add / 255)))
				end
				if alpha[1] > 1 then
					filledbox(pos.x, pos.y, w, height, (alpha[1] / 255))
					renderer.text("keybinds", fonts.verdana, vec2_t.new(pos.x + (w /2) - (renderer.get_text_size(fonts.verdana, 12, "keybinds").x /2) + 1, pos.y + 3), 12, color_t.new(0, 0, 0, 255 * (alpha[1] / 255)))
					renderer.text("keybinds", fonts.verdana, vec2_t.new(pos.x + (w /2) - (renderer.get_text_size(fonts.verdana, 12, "keybinds").x /2), pos.y + 2), 12, color_t.new(255, 255, 255, 255 * (alpha[1] / 255)))
					drag(pos.x, pos.y, w, height + 2, lua_re_keybinds_x, lua_re_keybinds_y, item)
				end
			end
		end
		
		if lua_re_watermark_enabled:get_value() then
			show_watermark()
			watermark_keybinds()
		end
	end


	client.register_callback("create_move", get_current_weapon)
	client.register_callback("create_move", show_current_weapon)
	client.register_callback("create_move", fakelag_chock)
	client.register_callback("create_move", lua_re_fake_angle)
	client.register_callback("paint", on_paint_indicators)
	client.register_callback("paint", on_paint_hitlist)
	client.register_callback("paint", draw_watermark)
	client.register_callback("shot_fired", hitlist)


-- Menu

local function menu_switch()
	if lua_re_menu:get_value() == 0 then

		-- Rage
		lua_re_ragelogs:set_visible(true)
		lua_re_votelogs:set_visible(true)
		lua_re_buylogs:set_visible(true)
			
		lua_re_autopeek:set_visible(true)
		lua_re_autopeek_circle:set_visible(true)

		lua_re_thirdperson_bind:set_visible(true)
		lua_re_onlyhead_bind:set_visible(true)
		lua_re_baim_bind:set_visible(true)
		lua_re_laim_bind:set_visible(true)
		lua_re_safepoints_bind:set_visible(true)
		lua_re_lethal_bind:set_visible(true)
		lua_re_pingspike_bind:set_visible(true)
		lua_re_pingspike:set_visible(true)
		lua_re_mindmg_bind:set_visible(true)
		lua_re_resolver_override_bind:set_visible(true)
			
		lua_re_dmgoverride_bind:set_visible(true)
		lua_re_dmgoverride:set_visible(true)
			
		lua_re_switchexploit:set_visible(true)
			
		lua_re_bt:set_visible(true)
		lua_re_bt_onxploit:set_visible(true)

		-- MinDmg
		lua_re_mindmg_enable:set_visible(false)
		lua_re_mindmg_weaponconfig:set_visible(false)

		-- DT/HS/FL/FD
		lua_re_weaponconfig:set_visible(false)
		
		-- Indicators
		scale_thirdperson:set_visible(false)
		thirdperson_scale:set_visible(false)

		indicators_switch:set_visible(false)
		x_slider:set_visible(false)
		y_slider:set_visible(false)

		hitlist_switch:set_visible(false)
		color_hitlist:set_visible(false)
		style:set_visible(false)
		hitlog_clear:set_visible(false)
		hitlog_pos_x:set_visible(false)
		hitlog_pos_y:set_visible(false)
		lua_re_watermark_enabled:set_visible(false)
		screen_ind:set_visible(false)
	
	elseif lua_re_menu:get_value() == 1 then

		-- Rage
		lua_re_ragelogs:set_visible(false)
		lua_re_votelogs:set_visible(false)
		lua_re_buylogs:set_visible(false)
			
		lua_re_autopeek:set_visible(false)
		lua_re_autopeek_circle:set_visible(false)
			
		lua_re_thirdperson_bind:set_visible(false)
		lua_re_onlyhead_bind:set_visible(false)
		lua_re_baim_bind:set_visible(false)
		lua_re_laim_bind:set_visible(false)
		lua_re_safepoints_bind:set_visible(false)
		lua_re_lethal_bind:set_visible(false)
		lua_re_pingspike_bind:set_visible(false)
		lua_re_pingspike:set_visible(false)
		lua_re_mindmg_bind:set_visible(false)
		lua_re_resolver_override_bind:set_visible(false)
			
		lua_re_dmgoverride_bind:set_visible(false)
		lua_re_dmgoverride:set_visible(false)
			
		lua_re_switchexploit:set_visible(false)
			
		lua_re_bt:set_visible(false)
		lua_re_bt_onxploit:set_visible(false)

		-- MinDmg
		lua_re_mindmg_enable:set_visible(true)
		lua_re_mindmg_weaponconfig:set_visible(true)

		-- DT/HS/FL/FD
		lua_re_weaponconfig:set_visible(false)

		-- Indicators
		scale_thirdperson:set_visible(false)
		thirdperson_scale:set_visible(false)

		indicators_switch:set_visible(false)
		x_slider:set_visible(false)
		y_slider:set_visible(false)

		hitlist_switch:set_visible(false)
		color_hitlist:set_visible(false)
		style:set_visible(false)
		hitlog_clear:set_visible(false)
		hitlog_pos_x:set_visible(false)
		hitlog_pos_y:set_visible(false)
		lua_re_watermark_enabled:set_visible(false)
		screen_ind:set_visible(false)

	elseif lua_re_menu:get_value() == 2 then

		-- Rage
		lua_re_ragelogs:set_visible(false)
		lua_re_votelogs:set_visible(false)
		lua_re_buylogs:set_visible(false)
			
		lua_re_autopeek:set_visible(false)
		lua_re_autopeek_circle:set_visible(false)
			
		lua_re_thirdperson_bind:set_visible(false)
		lua_re_onlyhead_bind:set_visible(false)
		lua_re_baim_bind:set_visible(false)
		lua_re_laim_bind:set_visible(false)
		lua_re_safepoints_bind:set_visible(false)
		lua_re_lethal_bind:set_visible(false)
		lua_re_pingspike_bind:set_visible(false)
		lua_re_pingspike:set_visible(false)
		lua_re_mindmg_bind:set_visible(false)
		lua_re_resolver_override_bind:set_visible(false)
			
		lua_re_dmgoverride_bind:set_visible(false)
		lua_re_dmgoverride:set_visible(false)
			
		lua_re_switchexploit:set_visible(false)
			
		lua_re_bt:set_visible(false)
		lua_re_bt_onxploit:set_visible(false)

		-- MinDmg
		lua_re_mindmg_enable:set_visible(false)
		lua_re_mindmg_weaponconfig:set_visible(false)

		-- DT/HS/FL/FD
		lua_re_weaponconfig:set_visible(true)

		-- Indicators
		scale_thirdperson:set_visible(false)
		thirdperson_scale:set_visible(false)

		indicators_switch:set_visible(false)
		x_slider:set_visible(false)
		y_slider:set_visible(false)

		hitlist_switch:set_visible(false)
		color_hitlist:set_visible(false)
		style:set_visible(false)
		hitlog_clear:set_visible(false)
		hitlog_pos_x:set_visible(false)
		hitlog_pos_y:set_visible(false)
		lua_re_watermark_enabled:set_visible(false)
		screen_ind:set_visible(false)

	elseif lua_re_menu:get_value() == 3 then

		-- Rage
		lua_re_ragelogs:set_visible(false)
		lua_re_votelogs:set_visible(false)
		lua_re_buylogs:set_visible(false)
			
		lua_re_autopeek:set_visible(false)
		lua_re_autopeek_circle:set_visible(false)
		
		lua_re_thirdperson_bind:set_visible(false)
		lua_re_onlyhead_bind:set_visible(false)
		lua_re_baim_bind:set_visible(false)
		lua_re_laim_bind:set_visible(false)
		lua_re_safepoints_bind:set_visible(false)
		lua_re_lethal_bind:set_visible(false)
		lua_re_pingspike_bind:set_visible(false)
		lua_re_pingspike:set_visible(false)
		lua_re_mindmg_bind:set_visible(false)
		lua_re_resolver_override_bind:set_visible(false)
			
		lua_re_dmgoverride_bind:set_visible(false)
		lua_re_dmgoverride:set_visible(false)
			
		lua_re_switchexploit:set_visible(false)
			
		lua_re_bt:set_visible(false)
		lua_re_bt_onxploit:set_visible(false)

		-- MinDmg
		lua_re_mindmg_enable:set_visible(false)
		lua_re_mindmg_weaponconfig:set_visible(false)

		-- DT/HS/FL/FD
		lua_re_weaponconfig:set_visible(false)

		-- Indicators
		scale_thirdperson:set_visible(true)
		thirdperson_scale:set_visible(true)

		indicators_switch:set_visible(true)
		x_slider:set_visible(true)
		y_slider:set_visible(true)

		hitlist_switch:set_visible(true)
		color_hitlist:set_visible(true)
		style:set_visible(true)
		hitlog_clear:set_visible(true)
		hitlog_pos_x:set_visible(true)
		hitlog_pos_y:set_visible(true)
		lua_re_watermark_enabled:set_visible(true)
		screen_ind:set_visible(true)
	end
end


client.register_callback("paint", menu_switch)