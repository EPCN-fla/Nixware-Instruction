local lua_re_autopeek = ui.add_key_bind("autopeek", "lua_re_autopeek", 0, 1)
local lua_re_autopeek_circle = ui.add_color_edit("autopeek circle", "lua_re_autopeek_circle", true, color_t.new(255, 255, 255, 255))

local lua_re_autoduck = ui.add_key_bind("autoduck", "lua_re_autoduck", 0, 1)
local lua_re_autoduck_limit = ui.add_slider_float("autoduck limit", "lua_re_autoduck_limit", 0, 1, 0)

local lua_re_ragelogs = ui.add_check_box("rage logs", "lua_re_ragelogs", false)	
local lua_re_votelogs = ui.add_check_box("vote logs", "lua_re_votelogs", false)
local lua_re_buylogs = ui.add_check_box("buy logs", "lua_re_buylogs", false)

local lua_re_radar = ui.add_check_box("reveal radar", "lua_re_radar", false)

local lua_re_baim_hitboxes = ui.add_multi_combo_box("baim hitboxes", "lua_re_baim_hitboxes", { "head", "chest", "pelvis", "stomach", "legs", "foot" }, { false, false, false, false, false, false })
local lua_re_onshot_hitboxes = ui.add_multi_combo_box("on shot hitboxes", "lua_re_onshot_hitboxes", { "head", "chest", "pelvis", "stomach", "legs", "foot" }, { false, false, false, false, false, false })
local lua_re_onshot_time = ui.add_slider_float("on shot time", "lua_re_onshot_time", 0, 0.2, 0)

local lua_re_safepoints_conditions = ui.add_multi_combo_box("force safepoints conditions", "lua_re_safepoints_conditions", { "standing", "slowwalking", "lethal" }, { false, false ,false })
local lua_re_baim_conditions = ui.add_multi_combo_box("baim conditions", "lua_re_baim_conditions", { "standing", "slowwalking", "lethal" }, { false, false ,false })
local lua_re_hs_conditions = ui.add_multi_combo_box("hs conditions", "lua_re_hs_conditions", { "in air", "in run", "on shot" }, { false, false ,false })

local lua_re_mp_head = ui.add_slider_int("multipoints head", "lua_re_mp_head", 0, 100, 0)
local lua_re_mp_body = ui.add_slider_int("multipoints body", "lua_re_mp_body", 0, 100, 0)
local lua_re_mp_conditions = ui.add_multi_combo_box("multipoints conditions", "lua_re_mp_conditions", { "in air", "in run", "on shot", "standing", "slowwalking", "lethal" }, { false, false ,false, false, false ,false })

local lua_re_onshot_bind = ui.add_key_bind("force on shot", "lua_re_onshot_bind", 0, 1)
local lua_re_baim_bind = ui.add_key_bind("force baim", "lua_re_baim_bind", 0, 1)
local lua_re_safepoints_bind = ui.add_key_bind("force safepoints", "lua_re_safepoints_bind", 0, 1)
local lua_re_lethal_bind = ui.add_key_bind("force lethal shots", "lua_re_lethal_bind", 0, 1)
local lua_re_resolver_override_bind = ui.add_key_bind("force override resolver", "lua_re_resolver_override_bind", 0, 1)

local lua_re_mindmg = ui.add_slider_int("min damage", "lua_re_mindmg", 0, 100, 0)
local lua_re_mindmg_bind = ui.add_key_bind("force min damage", "lua_re_mindmg_bind", 0, 1)

local lua_re_bt = ui.add_slider_float("backtrack", "lua_re_bt", 0, 0.2, 0)
local lua_re_bt_onxploit = ui.add_slider_float("backtrack on exploit", "lua_re_bt_onxploit", 0, 0.2, 0)

local lua_re_switchexploit = ui.add_key_bind("switch exploit", "lua_re_switchexploit", 0, 1)

