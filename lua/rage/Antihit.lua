local lua_ah_enabled = ui.add_check_box("Enable", "lua_ah_enabled", false)
local lua_ah_pitch = ui.add_combo_box("Pitch", "lua_ah_pitch", { "None", "Down", "Zero", "Up", "Custom" }, 0)
local lua_ah_pitch_custom = ui.add_slider_int("Pitch value", "lua_ah_pitch_custom", -89.0, 89.0, 0.0)
local lua_ah_yaw = ui.add_slider_int("Yaw", "lua_ah_yaw", -180.0, 180.0, 0.0)

local lua_ah_manual_left = ui.add_key_bind("Manual left", "lua_ah_manual_left", 0, 1)
local lua_ah_manual_back = ui.add_key_bind("Manual backward", "lua_ah_manual_back", 0, 1)
local lua_ah_manual_right = ui.add_key_bind("Manual right", "lua_ah_manual_right", 0, 1)

local lua_ah_jitter_yaw = ui.add_slider_float("Jitter", "lua_ah_jitter_yaw", 0.0, 60.0, 0.0)
local lua_ah_spin_speed = ui.add_slider_float("Spin speed", "lua_ah_spin_speed", 0.0, 60.0, 0.0)

local lua_ah_at_targets = ui.add_key_bind("At targets", "lua_ah_at_targets", 0, 1)
local lua_ah_at_targets_mode = ui.add_combo_box("At targets type", "lua_ah_at_targets_mode", { "Crosshair", "Distance" }, 0)
local lua_ah_at_targets_dormant = ui.add_slider_float("At targets in dormant", "lua_ah_at_targets_dormant", 0.0, 10.0, 0.5)

local lua_ah_desync = ui.add_combo_box("Desync type", "lua_ah_desync", { "None", "Static", "Lowdelta", "Extended", "Breaker", "Custom" }, 0)

local lua_ah_desync_custom_yaw = ui.add_slider_int("Desync length", "lua_ah_desync_custom_yaw", 0.0, 120.0, 0.0)
local lua_ah_desync_custom_yaw_inverted = ui.add_slider_int("Inverted desync length", "lua_ah_desync_custom_yaw_inverted", 0.0, 120.0, 0.0)

local lua_ah_flip_bind = ui.add_key_bind("Switch desync side", "lua_ah_flip_bind", 0, 2)
local lua_ah_flip_antibrute = ui.add_check_box("Anti bruteforce", "lua_ah_flip_antibrute", false)
local lua_ah_desync_jitter = ui.add_check_box("Desync jitter", "lua_ah_desync_jitter", false)
local lua_ah_legiaa_bind = ui.add_key_bind("Legit AA", "lua_ah_legiaa_bind", 0, 1)

local lua_ah_alternative_desync = ui.add_combo_box("Alternative desync", "lua_ah_alternative_desync", { "None", "Anti bruteforce", "Lowdelta", "Jitter" }, 0)
local lua_ah_desync_alternative_desync_triggers = ui.add_multi_combo_box("Alternative desync triggers", "lua_ah_desync_alternative_desync_triggers", { "In move", "In slowwalk", "On exploit" }, { false, false ,false })

local lua_ah_fakelags_min = ui.add_slider_int("Fakelags min", "lua_ah_fakelags_min", 0, 14, 0)
local lua_ah_fakelags_max = ui.add_slider_int("Fakelags max", "lua_ah_fakelags_max", 0, 14, 0)

local lua_ah_fakelags_on_peek = ui.add_slider_int("Fakelags on peek", "lua_ah_fakelags_on_peek", 0, 14, 0)

local lua_ah_slowwalk_override = ui.add_check_box("Slowwalk override", "lua_ah_slowwalk_override", false)
local lua_ah_slowwalk_min = ui.add_slider_int("Slowwalk speed min", "lua_ah_slowwalk_min", 0, 100, 0)
local lua_ah_slowwalk_max = ui.add_slider_int("Slowwalk speed max", "lua_ah_slowwalk_max", 0, 100, 0)

local lua_ah_fakelags_adaptive = ui.add_check_box("Adaptive fakelags", "lua_ah_fakelags_adaptive", false)

