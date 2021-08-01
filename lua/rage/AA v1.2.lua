require("bit32")
local choke_int_slider = ui.add_slider_int("Choke", "choke_int", 1, 14, 1)
local send_int_slider = ui.add_slider_int("Send", "send_int", 1, 14, 1)
local lby_combo = ui.add_combo_box("Body yaw type", "lby_type", { "Eye yaw", "Opposite", "Sway"}, 0)
local lby_slider = ui.add_slider_int("LBY Delta", "lby_val", 0, 60, 0)
local des_slider = ui.add_slider_int("Desync Delta", "des_val", 0, 60, 0)
local inverter_bind = ui.add_key_bind("Side Inverter", "invert_side", 0, 2)
local lowdelta_sw_checkbox = ui.add_check_box("Low Delta On Slow Walk", "ld_on_sw", false)
local e_legit_checkbox = ui.add_check_box("Base Yaw On Use", "e_legit_aa", false)
local add_jitter_slider = ui.add_slider_int("Jitter Adding", "jitter_int", -180, 180, 0)

local cnt = 0
local choke = 0
local send = 0
local ebind = ui.get_key_bind("rage_active_exploit_bind")
local ebox = ui.get_combo_box("rage_active_exploit")
local loop = false
local break_lby = false
local force_choke = false
local force_send = true
local lby_update = 0.0
local curtime = 0.0
local lby_delta = 0
local loop1 = false
local desync_delta = 0
local side = 1
local lby_time = 0.0
local lby_delta1 = 0
local lby_update1 = 0.0
local lby_loop = 0
local pitch1 = 0
local yaw1 = 0
local des1 = 0
local lby1 = 0
local lby_sw1 = 0

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

weapon_data_call = ffi.cast("int*(__thiscall*)(void*)", client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 53 8B D9 56 57 8D 8B ? ? ? ? 85 C9 75 04"));

function weapon_data( weapon )
    return ffi.cast("struct WeaponInfo_t*", weapon_data_call(ffi.cast("void*", weapon:get_address())));
end

function is_throwing(  )
    local active_weapon_throw_time = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon"))):get_prop_float(se.get_netvar("DT_BaseCSGrenade", "m_fThrowTime"))

    if active_weapon_throw_time > 0.1 then 
        return true
    end 
    
    return false
end

function is_nade(  )

    local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))

    if weapon_data(weapon).type == 0 then
        return true
    end

    return false

end

function is_knife(  )
    
    local weapon = entitylist.get_entity_from_handle(entitylist.get_local_player():get_prop_int(se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon")))

    if weapon_data(weapon).type == 1 then
        return true
    end

    return false

end

local function hasbit(x, p) return x % (p + p) >= p end

local function checks(pCmd)

    local netMoveType = se.get_netvar("DT_BaseEntity", "m_nRenderMode") + 1
    local move_type = entitylist.get_local_player():get_prop_int(netMoveType)

    if move_type == 8 or move_type == 9 then
        return true
    end

    if hasbit(pCmd.buttons, bit32.lshift(1, 0)) then
        return true
    end

    if hasbit(pCmd.buttons, bit32.lshift(1, 5)) and not e_legit_checkbox:get_value() then
        return true
    end

    if is_nade( ) and is_throwing( ) and not is_knife( ) then
        return true
    end
end

local function sidemoves(pCmd)
    if math.abs(pCmd.sidemove) < 4 then
        if pCmd.command_number % 2 == 1 then
            pCmd.sidemove = client.is_key_pressed(17) and 3.01 or 1.01 + pCmd.sidemove
        else
            pCmd.sidemove = client.is_key_pressed(17) and -3.01 or -1.01 + pCmd.sidemove 
        end
    end
end


local function do_lby(pCmd)
    if checks(pCmd) then return end

    side = inverter_bind:is_active() and 1 or -1

    curtime = globalvars.get_current_time()

    if e_legit_checkbox:get_value() and hasbit(pCmd.buttons, bit32.lshift(1, 5)) then
        if lby_combo:get_value() == 1 then
            lby1 = 180
        elseif lby_combo:get_value() == 2 then    
            lby1 = 140
        end    
        lby_sw1 = 80
    else
        lby1 = -120 - lby_slider:get_value()
        lby_sw1 = 20
    end

    if lby_combo:get_value() == 1 then
        lby_delta1 = lby1
    elseif lby_combo:get_value() == 2 then
        if curtime > lby_update1 then
            lby_update1 = curtime + 1.1

            if lby_loop then
                lby_delta1 = lby1
                lby_loop = false
            else
                lby_loop = true
                lby_delta1 = -lby_sw1
            end
        end
    end               
            
    lby_delta = -side * lby_delta1

    if ebind:is_active() and ebox:get_value() > 0 then
        lby_time = 1.1
    else
        lby_time = 0.22
    end
            
    if curtime > lby_update and lby_combo:get_value() > 0 then
        lby_update = curtime + lby_time
        break_lby = true
        pCmd.send_packet = false
        force_choke = true
        pCmd.viewangles.yaw = pCmd.viewangles.yaw + lby_delta
        sidemoves(pCmd)
        return
    else
        if lby_combo:get_value() == 0 then
            sidemoves(pCmd)
        end    
        break_lby = false
    end
end

local function fakelags(pCmd)
    if clientstate.get_choked_commands() > 12 then return end

    if ebind:is_active() and ebox:get_value() > 0 then
        choke = 1
        send = choke + 2
    else
        choke = choke_int_slider:get_value()
        send = choke + send_int_slider:get_value()
    end

    cnt = cnt + 1

    if cnt > 0 and cnt <= choke then
        force_choke = true
        force_send = false
    elseif cnt > choke and cnt <= send then
        force_send = break_lby and false or true
        force_choke = break_lby and true or false
    elseif cnt > send then
        cnt = 0
    end

    if force_choke or break_lby then
        pCmd.send_packet = false
    elseif force_send then
        pCmd.send_packet = true
    end                
end

local function aa(pCmd)
	if checks(pCmd) then return end

    if ebind:is_active() and ebox:get_value() > 0 then
        sidemoves(pCmd)
    else 
        do_lby(pCmd)
    end

    side = inverter_bind:is_active() and 1 or -1

    if clientstate.get_choked_commands() == 0 then
    	if loop then
    		loop = false
    		adding = add_jitter_slider:get_value()
    	else
    		loop = true
    		adding = -add_jitter_slider:get_value()
    	end
    end  

    if e_legit_checkbox:get_value() and hasbit(pCmd.buttons, bit32.lshift(1, 5)) then
        pitch1 = 0
        yaw1 = 0
    else
        pitch1 = 89
        yaw1 = 180
    end

    if lowdelta_sw_checkbox:get_value() then
        local sw_bind = ui.get_key_bind("antihit_extra_slowwalk_bind"):is_active()
        desync_delta = sw_bind and 90 or (120 - des_slider:get_value())*side
    else    
        desync_delta = (120 - des_slider:get_value()) * side
    end  
            
    pCmd.viewangles.pitch = pitch1
    if not pCmd.send_packet then
        pCmd.viewangles.yaw = pCmd.viewangles.yaw + desync_delta
    else
        pCmd.viewangles.yaw = pCmd.viewangles.yaw + yaw1 + adding
    end    
end

client.register_callback("create_move", fakelags)
client.register_callback("create_move", aa) 	