local lua_re_jumpscout = ui.add_key_bind("jumpscout", "lua_re_jumpscout", 0, 1)
local lua_re_jumpscout_hitboxes = ui.add_multi_combo_box("jumpscout hitboxes", "lua_re_jumpscout_hitboxes", { "head", "chest", "pelvis", "stomach", "legs", "foot" }, { false, false, false, false, false, false })
local lua_re_jumpscout_hc = ui.add_slider_int("jumpscout hitchance", "lua_re_jumpscout_hc", 0, 100, 0)
local lua_re_jumpscout_dmg = ui.add_slider_int("jumpscout damage", "lua_re_jumpscout_dmg", 0, 101, 0)

local lua_re_keybinds = ui.add_check_box("keybinds", "lua_re_keybinds", false)
local lua_re_keybinds_color = ui.add_color_edit("keybinds color", "lua_re_keybinds_color", true, color_t.new(255, 255, 255, 255))

--

local switching_exploit = false

local autopeek_accuracy = 10.0
local autopeek_pos = vec3_t.new(0, 0, 0)
local autopeek_return = false
local autopeek_last_shot = 0

local autoduck_return = false
local autoduck_last_shot = 0

local vote_options = {}

local jumpscout = false
local jumpscout_as = ui.get_check_box("misc_autostrafer"):get_value()
local jumpscout_hc = ui.get_slider_int("rage_scout_hitchance"):get_value()
local jumpscout_injump = false

local player_shots = {}
for i = 0, 64 do player_shots[i] = 0.0 end

--

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

local weapon_ssg08 = 40
local function is_scout()
    local handle = entitylist.get_local_player():get_prop_int(m_hActiveWeapon)
    local active_weapon = entitylist.get_entity_from_handle(handle)
	if active_weapon:get_prop_int(m_iItemDefinitionIndex) ~= weapon_ssg08 then return false end
	return true
end

local function is_knife()
	local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
	if weapon_data(weapon).type == 1 then
		return true
	end
	return false
end

--

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

local hitgroups =
{
	"head",
	"chest",
	"pelvis",
	"stomach",
	"legs",
	"foot"
}

local SCAN_HEAD = 0
local SCAN_CHEST = 1
local SCAN_PELVIS = 2
local SCAN_STOMACH = 3
local SCAN_LEGS = 4
local SCAN_FOOT = 5

--

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

--

local keybinds_active = 0	
local function get_keybind(kb, title)
	local kb_type = kb:get_type()
	if kb:is_active() then
		local kb_type_text = ""
		if kb_type == 0 then
			kb_type_text = "always on"
		elseif kb_type == 1 then
			kb_type_text = "hold"
		elseif kb_type == 2 then
			kb_type_text = "toggle"
		else
			kb_type_text = "force disable"
		end
		keybinds_active = keybinds_active + 1
		return title .. " [" .. kb_type_text .. "]" .. "\n"
	end
	return ""
end

local font_size = 14
local font = renderer.setup_font("C:/windows/fonts/lucon.ttf", font_size, 0)

local exploits = 
{ 
	[0] = "none",
	[1] = "hide shots",
	[2] = "double tap"
}

local circle_points = 20.0
local function on_paint()
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
	if lua_re_keybinds:get_value() and engine.get_local_player() ~= 0 then
		-- Ghetto keybinds, enjoy!
		local keybinds = ""
		keybinds_active = 0
		local autopeek_state = "ready"
		if autopeek_return then autopeek_state = "return" end
		keybinds = keybinds .. get_keybind(lua_re_autopeek, "autopeek " .. autopeek_state)
		local autoduck_state = "ready"
		if autoduck_return then autoduck_state = "return" end
		keybinds = keybinds .. get_keybind(lua_re_autoduck, "autoduck " .. autoduck_state)
		keybinds = keybinds .. get_keybind(lua_re_onshot_bind, "wait on shot")
		keybinds = keybinds .. get_keybind(lua_re_baim_bind, "force baim")
		keybinds = keybinds .. get_keybind(lua_re_safepoints_bind, "force safepoints")
		keybinds = keybinds .. get_keybind(lua_re_lethal_bind, "force lethal shots")
		keybinds = keybinds .. get_keybind(lua_re_resolver_override_bind, "force resolver override")
		if ui.get_combo_box("rage_active_exploit"):get_value() ~= 0 then
			keybinds = keybinds .. get_keybind(ui.get_key_bind("rage_active_exploit_bind"), exploits[ui.get_combo_box("rage_active_exploit"):get_value()])
		end
		keybinds = keybinds .. get_keybind(lua_re_jumpscout, "jumpscout")
		keybinds = keybinds .. get_keybind(ui.get_key_bind("antihit_extra_slowwalk_bind"), "slow walk")
		keybinds = keybinds .. get_keybind(lua_re_mindmg_bind, "mindmg " .. lua_re_mindmg:get_value())
		renderer.text(keybinds, font, vec2_t.new(0, engine.get_screen_size().y / 2 - (keybinds_active * font_size) / 2), font_size, lua_re_keybinds_color:get_value())
	end
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