local lua_ah_rindicator = ui.add_check_box("Real indicator", "lua_ah_rindicator", false)
local lua_ah_rindicator_color = ui.add_color_edit("Real indicator color", "lua_ah_rindicator_color", true, color_t.new(255, 255, 255, 255))

local lua_ah_dindicator = ui.add_check_box("Fake indicator", "lua_ah_dindicator", false)
local lua_ah_dindicator_color = ui.add_color_edit("Fake indicator color", "lua_ah_dindicator_color", true, color_t.new(255, 255, 255, 255))

local lua_ah_debug = false

local using_alternative_desync = false
local desync_flipped = false
local jitter_state = -1

local last_command_number = -1
local last_tick_count = -1

local recharged = false

local player_shots = {}
for i = 0, 64 do player_shots[i] = 0.0 end

local players_dormant = {}
for i = 0, 64 do players_dormant[i] = 0.0 end

local m_vecOrigin = se.get_netvar("DT_BaseEntity", "m_vecOrigin")
local m_flDuckSpeed = se.get_netvar("DT_BasePlayer", "m_flDuckSpeed");
local m_flDuckAmount = se.get_netvar("DT_BasePlayer", "m_flDuckAmount");
local m_vecVelocity = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]");
local m_bIsValveDS = se.get_netvar("DT_CSGameRulesProxy", "m_bIsValveDS")
local m_hActiveWeapon = se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")
local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")
local m_fFlags = se.get_netvar("DT_BasePlayer", "m_fFlags")
local m_flDuckAmount = se.get_netvar("DT_BasePlayer", "m_flDuckAmount")
local m_vecViewOffset = se.get_netvar("DT_BasePlayer", "m_vecViewOffset[0]")
local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")

local sv_maxspeed = se.get_convar("sv_maxspeed")

local antihit_extra_fakeduck_bind = ui.get_key_bind("antihit_extra_fakeduck_bind")

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

function hasbit(x, p) return x % (p + p) >= p end

local function server_time()
	return (entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BasePlayer", "m_nTickBase")) * globalvars.get_interval_per_tick())
end

local function get_weapon_ammo(player)
	return entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon"))):get_prop_int(se.get_netvar("DT_BaseCombatWeapon", "m_iClip1"))
end
local function get_weapon_recharge(weapon)
	in_recharge = ffi.cast("uint32_t*", (client.find_pattern("client.dll", "C6 87 ? ? ? ? ? 8B 06 8B CE FF 90") + 2))
	is_recharging = ffi.cast("bool*", weapon:get_address() + in_recharge[0])
	return is_recharging[0]
end
local function is_nade()
    local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
	if weapon_data(weapon).type == 0 then
		return true
	end
	return false
end
local function is_knife()
	local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))
	if weapon_data(weapon).type == 1 then
		return true
	end
	return false
end
local function is_ready_to_fire(cmd)
	local isknife = is_knife()
	if hasbit(cmd.buttons, 1) or (hasbit(cmd.buttons, 2048) and isknife) then 
		if isknife then return true end
		--balls
		return true
	end
	return false
end
function is_throwing()
    local active_weapon_throw_time = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon"))):get_prop_float(se.get_netvar("DT_BaseCSGrenade", "m_fThrowTime"))
    if active_weapon_throw_time > 0.1 then 
        return true
    end
    return false
end

local function micro_move(cmd)
	local micro_move = 1.10
	
	if (entitylist.get_local_player():get_prop_float(m_flDuckAmount) > 0.1) then
	  micro_move = micro_move * 3.0
	end
	
	if cmd.command_number % 2 == 0 then
	  micro_move = -micro_move
	end
	
	cmd.sidemove = cmd.sidemove + micro_move
end

local lower_body_yaw_update_time = 0.0
local lower_body_yaw_force_choke = false
local function break_lby(cmd, lby)
	if entitylist.get_local_player():get_prop_vector(m_vecVelocity):length() > 4.0 then
		return
	end
	if globalvars.get_current_time() >= lower_body_yaw_update_time then
		cmd.send_packet = false
		cmd.viewangles.yaw = cmd.viewangles.yaw + lby
		lower_body_yaw_force_choke = true
		lower_body_yaw_update_time = globalvars.get_current_time() + 0.22
		micro_move(cmd)
		return
	end
	
	if lower_body_yaw_force_choke then
		lower_body_yaw_force_choke = false
		cmd.send_packet = false
		return
	end
	
	if lower_body_yaw_force_choke then
		return
	end
