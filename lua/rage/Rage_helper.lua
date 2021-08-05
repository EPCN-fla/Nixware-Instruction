--[[
    # Author: Fla1337
    # Description: Just for rage.
    # Reference:
		RageEssentials.lua(https://nixware.cc/threads/16812/);
		Indicators.lua(https://nixware.cc/threads/12008/);
		simple_hitlist.lua(https://nixware.cc/threads/14831/);
		DT Helper.lua(https://nixware.cc/threads/15098/)
--]]

require 'AdvancedAPI'

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

local weapon_data_call = ffi.cast("int*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC 0C 01 ? ? 53 8B D9 56 57 8D 8B"));
local function weapon_data(weapon)
	return ffi.cast("struct WeaponInfo_t*", weapon_data_call(ffi.cast("void*", weapon:get_address())));
end
local m_bSpotted = se.get_netvar("DT_BaseEntity", "m_bSpotted")
local m_vecOrigin = se.get_netvar("DT_BaseEntity", "m_vecOrigin")
local m_fLastShotTime = se.get_netvar("DT_WeaponCSBase", "m_fLastShotTime")
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")
local m_vecVelocity = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]")
local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")
local m_hActiveWeapon = se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")
local m_iItemDefinitionIndex = se.get_netvar("DT_BaseAttributableItem", "m_iItemDefinitionIndex")
local m_flDuckAmount = se.get_netvar("DT_BasePlayer", "m_flDuckAmount");

local sv_maxunlag = se.get_convar("sv_maxunlag")
local sv_maxunlag_original = sv_maxunlag:get_float()

local function is_knife()
	local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
	if weapon_data(weapon).type == 1 then
		return true
	end
	return false
end

local function dist(a, b)
	return vec3_t.new(a.x - b.x, a.y - b.y, a.z - b.z):length()
end

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
	"head",
	"chest",
	"pelvis",
	"stomach",
	"legs",
	"foot"
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


local lua_re_menu = ui.add_combo_box("Menu", "lua_menu", { "Rage", "DT/HS/FL/FD", "Visuals" }, 0)

local lua_re_ragelogs = ui.add_check_box("Rage Logs", "lua_re_ragelogs", false)	
local lua_re_votelogs = ui.add_check_box("Vote Logs", "lua_re_votelogs", false)
local lua_re_buylogs = ui.add_check_box("Buy Logs", "lua_re_buylogs", false)

local lua_re_autopeek = ui.add_key_bind("Autopeek", "lua_re_autopeek", 0, 1)
local lua_re_autopeek_circle = ui.add_color_edit("Autopeek Circle", "lua_re_autopeek_circle", true, color_t.new(79, 79, 79, 255))

local scale_thirdperson = ui.add_check_box("Thirdperson Distance", "scale_thirdperson", false)
local thirdperson_scale = ui.add_slider_int("Thirdperson Scale", "thirdperson_scale", 65, 200, 120)

local lua_re_onlyhead_bind = ui.add_key_bind("Only Head", "lua_re_onlyhead_bind", 0, 2)
local lua_re_baim_bind = ui.add_key_bind("Force BAIM", "lua_re_baim_bind", 0, 2)
local lua_re_laim_bind = ui.add_key_bind("Wash Legs", "lua_re_laim_bind", 0, 2)
local lua_re_safepoints_bind = ui.add_key_bind("Force Safepoints", "lua_re_safepoints_bind", 0, 2)
local lua_re_lethal_bind = ui.add_key_bind("Force Lethal Shots", "lua_re_lethal_bind", 0, 2)
local lua_re_pingspike_bind = ui.add_key_bind("Ping Spike", "lua_re_pingspike_bind", 0, 2)
local lua_re_mindmg_bind = ui.add_key_bind("MinDmg", "lua_re_mindmg_bind", 0, 2)
local lua_re_resolver_override_bind = ui.add_key_bind("Disable Resolver", "lua_re_resolver_override_bind", 0, 2)

local lua_re_dmgoverride_bind = ui.add_key_bind("Damage Override", "lua_re_dmgoverride_bind", 0, 2)
local lua_re_dmgoverride = ui.add_slider_int("Override Value", "lua_re_dmgoverride", 0, 100, 0)

local lua_re_switchexploit = ui.add_key_bind("Switch Exploit", "lua_re_switchexploit", 0, 1)

local lua_re_bt = ui.add_slider_float("Backtrack", "lua_re_bt", 0, 0.2, 0)
local lua_re_bt_onxploit = ui.add_slider_float("Backtrack On Exploit", "lua_re_bt_onxploit", 0, 0.2, 0)

local lua_re_jumpscout = ui.add_key_bind("Jumpscout", "lua_re_jumpscout", 0, 2)
local lua_re_jumpscout_hitboxes = ui.add_multi_combo_box("Jumpscout hitboxes", "lua_re_jumpscout_hitboxes", { "head", "chest", "pelvis", "stomach", "legs", "foot" }, { false, false, false, false, false, false })
local lua_re_jumpscout_hc = ui.add_slider_int("Jumpscout hitchance", "lua_re_jumpscout_hc", 0, 100, 0)
local lua_re_jumpscout_dmg = ui.add_slider_int("Jumpscout damage", "lua_re_jumpscout_dmg", 0, 101, 0)


-- Rage

	-- Global variate

	local switching_exploit = false

	local autopeek_accuracy = 10.0
	local autopeek_pos = vec3_t.new(0, 0, 0)
	local autopeek_return = false
	local autopeek_last_shot = 0

	local once_thirdperson = false

	local jumpscout_hc = ui.get_slider_int("rage_scout_hitchance"):get_value()

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

	local function jump_scout()
		local entity = entitylist.get_players(0)
		if lua_re_jumpscout:is_active() then
			ui.get_check_box("misc_autostrafer"):set_value(false)
			ui.get_slider_int("rage_scout_hitchance"):set_value(lua_re_jumpscout_hc:get_value())
			for i = 1, #entity do
				local player = entity[i]

				ragebot.override_hitscan(player:get_index(), SCAN_HEAD, lua_re_jumpscout_hitboxes:get_value(SCAN_HEAD))
				ragebot.override_hitscan(player:get_index(), SCAN_CHEST, lua_re_jumpscout_hitboxes:get_value(SCAN_CHEST))
				ragebot.override_hitscan(player:get_index(), SCAN_PELVIS, lua_re_jumpscout_hitboxes:get_value(SCAN_PELVIS))
				ragebot.override_hitscan(player:get_index(), SCAN_STOMACH, lua_re_jumpscout_hitboxes:get_value(SCAN_STOMACH))
				ragebot.override_hitscan(player:get_index(), SCAN_LEGS, lua_re_jumpscout_hitboxes:get_value(SCAN_LEGS))
				ragebot.override_hitscan(player:get_index(), SCAN_FOOT, lua_re_jumpscout_hitboxes:get_value(SCAN_FOOT))
				
				ragebot.override_min_damage(player:get_index(), lua_re_jumpscout_dmg:get_value())
			end
		else
			ui.get_check_box("misc_autostrafer"):set_value(true)
			ui.get_slider_int("rage_scout_hitchance"):set_value(jumpscout_hc)
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
		autopeek(cmd)
		switch_exploit()
		backtracking()
		jump_scout()
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
		ui.get_slider_int("rage_scout_hitchance"):set_value(jumpscout_hc)
	end
	
	client.register_callback("unload", on_unload)
	client.register_callback("paint", on_paint_autopeek)
	client.register_callback("fire_game_event", on_events)
	client.register_callback("shot_fired", on_shot_fired)
	client.register_callback("create_move", on_create_move)

--DT/HS/FL/FD

rage_active_exploit = ui.get_combo_box("rage_active_exploit")
antihit_extra_fakeduck_bind = ui.get_key_bind("antihit_extra_fakeduck_bind")
rage_active_exploit_bind = ui.get_key_bind("rage_active_exploit_bind")

local scar_hitscan_hs = ui.add_multi_combo_box('Auto HS/FL Hitscan', 'scar_hitscan_hs', hitscan, { false, false, false, false, false, false })
local scar_hitscan_noscope_dt = ui.add_multi_combo_box('Auto DT NoScope Hitscan', 'scar_hitscan_noscope_dt', hitscan, { false, false, false, false, false, false })
local scar_hitscan_dt = ui.add_multi_combo_box('Auto DT Hitscan', 'scar_hitscan_dt', hitscan, { false, false, false, false, false, false })
local scar_safepoint_hs = ui.add_combo_box('Auto HS/FL Safepoints', 'scar_safepoint_hs', {'default', 'prefer', 'force'}, 0)
local scar_headscale_hs = ui.add_slider_int('Auto HS/FL Head Scale', 'scar_headscale_hs', 0, 100, 0)
local scar_bodyscale_hs = ui.add_slider_int('Auto HS/FL Body Scale', 'scar_bodyscale_hs', 0, 100, 0)
local scar_hitchance_hs = ui.add_slider_int('Auto HS/FL HitChance', 'scar_hitchance_hs', 0, 100, 0)
local scar_safepoint_noscope_dt = ui.add_combo_box('Auto DT NoScope Safepoints', 'scar_safepoint_noscope_dt', {'default', 'prefer', 'force'}, 0)
local scar_headscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Head Scale', 'scar_headscale_noscope_dt', 0, 100, 0)
local scar_bodyscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Body Scale', 'scar_bodyscale_noscope_dt', 0, 100, 0)
local scar_hitchance_noscope_dt = ui.add_slider_int('Auto DT NoScope HitChance', 'scar_hitchance_noscope_dt', 0, 100, 0)
local scar_safepoint_dt = ui.add_combo_box('Auto DT Safepoints', 'scar_safepoint_dt', {'default', 'prefer', 'force'}, 0)
local scar_headscale_dt = ui.add_slider_int('Auto DT Head Scale', 'scar_headscale_dt', 0, 100, 0)
local scar_bodyscale_dt = ui.add_slider_int('Auto DT Body Scale', 'scar_bodyscale_dt', 0, 100, 0)
local scar_hitchance_dt = ui.add_slider_int('Auto DT HitChance', 'scar_hitchance_dt', 0, 100, 0)

local auto_hitscan = ui.get_multi_combo_box("rage_auto_hitscan")
local auto_head = ui.get_slider_int("rage_auto_head_pointscale") 
local auto_body = ui.get_slider_int("rage_auto_body_pointscale")
local auto_sp = ui.get_combo_box("rage_auto_safepoints")
local auto_hitchance = ui.get_slider_int("rage_auto_hitchance")
local auto_autoscope = ui.get_check_box("rage_auto_autoscope")

local function scar_override()   
    local player = entitylist.get_local_player()
    local is_scoped = player:get_prop_bool( se.get_netvar( "DT_CSPlayer", "m_bIsScoped" ) )

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
end

local function scar_hitscan()
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
end

client.register_callback('create_move', scar_override)
client.register_callback('create_move', scar_hitscan)



--Visuals

	-- Indicators

	local screen = engine.get_screen_size()

	local indicators_switch = ui.add_check_box("Indicators", "indicators_switch", false)
	local x_slider = ui.add_slider_int('Indicators position x', 'og_indicators_pos_x', 0, screen.x, 10)
	local y_slider = ui.add_slider_int('Indicators position y', 'og_indicators_pos_y', 0, screen.y, 260)

	local fonts = {
		verdana = renderer.setup_font('c:/windows/fonts/verdana.ttf', 12, 0),
		tohomabd = renderer.setup_font('C:/windows/fonts/tahomabd.ttf', 30, 0)
		} 

	local indicators = {}

	local exploit_names = {
		'none',
		'HS',
		'DT'
	}

	local binds = {
		{ name = 'XT',                  cfg = ui.get_slider_int('misc_ping_spike_amount'),      type = 'slider_int', disable_val = 0 },
		{ name = exploit_names,         cfg = ui.get_key_bind('rage_active_exploit_bind'),      type = 'key_bind' },
		{ name = 'FD',                  cfg = ui.get_key_bind('antihit_extra_fakeduck_bind'),   type = 'key_bind' },
		{ name = 'AP',                  cfg = lua_re_autopeek,               type = 'key_bind' },
		{ name = 'Only Head',           cfg = lua_re_onlyhead_bind,          type = 'key_bind' },
		{ name = 'BAIM',                cfg = lua_re_baim_bind,              type = 'key_bind' },
		{ name = 'LAIM',                cfg = lua_re_laim_bind,              type = 'key_bind' },
		{ name = 'Lethal',              cfg = lua_re_lethal_bind,            type = 'key_bind' },
		{ name = 'MinDmg',     			cfg = lua_re_mindmg_bind,       	 type = 'key_bind' },
		{ name = 'Jumpscout',        	cfg = lua_re_jumpscout,            	 type = 'key_bind' },
		{ name = 'Force Safepoint',     cfg = lua_re_safepoints_bind,        type = 'key_bind' },
		{ name = 'Damage Override',     cfg = lua_re_dmgoverride_bind,       type = 'key_bind' },
		{ name = 'Resolver Disabled',   cfg = lua_re_resolver_override_bind, type = 'key_bind' },
		{ name = 'FL',                  type = 'static' },
	}

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

	local function draw_indicators()
		local x = x_slider:get_value()
		local h = screen.y - 50 - y_slider:get_value()

		local y = 30 * #indicators

		for key, value in pairs(indicators) do
			local addition = 0

			local sizes = renderer.get_text_size(fonts.tohomabd, 30, value.text)
			
			render_text(value.text, x, h - y, value.color)

			addition = addition + sizes.y

			if value.bar then
				local bar = value.bar
				local fill = (sizes.x - 2) / (bar.max - bar.min) * (bar.value - bar.min)

				render_filled_rect(x, h - y + addition, sizes.x, 8, color_t.new(0, 0, 0, 150))
				render_filled_rect(x + 1, h - y + addition + 1, fill, 6, bar.color)
			
				addition = addition + 6
			end

			y = y - addition
		end
	end

	local function to_percent(a, b)
		return a * 100 / b
	end

	local function p2c(per, alpha)
		local red = per < 50 and 200 or math.floor(200 - (per * 2 - 100) * 200 / 100);
		local green = per > 50 and 200 or math.floor((per * 2) * 200 / 100);

		return color_t.new(red, green, 13, alpha or 255);
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
							}
						}
					end
				elseif bind.type == 'slider_int' then
					if bind.cfg:get_value() > bind.disable_val then
						information = {
							text = name,
							color = color_t.new(0, 255, 0, 255)
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

	local function on_object(mx, my, pos_x, pos_y, w, h)
		return mx <= pos_x + w and mx >= pos_x and my <= pos_y + h and my >= pos_y
	end

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

	client.register_callback("paint", on_paint_indicators)
	client.register_callback("paint", on_paint_hitlist)
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
			
		scale_thirdperson:set_visible(true)
		thirdperson_scale:set_visible(true)
			
		lua_re_onlyhead_bind:set_visible(true)
		lua_re_baim_bind:set_visible(true)
		lua_re_laim_bind:set_visible(true)
		lua_re_safepoints_bind:set_visible(true)
		lua_re_lethal_bind:set_visible(true)
		lua_re_pingspike_bind:set_visible(true)
		lua_re_mindmg_bind:set_visible(true)
		lua_re_resolver_override_bind:set_visible(true)
			
		lua_re_dmgoverride_bind:set_visible(true)
		lua_re_dmgoverride:set_visible(true)
			
		lua_re_switchexploit:set_visible(true)
			
		lua_re_bt:set_visible(true)
		lua_re_bt_onxploit:set_visible(true)
			
		lua_re_jumpscout:set_visible(true)
		lua_re_jumpscout_hitboxes:set_visible(true)
		lua_re_jumpscout_hc:set_visible(true)
		lua_re_jumpscout_dmg:set_visible(true)

		-- DT/HS/FL/FD
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

		-- Indicators
		indicators_switch:set_visible(false)
		x_slider:set_visible(false)
		y_slider:set_visible(false)

		hitlist_switch:set_visible(false)
		color_hitlist:set_visible(false)
		style:set_visible(false)
		hitlog_clear:set_visible(false)
		hitlog_pos_x:set_visible(false)
		hitlog_pos_y:set_visible(false)

	elseif lua_re_menu:get_value() == 1 then

		-- Rage
		lua_re_ragelogs:set_visible(false)
		lua_re_votelogs:set_visible(false)
		lua_re_buylogs:set_visible(false)
			
		lua_re_autopeek:set_visible(false)
		lua_re_autopeek_circle:set_visible(false)
			
		scale_thirdperson:set_visible(false)
		thirdperson_scale:set_visible(false)
			
		lua_re_onlyhead_bind:set_visible(false)
		lua_re_baim_bind:set_visible(false)
		lua_re_laim_bind:set_visible(false)
		lua_re_safepoints_bind:set_visible(false)
		lua_re_lethal_bind:set_visible(false)
		lua_re_pingspike_bind:set_visible(false)
		lua_re_mindmg_bind:set_visible(false)
		lua_re_resolver_override_bind:set_visible(false)
			
		lua_re_dmgoverride_bind:set_visible(false)
		lua_re_dmgoverride:set_visible(false)
			
		lua_re_switchexploit:set_visible(false)
			
		lua_re_bt:set_visible(false)
		lua_re_bt_onxploit:set_visible(false)
			
		lua_re_jumpscout:set_visible(false)
		lua_re_jumpscout_hitboxes:set_visible(false)
		lua_re_jumpscout_hc:set_visible(false)
		lua_re_jumpscout_dmg:set_visible(false)

		-- DT/HS/FL/FD
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

		-- Indicators
		indicators_switch:set_visible(false)
		x_slider:set_visible(false)
		y_slider:set_visible(false)

		hitlist_switch:set_visible(false)
		color_hitlist:set_visible(false)
		style:set_visible(false)
		hitlog_clear:set_visible(false)
		hitlog_pos_x:set_visible(false)
		hitlog_pos_y:set_visible(false)

	elseif lua_re_menu:get_value() == 2 then

		-- Rage
		lua_re_ragelogs:set_visible(false)
		lua_re_votelogs:set_visible(false)
		lua_re_buylogs:set_visible(false)
			
		lua_re_autopeek:set_visible(false)
		lua_re_autopeek_circle:set_visible(false)
			
		scale_thirdperson:set_visible(false)
		thirdperson_scale:set_visible(false)
			
		lua_re_onlyhead_bind:set_visible(false)
		lua_re_baim_bind:set_visible(false)
		lua_re_laim_bind:set_visible(false)
		lua_re_safepoints_bind:set_visible(false)
		lua_re_lethal_bind:set_visible(false)
		lua_re_pingspike_bind:set_visible(false)
		lua_re_mindmg_bind:set_visible(false)
		lua_re_resolver_override_bind:set_visible(false)
			
		lua_re_dmgoverride_bind:set_visible(false)
		lua_re_dmgoverride:set_visible(false)
			
		lua_re_switchexploit:set_visible(false)
			
		lua_re_bt:set_visible(false)
		lua_re_bt_onxploit:set_visible(false)
			
		lua_re_jumpscout:set_visible(false)
		lua_re_jumpscout_hitboxes:set_visible(false)
		lua_re_jumpscout_hc:set_visible(false)
		lua_re_jumpscout_dmg:set_visible(false)

		-- DT/HS/FL/FD
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

		-- Indicators
		indicators_switch:set_visible(true)
		x_slider:set_visible(true)
		y_slider:set_visible(true)

		hitlist_switch:set_visible(true)
		color_hitlist:set_visible(true)
		style:set_visible(true)
		hitlog_clear:set_visible(true)
		hitlog_pos_x:set_visible(true)
		hitlog_pos_y:set_visible(true)

	end
end


client.register_callback("create_move", menu_switch)