local function essentials(cmd)
	local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
	local damage = weapon_data(weapon).damage
	local local_player = entitylist.get_local_player()
	local player_team = local_player:get_prop_int(m_iTeamNum)
	for i = 0, 64 do
		local entity = entitylist.get_entity_by_index(i)
		if entity ~= nil and player_team ~= entity:get_prop_int(m_iTeamNum) and entity:get_prop_int(m_iHealth) > 0 then
			--reveal radar
			if lua_re_radar:get_value() then
				entity:set_prop_bool(m_bSpotted, true)
			end
			--disable head if any hs conditions are enabled
			if lua_re_hs_conditions:get_value(0) or lua_re_hs_conditions:get_value(1) or lua_re_hs_conditions:get_value(2) then
				ragebot.override_hitscan(i, SCAN_HEAD, false)
			end
			--conditions
			local health = entity:get_prop_int(m_iHealth)
			if damage > health then -- lethal
				if lua_re_mp_conditions:get_value(5) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_baim_conditions:get_value(2) then
					ragebot.override_hitscan(i, SCAN_HEAD, lua_re_baim_hitboxes:get_value(SCAN_HEAD))
					ragebot.override_hitscan(i, SCAN_CHEST, lua_re_baim_hitboxes:get_value(SCAN_CHEST))
					ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_baim_hitboxes:get_value(SCAN_PELVIS))
					ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_baim_hitboxes:get_value(SCAN_STOMACH))
					ragebot.override_hitscan(i, SCAN_LEGS, lua_re_baim_hitboxes:get_value(SCAN_LEGS))
					ragebot.override_hitscan(i, SCAN_FOOT, lua_re_baim_hitboxes:get_value(SCAN_FOOT))
				end
				if lua_re_safepoints_conditions:get_value(2) then
					ragebot.override_safe_point(i, 2) 
				end
			end
			local velocity = entity:get_prop_vector(m_vecVelocity)
			local speed = velocity:length()
			if speed < 8.0 then --standing
				if lua_re_mp_conditions:get_value(3) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_baim_conditions:get_value(0) then
					ragebot.override_hitscan(i, SCAN_HEAD, lua_re_baim_hitboxes:get_value(SCAN_HEAD))
					ragebot.override_hitscan(i, SCAN_CHEST, lua_re_baim_hitboxes:get_value(SCAN_CHEST))
					ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_baim_hitboxes:get_value(SCAN_PELVIS))
					ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_baim_hitboxes:get_value(SCAN_STOMACH))
					ragebot.override_hitscan(i, SCAN_LEGS, lua_re_baim_hitboxes:get_value(SCAN_LEGS))
					ragebot.override_hitscan(i, SCAN_FOOT, lua_re_baim_hitboxes:get_value(SCAN_FOOT))
				end
				if lua_re_safepoints_conditions:get_value(0) then
					ragebot.override_safe_point(i, 2) 
				end
			elseif speed < 180.0 then --slowwalking / shifting
				if lua_re_mp_conditions:get_value(4) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_baim_conditions:get_value(1) then
					ragebot.override_hitscan(i, SCAN_HEAD, lua_re_baim_hitboxes:get_value(SCAN_HEAD))
					ragebot.override_hitscan(i, SCAN_CHEST, lua_re_baim_hitboxes:get_value(SCAN_CHEST))
					ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_baim_hitboxes:get_value(SCAN_PELVIS))
					ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_baim_hitboxes:get_value(SCAN_STOMACH))
					ragebot.override_hitscan(i, SCAN_LEGS, lua_re_baim_hitboxes:get_value(SCAN_LEGS))
					ragebot.override_hitscan(i, SCAN_FOOT, lua_re_baim_hitboxes:get_value(SCAN_FOOT))
				end
				if lua_re_safepoints_conditions:get_value(1) then
					ragebot.override_safe_point(i, 2) 
				end
			else --running / bhopping
				if lua_re_mp_conditions:get_value(1) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_hs_conditions:get_value(1) then
					ragebot.override_hitscan(i, SCAN_HEAD, true)
				end
			end
			if player_shots[i] + lua_re_onshot_time:get_value() > globalvars.get_current_time() then --on shot
				ragebot.override_max_misses(i, 0)
				ragebot.override_safe_point(i, 0)
				ragebot.override_hitscan(i, SCAN_HEAD, lua_re_onshot_hitboxes:get_value(SCAN_HEAD))
				ragebot.override_hitscan(i, SCAN_CHEST, lua_re_onshot_hitboxes:get_value(SCAN_CHEST))
				ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_onshot_hitboxes:get_value(SCAN_PELVIS))
				ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_onshot_hitboxes:get_value(SCAN_STOMACH))
				ragebot.override_hitscan(i, SCAN_LEGS, lua_re_onshot_hitboxes:get_value(SCAN_LEGS))
				ragebot.override_hitscan(i, SCAN_FOOT, lua_re_onshot_hitboxes:get_value(SCAN_FOOT))
				if lua_re_mp_conditions:get_value(2) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_hs_conditions:get_value(2) then
					ragebot.override_hitscan(i, SCAN_HEAD, true)
				end
			end
			if velocity.z ~= 0 then --in air
				if lua_re_mp_conditions:get_value(0) then
					ragebot.override_head_scale(i, lua_re_mp_head:get_value())
					ragebot.override_body_scale(i, lua_re_mp_body:get_value())
				end
				if lua_re_hs_conditions:get_value(0) then
					ragebot.override_hitscan(i, SCAN_HEAD, true)
				end
			end
			--jumpscout
			if jumpscout_injump then
				ragebot.override_safe_point(i, 0)
				
				ragebot.override_hitscan(i, SCAN_HEAD, lua_re_jumpscout_hitboxes:get_value(SCAN_HEAD))
				ragebot.override_hitscan(i, SCAN_CHEST, lua_re_jumpscout_hitboxes:get_value(SCAN_CHEST))
				ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_jumpscout_hitboxes:get_value(SCAN_PELVIS))
				ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_jumpscout_hitboxes:get_value(SCAN_STOMACH))
				ragebot.override_hitscan(i, SCAN_LEGS, lua_re_jumpscout_hitboxes:get_value(SCAN_LEGS))
				ragebot.override_hitscan(i, SCAN_FOOT, lua_re_jumpscout_hitboxes:get_value(SCAN_FOOT))
				
				ragebot.override_min_damage(i, lua_re_jumpscout_dmg:get_value())
			end
			--binds
			if lua_re_onshot_bind:is_active() then
				if player_shots[i] + lua_re_onshot_time:get_value() < globalvars.get_current_time() then
					ragebot.override_hitscan(i, SCAN_HEAD, false)
					ragebot.override_hitscan(i, SCAN_CHEST, false)
					ragebot.override_hitscan(i, SCAN_PELVIS, false)
					ragebot.override_hitscan(i, SCAN_STOMACH, false)
					ragebot.override_hitscan(i, SCAN_LEGS, false)
					ragebot.override_hitscan(i, SCAN_FOOT, false)
				end
			end
			if lua_re_baim_bind:is_active() then
				ragebot.override_hitscan(i, SCAN_HEAD, lua_re_baim_hitboxes:get_value(SCAN_HEAD))
				ragebot.override_hitscan(i, SCAN_CHEST, lua_re_baim_hitboxes:get_value(SCAN_CHEST))
				ragebot.override_hitscan(i, SCAN_PELVIS, lua_re_baim_hitboxes:get_value(SCAN_PELVIS))
				ragebot.override_hitscan(i, SCAN_STOMACH, lua_re_baim_hitboxes:get_value(SCAN_STOMACH))
				ragebot.override_hitscan(i, SCAN_LEGS, lua_re_baim_hitboxes:get_value(SCAN_LEGS))
				ragebot.override_hitscan(i, SCAN_FOOT, lua_re_baim_hitboxes:get_value(SCAN_FOOT))
			end
			if lua_re_safepoints_bind:is_active() then 
				ragebot.override_safe_point(i, 2) 
			end
			if lua_re_lethal_bind:is_active() then 
				if ui.get_combo_box("rage_active_exploit"):get_value() == 2 and ui.get_key_bind("rage_active_exploit_bind"):is_active() then
					ragebot.override_min_damage(i, (health / 2) + 1)
				else
					ragebot.override_min_damage(i, health + 1)
				end
			end
			if lua_re_mindmg_bind:is_active() then
				ragebot.override_min_damage(i, lua_re_mindmg:get_value())
			end
			if lua_re_resolver_override_bind:is_active() then
				ragebot.override_desync_correction(i, false)
			end
		end
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