end

local function dist_3d(a, b)
	return vec3_t.new(a.x - b.x, a.y - b.y, a.z - b.z):length()
end

local function angle_vectors(angles)
  local cp, sp = math.cos(angles.pitch * 0.017453292519), math.sin(angles.pitch * 0.017453292519)
  local cy, sy = math.cos(angles.yaw * 0.017453292519), math.sin(angles.yaw * 0.017453292519)
  local cr, sr = math.cos(angles.roll * 0.017453292519), math.sin(angles.roll * 0.017453292519)
  
  local forward = vec3_t.new(0, 0, 0)
  
  forward.x = cp * cy
  forward.y = cp * sy
  forward.z = -sp
  
  return forward
end

local function calc_angle(from, to)
	local vec = vec3_t.new(to.x - from.x, to.y - from.y, to.z - from.z)
	local hyp = math.sqrt(vec.x*vec.x+vec.y*vec.y+vec.z*vec.z)
	
	local pitch = -math.asin(vec.z / hyp) * 57.29578
	if pitch > 89.0 then pitch = 89.0 end
	if pitch < -89.0 then pitch = -89.0 end
	
	local yaw = math.atan2(vec.y, vec.x) * 57.29578
	while yaw < -180.0 do angle = angle + 360.0 end
	while yaw > 180.0 do angle = angle - 360.0 end
	
	return angle_t.new(pitch, yaw, 0)
end

local function get_projection(a, b, c) -- epic applied math student moment
	local length = dist_3d(b, c)
	local d = vec3_t.new(c.x - b.x, c.y - b.y, c.z - b.z)
	d = vec3_t.new(d.x / length, d.y / length, d.z / length)
	local v = vec3_t.new(a.x - b.x, a.y - b.y, a.z - b.z)
	local t = v.x * d.x + v.y * d.y + v.z * d.z
	local p = vec3_t.new(d.x * t, d.y * t, d.z * t)
	return vec3_t.new(b.x + p.x, b.y + p.y, b.z + p.z)
end

local function best_angle(cmd)
	local lowest_distance = 2147483647
	local lowest_fov = 2147483647	
	local best_player = nil
	local local_player = entitylist.get_local_player()
	if not local_player then return -1 end
	for i = 0, 64 do
	local current_player = entitylist.get_entity_by_index(i)
		if current_player ~= nil and current_player ~= entitylist.get_local_player() and current_player:get_prop_int(m_iTeamNum) ~= local_player:get_prop_int(m_iTeamNum) and not current_player:is_dormant() then players_dormant[i] = globalvars.get_current_time() end
		if current_player ~= nil and current_player ~= entitylist.get_local_player() and current_player:get_prop_int(m_iTeamNum) ~= local_player:get_prop_int(m_iTeamNum) and globalvars.get_current_time() - players_dormant[i] < lua_ah_at_targets_dormant:get_value() then
			if not current_player or not current_player:is_alive() and not current_player:is_dormant() then
				at_targets = false
				goto continue
			end
			if lua_ah_at_targets_mode:get_value() == 0 then
				local current_angle = calc_angle(local_player:get_prop_vector(m_vecOrigin), current_player:get_prop_vector(m_vecOrigin))
				local current_fov = dist_3d(angle_vectors(current_angle), angle_vectors(engine.get_view_angles()))
				if current_fov < lowest_fov then
					lowest_fov = current_fov
					best_player = current_player
				end
			else
				local current_distance = dist_3d(local_player:get_prop_vector(m_vecOrigin), current_player:get_prop_vector(m_vecOrigin))
				if current_distance < lowest_distance then
					lowest_distance = current_distance
					best_player = current_player
				end
			end
			::continue::
		end
	end
	if best_player == nil then
		return engine.get_view_angles()
	end
	return calc_angle(local_player:get_prop_vector(m_vecOrigin), best_player:get_prop_vector(m_vecOrigin))
end

local manual_side = 0

local function get_manual_side() -- waparabka.technologies
	if client.is_key_clicked(lua_ah_manual_left:get_key()) then
        if manual_side == 1 then 
			manual_side = 0 
			return manual_side
		end
        manual_side = 1
    end
	if client.is_key_clicked(lua_ah_manual_back:get_key()) then
        if manual_side == 2 then 
			manual_side = 0 
			return manual_side
		end
        manual_side = 2
    end
	if client.is_key_clicked(lua_ah_manual_right:get_key()) then
        if manual_side == 3 then 
			manual_side = 0 
			return manual_side
		end
        manual_side = 3
    end
	return manual_side
end

local player_vtable = ffi.cast("int*", client.find_pattern("client.dll", "55 8B EC 83 E4 F8 83 EC 18 56 57 8B F9 89 7C 24 0C") + 0x47)[0]
local get_abs_origin = ffi.cast("float*(__thiscall*)(int)", ffi.cast("int*", player_vtable + 0x28)[0])

local function get_eyes_pos()
	local local_player = entitylist.get_local_player()
	if local_player == nil or not local_player:is_alive() then 
        return 0
    end
	local abs_origin = get_abs_origin(local_player:get_address())
	local view_offset = local_player:get_prop_vector(m_vecViewOffset)
	return vec3_t.new(abs_origin[0] + view_offset.x, abs_origin[1] + view_offset.y, abs_origin[2] + view_offset.z)
end

local function find_closest_point_at_angle(angle)
	local local_player = entitylist.get_local_player()
    if local_player == nil or not local_player:is_alive() then 
        return 
    end

    local trace_end = angle_vectors(angle)

    local abs_origin = get_abs_origin(local_player:get_address())	
    local view_offset = local_player:get_prop_vector(m_vecViewOffset)
    local trace_start = vec3_t.new(abs_origin[0] + view_offset.x, abs_origin[1] + view_offset.y, abs_origin[2] + view_offset.z)

    trace_end.x = trace_start.x + trace_end.x * 8192.0
    trace_end.y = trace_start.y + trace_end.y * 8192.0
    trace_end.z = trace_start.z + trace_end.z * 8192.0

    local trace_out = trace.line(engine.get_local_player(), 0x46004003, trace_start, trace_end)	
	return dist_from_camera(trace_out.endpos)
end