local function autoduck(cmd)
	if not autoduck_return then
		local duck_amount = entitylist.get_local_player():get_prop_float(m_flDuckAmount)
		if duck_amount < lua_re_autoduck_limit:get_value() then
			autoduck_return = true
		end
		local last_shot = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon"))):get_prop_float(m_fLastShotTime)
		if last_shot > autoduck_last_shot then
			autoduck_last_shot = last_shot
			autoduck_return = true
		end
	end
	if not lua_re_autoduck:is_active() then
		autoduck_return = false
	end
	if autoduck_return then
		if bit32.band(cmd.buttons, 4) ~= 0 then
			autoduck_return = false
		end
		cmd.buttons = bit32.bor(cmd.buttons, 4194304)
		cmd.buttons = bit32.bor(cmd.buttons, 4)
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
	if lua_re_jumpscout:is_active() and is_scout() then
		if not jumpscout then
			jumpscout_as = ui.get_check_box("misc_autostrafer"):get_value()
			jumpscout_hc = ui.get_slider_int("rage_scout_hitchance"):get_value()
			ui.get_check_box("misc_autostrafer"):set_value(false)
			ui.get_slider_int("rage_scout_hitchance"):set_value(lua_re_jumpscout_hc:get_value())
			jumpscout = true
		end
		if entitylist.get_local_player():get_prop_vector(m_vecVelocity).z ~= 0.0 then
			jumpscout_injump = true
		else
			jumpscout_injump = false
		end
	else
		if jumpscout then
			ui.get_check_box("misc_autostrafer"):set_value(jumpscout_as)
			ui.get_slider_int("rage_scout_hitchance"):set_value(jumpscout_hc)
			jumpscout = false
			jumpscout_injump = false
		end
	end
end


local function on_create_move(cmd)
	essentials(cmd)
	autopeek(cmd)
	autoduck(cmd)
	switch_exploit()
	backtracking()
	jump_scout()
end

function on_shot_fired(shot_info) 
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
	ui.get_check_box("misc_autostrafer"):set_value(jumpscout_as)
	ui.get_slider_int("rage_scout_hitchance"):set_value(jumpscout_hc)
end

client.register_callback("unload", on_unload)
client.register_callback("paint", on_paint)
client.register_callback("fire_game_event", on_events)
client.register_callback("shot_fired", on_shot_fired)
client.register_callback("create_move", on_create_move)