local function can_hit_directly(pos, ent) -- nixer wall penetration calculation when :(
	local trace_out1 = trace.line(engine.get_local_player(), 0x46004003, pos, ent:get_player_hitbox_pos(8))
	local trace_out2 = trace.line(engine.get_local_player(), 0x46004003, pos, ent:get_player_hitbox_pos(0))
	return (trace_out1.hit_entity_index == ent:get_index()) or (trace_out2.hit_entity_index == ent:get_index())
end

local function in_peek(pred_ticks) -- tatarstan technologies
	local lp = entitylist.get_local_player()
	local pos = get_eyes_pos()
	local predict = lp:get_prop_vector(m_vecVelocity)
	local tick_time = globalvars.get_interval_per_tick() * pred_ticks
	local pos_predicted = vec3_t.new(pos.x + predict.x * tick_time, pos.y + predict.y * tick_time, pos.z + predict.z * tick_time)
	local player_team = lp:get_prop_int(m_iTeamNum)
	for i = 1, 64 do
		local entity = entitylist.get_entity_by_index(i)
		if entity ~= nil and player_team ~= entity:get_prop_int(m_iTeamNum) and entity:get_prop_int(m_iHealth) > 0 then
			if can_hit_directly(pos, entity) then return true end
			if can_hit_directly(pos_predicted, entity) then return true end
		end
	end
	if pred_ticks > 1 then
		return in_peek(pred_ticks - 1)
	end
	return false
end

local desync_flipped_held = false
local cmd_yaw = 0.0
local cmd_desync = 0.0

local function get_centered_cpos(offset, angle)
	local x = engine.get_screen_size().x / 2 + math.sin(angle) * offset
	local y = engine.get_screen_size().y / 2 + math.cos(angle) * offset
	return vec2_t.new(x, y)
end

local function draw_indicator(angle, color)
	local yaw = 3.1415926535898 - angle * 0.01745329251994
	local points = 
	{
		get_centered_cpos(40, yaw + 0.39269908169865),
		get_centered_cpos(60, yaw),
		get_centered_cpos(40, yaw - 0.39269908169865)
	}
	renderer.filled_polygon(points, color)
end

local function on_paint()
	manual_side = get_manual_side()
	if lua_ah_desync:get_value() == 5 then
		lua_ah_desync_custom_yaw:set_visible(true)
		lua_ah_desync_custom_yaw_inverted:set_visible(true)
	else
		lua_ah_desync_custom_yaw:set_visible(false)
		lua_ah_desync_custom_yaw_inverted:set_visible(false)
	end
	
	if lua_ah_slowwalk_override:get_value() then
		lua_ah_slowwalk_min:set_visible(true)
		lua_ah_slowwalk_max:set_visible(true)
	else
		lua_ah_slowwalk_min:set_visible(false)
		lua_ah_slowwalk_max:set_visible(false)
	end

	if lua_ah_fakelags_min:get_value() > lua_ah_fakelags_max:get_value() then
		lua_ah_fakelags_min:set_value(lua_ah_fakelags_max:get_value())
	end

	if lua_ah_pitch:get_value() == 4 then
		lua_ah_pitch_custom:set_visible(true)
	else
		lua_ah_pitch_custom:set_visible(false)
	end

	if not lua_ah_enabled:get_value() then return end
	
	ui.get_check_box("antihit_fakelag_enable"):set_value(false)
	ui.get_check_box("antihit_antiaim_enable"):set_value(false)
	
	local local_player = entitylist.get_local_player()
	if local_player ~= nil and local_player:is_alive() then
		if lua_ah_rindicator:get_value() then
			draw_indicator(cmd_yaw, lua_ah_rindicator_color:get_value())
		end
		if lua_ah_dindicator:get_value() then
			draw_indicator(cmd_yaw - cmd_desync, lua_ah_dindicator_color:get_value())
		end
	end
end

local freezetime = false

client.register_callback("bullet_impact", function(event)
	local entity_id = engine.get_player_for_user_id( event:get_int("userid", 0) )
	if entity_id == engine.get_local_player() then return end
	
	local entity = entitylist.get_entity_by_index(entity_id)
	local from = entity:get_player_hitbox_pos(0)
	local to = vec3_t.new(event:get_float("x", 0.0), event:get_float("y", 0.0), event:get_float("z", 0.0))
	local head = get_eyes_pos()
	
	local closest_point = get_projection(head, from, to)
	local dist = dist_3d(closest_point, head)
	if dist < 45 and dist_3d(from, to) >= dist_3d(from, head) - 10.0 and player_shots[engine.get_player_for_user_id(event:get_int("userid", 0))] + 0.05 < globalvars.get_current_time() then
		if lua_ah_flip_antibrute:get_value() or (lua_ah_alternative_desync:get_value() == 1 and using_alternative_desync) then 
			desync_flipped = not desync_flipped
		end	
	end
	player_shots[engine.get_player_for_user_id(event:get_int("userid", 0))] = globalvars.get_current_time()
end)

client.register_callback("round_start", function()
	lower_body_yaw_update_time = 0.22
end)

client.register_callback("round_prestart", function()
	freezetime = true
end)

client.register_callback("round_freeze_end", function()
	for i = 0, 64 do players_dormant[i] = 0.0 end
	freezetime = false
end)

client.register_callback("player_death", function(event)
	local local_player_userid = engine.get_player_info(engine.get_local_player()).user_id
	local event_userid = event:get_int("userid", 0)
	
	if local_player_userid == event_userid then
		last_command_number = -1
		last_tick_count = -1
	end
end)

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

local function get_animstate()
	local entity = entitylist.get_local_player()
    return ffi.cast("struct Animstate_t**", entity:get_address() + 0x9960)[0]
end

local function clamp_yaw(yaw)
	while yaw < -180.0 do yaw = yaw + 360.0 end
	while yaw > 180.0 do yaw = yaw - 360.0 end
	return yaw
end

local function get_current_desync(mod_yaw)
	local animstate = get_animstate()
	return math.abs(mod_yaw - math.abs(clamp_yaw(engine.get_view_angles().yaw - animstate.m_flGoalFeetYaw))) -- CO3DAT3JIb JS REZOLVER
end

local peeked = false

local lag_amount = 0
local spin = 0

local function on_create_move(cmd)
	if not lua_ah_enabled:get_value() then return end
	cmd_yaw = 0
	if freezetime then return end
	local local_player = entitylist.get_local_player()
	if bit.band(local_player:get_prop_int(m_fFlags), 64) ~= 0 then return end
	local velocity = local_player:get_prop_vector(m_vecVelocity)
	
	using_alternative_desync = false
	if lua_ah_desync_alternative_desync_triggers:get_value(0) and velocity:length() > 130 then 
		using_alternative_desync = true
	end
	if lua_ah_desync_alternative_desync_triggers:get_value(1) and velocity:length() > 10 and velocity:length() <= 130 then 
		using_alternative_desync = true
	end
	if lua_ah_desync_alternative_desync_triggers:get_value(2) and ui.get_combo_box("rage_active_exploit"):get_value() ~= 0 and ui.get_key_bind("rage_active_exploit_bind"):is_active() then 
		using_alternative_desync = true
	end
	
	if cmd.command_number - last_command_number > 1 and last_command_number ~= -1 then
		recharged = false
	end
	last_command_number = cmd.command_number
	
	if cmd.tick_count - last_tick_count > 1 and last_tick_count ~= -1 then
		recharged = true
	end
	last_tick_count = cmd.tick_count
	
	if lag_amount == 0 then
		if lua_ah_fakelags_on_peek:get_value() ~= 0 and in_peek(lua_ah_fakelags_on_peek:get_value()) then
			if not peeked then
				lag_amount = lua_ah_fakelags_on_peek:get_value()
				peeked = true
			else
				lag_amount = math.random( lua_ah_fakelags_min:get_value(), lua_ah_fakelags_max:get_value() )
			end
		else	
			lag_amount = math.random( lua_ah_fakelags_min:get_value(), lua_ah_fakelags_max:get_value() )
			peeked = false
		end
	end
	
	local fakelags = lag_amount
	if fakelags > 14 then fakelags = 14 end
	if lua_ah_fakelags_adaptive:get_value() then fakelags = fakelags * ( velocity:length() / sv_maxspeed:get_int() ) end
	if fakelags < 2 and lua_ah_desync:get_value() ~= 0 then
		fakelags = 2
	end
	if fakelags > 2 and ui.get_combo_box("rage_active_exploit"):get_value() ~= 0 and ui.get_key_bind("rage_active_exploit_bind"):is_active() and recharged then
		fakelags = 1
	end
	
	local active_weapon_handle = local_player:get_prop_int(m_hActiveWeapon)
	local active_weapon = entitylist.get_entity_from_handle(active_weapon_handle)
	local move_type = local_player:get_prop_int(se.get_netvar("DT_BaseEntity", "m_nRenderMode") + 1) 
	if move_type == 0 or move_type == 8 or move_type == 9 then return end
	if is_nade() and is_throwing() and not is_knife() then return end
	if is_ready_to_fire(cmd) then return end
    if not lua_ah_legiaa_bind:is_active() and hasbit(cmd.buttons, 32) then return end

	if not antihit_extra_fakeduck_bind:is_active() then
		if fakelags <= clientstate.get_choked_commands() then
			lag_amount = 0
			cmd.send_packet = true
		else
			cmd.send_packet = false
		end
	end
	
	local pitch_type = lua_ah_pitch:get_value()
	if pitch_type == 0 then
	elseif pitch_type == 1 then
		cmd.viewangles.pitch = 89.0
	elseif pitch_type == 2 then
		cmd.viewangles.pitch = 0.0
	elseif pitch_type == 3 then
		cmd.viewangles.pitch = -89.0
	elseif pitch_type == 4 then
		cmd.viewangles.pitch = lua_ah_pitch_custom:get_value()
	end
	
	cmd.viewangles.yaw = engine.get_view_angles().yaw - lua_ah_yaw:get_value()
	if lua_ah_at_targets:is_active() then
		cmd.viewangles.yaw = best_angle(cmd).yaw - lua_ah_yaw:get_value()
	end
	
	if manual_side == 1 then cmd.viewangles.yaw = engine.get_view_angles().yaw - 270.0 end
	if manual_side == 2 then cmd.viewangles.yaw = engine.get_view_angles().yaw - 180.0 end
	if manual_side == 3 then cmd.viewangles.yaw = engine.get_view_angles().yaw - 90.0 end
	
	if lua_ah_spin_speed:get_value() ~= 0 then
		spin = spin + lua_ah_spin_speed:get_value()
		if spin > 360 then spin = 0 end
		cmd.viewangles.yaw = cmd.viewangles.yaw + spin
	end
	
	cmd_yaw = engine.get_view_angles().yaw - cmd.viewangles.yaw
	
	cmd.viewangles.yaw = cmd.viewangles.yaw - lua_ah_jitter_yaw:get_value() * jitter_state
	if cmd.send_packet then
		jitter_state = jitter_state * -1
		if lua_ah_desync_jitter:get_value() or (lua_ah_alternative_desync:get_value() == 3 and using_alternative_desync) then
			desync_flipped = not desync_flipped
		end
	end

	if lua_ah_slowwalk_override:get_value() then 
		ui.get_slider_int("antihit_extra_slowwalk_speed"):set_value( math.random( lua_ah_slowwalk_min:get_value(), lua_ah_slowwalk_max:get_value() ) )
	end

	if lua_ah_legiaa_bind:is_active() then 
		cmd_yaw = 0
		cmd.viewangles = engine.get_view_angles() 
	end
	
	local desync_type = lua_ah_desync:get_value()
	
	if using_alternative_desync then
		desync_type = lua_ah_alternative_desync:get_value()
		if lua_ah_alternative_desync:get_value() == 3 then
			desync_type = 1
		end
	end
	
	local mod_yaw = engine.get_view_angles().yaw - cmd.viewangles.yaw
	
	local desync_switched = desync_flipped
	if lua_ah_flip_bind:is_active() then
		desync_switched = not desync_switched
	end
	
	-- welcome to the cum zone
	local desync_value = 0.0
	if desync_type == 1 or desync_type == 2 then
		desync_value = 58.0
		micro_move(cmd)
		if desync_switched then
			desync_value = -desync_value
		end
		if get_current_desync(mod_yaw) < math.abs(desync_value) then
			desync_value = (desync_value / math.abs(desync_value)) * 120
		end
		if desync_type == 2 then desync_value = math.random(20.0, 30.0) end
		if not cmd.send_packet then
		  cmd.viewangles.yaw = cmd.viewangles.yaw - desync_value
		end
	elseif desync_type == 3 or desync_type == 4 then
		desync_value = 120.0
		if desync_type == 4 then 
			desync_value = 58.0
		end
		if desync_switched then
			desync_value = -desync_value
		end
		break_lby(cmd, 180.0)
		if not cmd.send_packet then
		  cmd.viewangles.yaw = cmd.viewangles.yaw - desync_value
		end
	elseif desync_type == 0 then
		desync_value = 0.0
	else
		desync_value = 0
		if not desync_switched then
			desync_value = lua_ah_desync_custom_yaw:get_value()
		else
			desync_value = -lua_ah_desync_custom_yaw_inverted:get_value()
		end
		if math.abs(desync_value) > 58.0 then
			break_lby(cmd, (111.0 + math.abs(desync_value)) * (desync_value / math.abs(desync_value)))
		elseif math.abs(desync_value) == 120.0 then
			break_lby(cmd, 180.0)
		elseif math.abs(desync_value) == 58.0 then
			if get_current_desync(mod_yaw) < math.abs(desync_value) then
				desync_value = (desync_value / math.abs(desync_value)) * 120
			end
			micro_move(cmd)
		else
			micro_move(cmd)
		end	
		if not cmd.send_packet then
			cmd.viewangles.yaw = cmd.viewangles.yaw - desync_value
		end
	end
	cmd_desync = (desync_value / math.abs(desync_value)) * 90
end

client.register_callback("paint", on_paint)
client.register_callback("create_move", on_create_move)