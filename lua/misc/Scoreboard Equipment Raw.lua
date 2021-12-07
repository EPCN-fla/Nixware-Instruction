--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
----	   ______   .___  ___.  _______   _______      ___         .______   .______        ______          __   _______   ______ .___________.		----
----	  /  __  \  |   \/   | |   ____| /  _____|    /   \        |   _  \  |   _  \      /  __  \        |  | |   ____| /      ||           |		----
----	 |  |  |  | |  \  /  | |  |__   |  |  __     /  ^  \       |  |_)  | |  |_)  |    |  |  |  |       |  | |  |__   |  ,----'`---|  |----`		----
----	 |  |  |  | |  |\/|  | |   __|  |  | |_ |   /  /_\  \      |   ___/  |      /     |  |  |  | .--.  |  | |   __|  |  |         |  |     		----
----	 |  `--'  | |  |  |  | |  |____ |  |__| |  /  _____  \     |  |      |  |\  \----.|  `--'  | |  `--'  | |  |____ |  `----.    |  |     		----
----	  \______/  |__|  |__| |_______| \______| /__/     \__\    | _|      | _| `._____| \______/   \______/  |_______| \______|    |__|     		----
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    # Author: Fla1337
    # Description: The Scoreboard Equipment Lua For Nixware.
    # Version: 1.0
    # Update Time: 2021.12.7
--]]

local ffi = require("ffi")

--> Vtable Worked With Nixware (Copied from skeet)
-------------------------------- Vtable Start ----------------------------------
function vtable_entry(instance, index, type)
	return ffi.cast(type, (ffi.cast("void***", instance)[0])[index])
end

function vtable_bind(module, interface, index, typestring) -- instance is bound to the callback as an upvalue
	local instance = se.create_interface(module, interface) or error("invalid interface")
	local typeof = ffi.typeof(typestring)

	local fnptr = vtable_entry(instance, index, typeof) or error("invalid vtable")
	return function(...)
		return fnptr(instance, ...)
	end
end

function vtable_thunk(index, typestring) -- instance will be passed to the function at runtime
	local t = ffi.typeof(typestring)
	return function(instance, ...)
		assert(instance ~= nil)
		if instance then
			return vtable_entry(instance, index, t)(instance, ...)
		end
	end
end
--------------------------------- Vtable End -----------------------------------

--> FFI Helper (From Nixware Forum)
------------------------------ FFI Helper Start --------------------------------
local helper = {}
local interface_mt = {}

local iface_ptr = ffi.typeof('void***')
local char_ptr = ffi.typeof('char*')
local nullptr = ffi.new('void*')

function iface_cast(raw)
    return ffi.cast(iface_ptr, raw)
end
function is_valid_ptr(p)
    return p ~= nullptr and p or nil
end
function get_adress_of(raw)
    return ffi.cast('int*', raw)[0]
end
function function_cast(thisptr, index, typedef, tdef)
    local vtblptr = thisptr[0]

    if is_valid_ptr(vtblptr) then
        local fnptr = vtblptr[index]

        if is_valid_ptr(fnptr) then
            local ret = ffi.cast(typedef, fnptr)

            if is_valid_ptr(ret) then
                return ret
            end

            error('function_cast: couldn\'t cast function typedef: ' ..tdef)
        end
        error('function_cast: function pointer is invalid, index might be wrong typedef: ' .. tdef)
    end
    error("function_cast: virtual table pointer is invalid, thisptr might be invalid typedef: " .. tdef)
end

local seen = {}
function check_or_create_typedef(tdef)
    if seen[tdef] then
        return seen[tdef]
    end

    local success, typedef = pcall(ffi.typeof, tdef)
    if not success then
        error("error while creating typedef for " ..  tdef .. "\n\t\t\terror: " .. typedef)
    end
    seen[tdef] = typedef
    return typedef
end

function interface_mt.get_vfunc(self, index, tdef)
    local thisptr = self[1]

    if is_valid_ptr(thisptr) then
        local typedef = check_or_create_typedef(tdef)
        local fn = function_cast(thisptr, index, typedef, tdef)

        if not is_valid_ptr(fn) then
            error("get_vfunc: couldnt cast function (" .. index .. ")")
        end

        return function(...)
            return fn(thisptr, ...)
        end
    end

    error('get_vfunc: thisptr is invalid')
end

function helper.find_interface(module, interface)
    local iface = se.create_interface(module, interface)
    if is_valid_ptr(iface) then
        return setmetatable({iface_cast(iface), module}, {__index = interface_mt})
    else
        error("find_interface: interface pointer is invalid (" .. module .. " | " .. interface .. ")")
    end
end

function helper.get_class(raw, module)
    if is_valid_ptr(raw) then 
        local ptr = iface_cast(raw)
        if is_valid_ptr(ptr) then 
            return setmetatable({ptr, module}, {__index = interface_mt})
        else
            error("get_class: class pointer is invalid")
        end
    end
    error("get_class: argument is nullptr")
end
------------------------------- FFI Helper End ---------------------------------

-----> Panorama
------------------------------ Panorama Start ----------------------------------
ffi.cdef[[
    typedef const char*(__thiscall* get_panel_id_t)(void*, void); // 9
    typedef void*(__thiscall* get_parent_t)(void*); // 25
    typedef void*(__thiscall* set_visible_t)(void*, bool);
]]

panorama_engine = helper.find_interface('panorama.dll', 'PanoramaUIEngine001')
access_ui_engine = panorama_engine:get_vfunc(11, 'void*(__thiscall*)(void*, void)')
--> UIEngine
uiengine = helper.get_class(access_ui_engine())
run_script = uiengine:get_vfunc(113, 'int (__thiscall*)(void*, void*, char const*, char const*, int, int, bool, bool)')
is_valid_panel_ptr = uiengine:get_vfunc(36, 'bool(__thiscall*)(void*, void*)')
get_last_target_panel = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
--> UIPanel
get_panel_id = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
get_parent = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
set_visible = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')

function get_panel_id(panelptr)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[9] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("get_panel_id_t", func)
    return ffi.string(fn(panelptr))
end

function get_parent(panelptr)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[25] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("get_parent_t", func)
    return fn(panelptr)
end

function set_visible(panelptr, state)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[27] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("set_visible_t", func)
    fn(panelptr, state)
end

function get_root(custompanel)
    local itr = get_last_target_panel()

    if itr == nil then return end

    local ret = nil
    local panelptr = nil

    while itr ~= nil and is_valid_panel_ptr(itr) do
        panelptr = ffi.cast('void***', itr)

        if custompanel and get_panel_id(panelptr) == custompanel then
            ret = itr
            break
        elseif get_panel_id(panelptr) == 'CSGOMainMenu' then
            ret = itr
            break
        elseif get_panel_id(panelptr) == 'CSGOHud' then
            ret = itr
            break
        end

        itr = get_parent(panelptr) or error('Couldn\'t get parent..', 2)
    end

    return ret
end

local rootpanel = get_root()
function eval(code, custompanel, customfile)
    if custompanel then
        rootpanel = custompanel
    else
        if rootpanel == nil then
            rootpanel = get_root(custompanel) or error('Couldn\'t get parent..', 2)
        end
    end

    local file = customfile or 'panorama/layout/base_mainmenu.xml'

    return run_script(rootpanel, ffi.string(code), file, 8, 10, false, false)
end

function get_child(name)
    return get_root(name) or error('Couldn\'t get parent..', 2)
end

function change_visibility(ptr, state)
    local panelptr = ffi.cast('void***', ptr)

    if is_valid_panel_ptr(ptr) then
        return set_visible(panelptr, state)
    else
        error('Invalid panel', 2)
    end
end

function get_child_name(ptr)
    local panelptr = ffi.cast('void***', ptr)

    if is_valid_panel_ptr(ptr) then
        return ffi.string(get_panel_id(panelptr))
    else
        error('Invalid panel', 2)
    end
end

--> Callback
local panorama = {
	loadstring = eval,
	get_child = get_child,
    get_child_name = get_child_name,
    set_visible = change_visibility
}
------------------------------- Panorama End -----------------------------------

-----> CS Vars
-------------------------------- Vars Start ------------------------------------
local netvars_group = {
    m_iItemDefinitionIndex = se.get_netvar("DT_BaseAttributableItem", "m_iItemDefinitionIndex"),
	m_hActiveWeapon = se.get_netvar("DT_BaseCombatCharacter", "m_hActiveWeapon"),
    m_hMyWeapons = se.get_netvar("DT_BaseCombatCharacter", "m_hMyWeapons"),

    m_ArmorValue = se.get_netvar("DT_CSPlayer", "m_ArmorValue"),
    m_bHasHelmet = se.get_netvar("DT_CSPlayer", "m_bHasHelmet"),
}

local convars_group = {
	mp_free_armor = se.get_convar('mp_free_armor'),
    mp_defuser_allocation = se.get_convar('mp_defuser_allocation'),
}
--------------------------------- Vars End -------------------------------------

-----> Get Current Weapon
-------------------------------- Weapon Start ----------------------------------
-- FFI Structure
CCSWeaponInfo_t = [[
	struct {
		char         __pad_0x0000[4];                       // 0x0000
		char*        console_name;                          // 0x0004
		char         __pad_0x0008[12];                      // 0x0008
		int          primary_clip_size;                     // 0x0014
		int          secondary_clip_size;                   // 0x0018
		int          primary_default_clip_size;             // 0x001c
		int          secondary_default_clip_size;           // 0x0020
		int          primary_reserve_ammo_max;              // 0x0024
		int          secondary_reserve_ammo_max;            // 0x0028
		char*        model_world;                           // 0x002c
		char*        model_player;                          // 0x0030
		char*        model_dropped;                         // 0x0034
		char*        sound_empty;                           // 0x0038
		char*        sound_single_shot;                     // 0x003c
		char*        sound_single_shot_accurate;            // 0x0040
		char         __pad_0x0044[12];                      // 0x0044
		char*        sound_burst;                           // 0x0050
		char*        sound_reload;                          // 0x0054
		char         __pad_0x0058[16];                      // 0x0058
		char*        sound_special1;                        // 0x0068
		char*        sound_special2;                        // 0x006c
		char*        sound_special3;                        // 0x0070
		char         __pad_0x0074[4];                       // 0x0074
		char*        sound_nearlyempty;                     // 0x0078
		char         __pad_0x007c[4];                       // 0x007c
		char*        primary_ammo;                          // 0x0080
		char*        secondary_ammo;                        // 0x0084
		char*        item_name;                             // 0x0088
		char*        item_class;                            // 0x008c
		bool         itemflag_exhaustible;                  // 0x0090
		bool         model_right_handed;                    // 0x0091
		bool         is_melee_weapon;                       // 0x0092
		char         __pad_0x0093[9];                       // 0x0093
		int          weapon_weight;                         // 0x009c
		char         __pad_0x00a0[8];                       // 0x00a0
		int          item_gear_slot_position;               // 0x00a8
		char         __pad_0x00ac[28];                      // 0x00ac
		int          weapon_type_int;                       // 0x00c8
		char         __pad_0x00cc[4];                       // 0x00cc
		int          in_game_price;                         // 0x00d0
		int          kill_award;                            // 0x00d4
		char*        player_animation_extension;            // 0x00d8
		float        cycletime;                             // 0x00dc
		float        cycletime_alt;                         // 0x00e0
		float        time_to_idle;                          // 0x00e4
		float        idle_interval;                         // 0x00e8
		bool         is_full_auto;                          // 0x00ec
		char         __pad_0x00ed[3];                       // 0x00ed
		int          damage;                                // 0x00f0
		float        armor_ratio;                           // 0x00f4
		int          bullets;                               // 0x00f8
		float        penetration;                           // 0x00fc
		float        flinch_velocity_modifier_large;        // 0x0100
		float        flinch_velocity_modifier_small;        // 0x0104
		float        range;                                 // 0x0108
		float        range_modifier;                        // 0x010c
		float        throw_velocity;                        // 0x0110
		char         __pad_0x0114[12];                      // 0x0114
		int          has_silencer;                          // 0x0120
		char         __pad_0x0124[4];                       // 0x0124
		int          crosshair_min_distance;                // 0x0128
		int          crosshair_delta_distance;              // 0x012c
		float        max_player_speed;                      // 0x0130
		float        max_player_speed_alt;                  // 0x0134
		float        attack_movespeed_factor;               // 0x0138
		float        spread;                                // 0x013c
		float        spread_alt;                            // 0x0140
		float        inaccuracy_crouch;                     // 0x0144
		float        inaccuracy_crouch_alt;                 // 0x0148
		float        inaccuracy_stand;                      // 0x014c
		float        inaccuracy_stand_alt;                  // 0x0150
		float        inaccuracy_jump_initial;               // 0x0154
		float        inaccuracy_jump_apex;                  // 0x0158
		float        inaccuracy_jump;                       // 0x015c
		float        inaccuracy_jump_alt;                   // 0x0160
		float        inaccuracy_land;                       // 0x0164
		float        inaccuracy_land_alt;                   // 0x0168
		float        inaccuracy_ladder;                     // 0x016c
		float        inaccuracy_ladder_alt;                 // 0x0170
		float        inaccuracy_fire;                       // 0x0174
		float        inaccuracy_fire_alt;                   // 0x0178
		float        inaccuracy_move;                       // 0x017c
		float        inaccuracy_move_alt;                   // 0x0180
		float        inaccuracy_reload;                     // 0x0184
		int          recoil_seed;                           // 0x0188
		float        recoil_angle;                          // 0x018c
		float        recoil_angle_alt;                      // 0x0190
		float        recoil_angle_variance;                 // 0x0194
		float        recoil_angle_variance_alt;             // 0x0198
		float        recoil_magnitude;                      // 0x019c
		float        recoil_magnitude_alt;                  // 0x01a0
		float        recoil_magnitude_variance;             // 0x01a4
		float        recoil_magnitude_variance_alt;         // 0x01a8
		int          spread_seed;                           // 0x01ac
		float        recovery_time_crouch;                  // 0x01b0
		float        recovery_time_stand;                   // 0x01b4
		float        recovery_time_crouch_final;            // 0x01b8
		float        recovery_time_stand_final;             // 0x01bc
		int          recovery_transition_start_bullet;      // 0x01c0
		int          recovery_transition_end_bullet;        // 0x01c4
		bool         unzoom_after_shot;                     // 0x01c8
		bool         hide_view_model_zoomed;                // 0x01c9
		char         __pad_0x01ca[2];                       // 0x01ca
		int          zoom_levels;                           // 0x01cc
		int          zoom_fov_1;                            // 0x01d0
		int          zoom_fov_2;                            // 0x01d4
		int          zoom_time_0;                           // 0x01d8
		int          zoom_time_1;                           // 0x01dc
		int          zoom_time_2;                           // 0x01e0
		char*        addon_location;                        // 0x01e4
		char         __pad_0x01e8[4];                       // 0x01e8
		float        addon_scale;                           // 0x01ec
		char*        eject_brass_effect;                    // 0x01f0
		char*        tracer_effect;                         // 0x01f4
		int          tracer_frequency;                      // 0x01f8
		int          tracer_frequency_alt;                  // 0x01fc
		char*        muzzle_flash_effect_1st_person;        // 0x0200
		char*        muzzle_flash_effect_1st_person_alt;    // 0x0204
		char*        muzzle_flash_effect_3rd_person;        // 0x0208
		char*        muzzle_flash_effect_3rd_person_alt;    // 0x020c
		char*        heat_effect;                           // 0x0210
		float        heat_per_shot;                         // 0x0214
		char*        zoom_in_sound;                         // 0x0218
		char*        zoom_out_sound;                        // 0x021c
		char         __pad_0x0220[4];                       // 0x0220
		float        inaccuracy_alt_sound_threshold;        // 0x0224
		float        bot_audible_range;                     // 0x0228
		char         __pad_0x022c[12];                      // 0x022c
		bool         has_burst_mode;                        // 0x0238
		bool         is_revolver;                           // 0x0239
		char         __pad_0x023a[2];                       // 0x023a
	}
]]

-- IWeaponSystem
match = client.find_pattern("client.dll", "8B 35 ? ? ? ? FF 10 0F B7 C0") or error("IWeaponSystem signature invalid")
IWeaponSystem_raw = ffi.cast("void****", ffi.cast("char*", match) + 0x2)[0]
native_GetCSWeaponInfo = vtable_thunk(2, CCSWeaponInfo_t .. "*(__thiscall*)(void*, unsigned int)") or error("invalid GetCSWeaponInfo index")
ctype_char = ffi.typeof("char*")

-- Useful Functions
function GetWeaponIndex(entity)
	local weapon_defindex = entitylist.get_entity_from_handle(entity:get_prop_int(netvars_group.m_hActiveWeapon)):get_prop_int(netvars_group.m_iItemDefinitionIndex)
	if weapon_defindex >= 589824 then
		weapon_defindex = weapon_defindex - 589824
	elseif weapon_defindex >= 262144 then
		weapon_defindex = weapon_defindex - 262144
	end

	return weapon_defindex
end

function GetWeaponInfo(info, index)
	local res = native_GetCSWeaponInfo(IWeaponSystem_raw, index)

	if res ~= nil then
		local val = res[info]

		local ct_success, ct = pcall(ffi.typeof, val)
		if ct_success and ct == ctype_char then
			return ffi.string(val)
		else
			return val
		end
	end

	return nil
end

function GetWeaponTypeValue(weapon_name)
    if weapon_name == "glock" or weapon_name == "hkp2000" or weapon_name == "usp_silencer" or weapon_name == "elite" or weapon_name == "p250" or weapon_name == "tec9" or weapon_name == "fiveseven" or weapon_name == "deagle" or weapon_name == "revolver" then
        return 2
    elseif weapon_name == "ssg08" or weapon_name == "awp" or weapon_name == "ssg08" or weapon_name == "scar20" or weapon_name == "g3sg1" or weapon_name == "galilar" or weapon_name == "famas" or weapon_name == "ak47" or weapon_name == "m4a1" or weapon_name == "m4a1_silencer" or weapon_name == "sg556" or weapon_name == "aug" or weapon_name == "nova" or weapon_name == "xm1014" or weapon_name == "mag7" or weapon_name == "m249" or weapon_name == "negev" or weapon_name == "mac10" or weapon_name == "mp9" or weapon_name == "mp7" or weapon_name == "ump45" or weapon_name == "p90" or weapon_name == "bizon" then
        return 1
    elseif weapon_name == "taser" then
        return 3
    elseif weapon_name == "knife" or weapon_name == "knifegg" or weapon_name == "knife_t" then
        return 4
    elseif string.find(weapon_name, "knife") ~= nil then
        return 5
    elseif weapon_name == "molotov" or weapon_name == "incgrenade" then
        return 6
    elseif weapon_name == "decoy" then
        return 7
    elseif weapon_name == "flashbang" then
        return 8
    elseif weapon_name == "hegrenade" then
        return 9
    elseif weapon_name == "smokegrenade" then
        return 10
    else
        return 11
    end
end
-------------------------------- Weapon End ------------------------------------

-----> Main
-------------------------------- Main Start ------------------------------------
local js_string = {
    main_body = [[
        function MainString() {
            let entity_panels = {}
            let entity_flair_panels = {}
            let entity_data = {}
            let event_callbacks = {}

            let unmuted_players = {}

            let TEAM_COLORS = {
                CT: "#B5D4EE40",
                TERRORIST: "#EAD18A61"
            }

            let SHADOW_COLORS = {
                CT: "#393C40",
                TERRORIST: "#4C4844"
            }

            let HIDDEN_IDS = ["id-sb-name__commendations__leader", "id-sb-name__commendations__teacher", "id-sb-name__commendations__friendly", "id-sb-name__musickit"]

            let SLOT_LAYOUT = `
                <root>
                    <Panel style="min-width: 3px; padding-top: 2px; padding-left: 2px; overflow: noclip;">
                        <Image id="smaller" textureheight="15" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px;"  />
                        <Image id="small" textureheight="17" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px;" />
                        <Image id="medium" textureheight="18" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px; margin-top: -4px;" />
                        <Image id="large" textureheight="21" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px; margin-top: -5px;" />
                    </Panel>
                </root>
            `

            let MIN_WIDTHS = {}
            let MAX_WIDTHS = {}
            let SLOT_OVERRIDE = {}

            let GameStateAPI_IsLocalPlayerPlayingMatch_prev
            let FriendsListAPI_IsSelectedPlayerMuted_prev
            let GameStateAPI_IsSelectedPlayerMuted_prev
            let my_xuid = MyPersonaAPI.GetXuid()

            let _SetMinMaxWidth = function(weapon, min_width, max_width, slot_override) {
                if(min_width)
                    MIN_WIDTHS[weapon] = min_width

                if(max_width)
                    MAX_WIDTHS[weapon] = max_width

                if(slot_override)
                    SLOT_OVERRIDE[weapon] = slot_override
            }

            let _DestroyEntityPanels = function() {
                for(key in entity_panels){
                    let panel = entity_panels[key]

                    if(panel != null && panel.IsValid()) {
                        var parent = panel.GetParent()

                        HIDDEN_IDS.forEach(id => {
                            let panel = parent.FindChildTraverse(id)

                            if(panel != null) {
                                panel.style.maxWidth = "28px"
                                panel.style.margin = "0px 5px 0px 5px"
                            }
                        })

                        if(parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                            parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 0px"
                        }

                        panel.DeleteAsync(0.0)
                    }

                    delete entity_panels[key]
                }
            }

            let _GetOrCreateCustomPanel = function(xuid) {
                if(entity_panels[xuid] == null || !entity_panels[xuid].IsValid()){
                    entity_panels[xuid] = null

                    // $.Msg("creating panel for ", xuid)
                    let scoreboard_context_panel = $.GetContextPanel().FindChildTraverse("ScoreboardContainer").FindChildTraverse("Scoreboard") || $.GetContextPanel().FindChildTraverse("id-eom-scoreboard-container").FindChildTraverse("Scoreboard")

                    if(scoreboard_context_panel == null){
                        // usually happens if end of match scoreboard is open. clean up everything?

                        _Clear()
                        _DestroyEntityPanels()

                        return
                    }

                    scoreboard_context_panel.FindChildrenWithClassTraverse("sb-row").forEach(function(el){
                        let scoreboard_el

                        if(el.m_xuid == xuid) {
                            el.Children().forEach(function(child_frame){
                                let stat = child_frame.GetAttributeString("data-stat", "")
                                if(stat == "name") {
                                    scoreboard_el = child_frame.GetChild(0)
                                } else if(stat == "flair") {
                                    entity_flair_panels[xuid] = child_frame.GetChild(0)
                                }
                            })

                            if(scoreboard_el) {
                                let scoreboard_el_parent = scoreboard_el.GetParent()

                                // fix some style. this is not restored
                                // scoreboard_el_parent.style.overflow = "clip clip;"

                                // create panel
                                let custom_weapons = $.CreatePanel("Panel", scoreboard_el_parent, "custom-weapons", {
                                    style: "overflow: noclip; width: fit-children; margin: 0px 0px 0px 0px; padding: 1px 0px 0px 0px; height: 100%; flow-children: left; min-width: 30px;"
                                })

                                HIDDEN_IDS.forEach(id => {
                                    let panel = scoreboard_el_parent.FindChildTraverse(id)

                                    if(panel != null) {
                                        panel.style.maxWidth = "0px"
                                        panel.style.margin = "0px"
                                    }
                                })

                                if(scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                                    scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 5px"
                                }

                                scoreboard_el_parent.MoveChildBefore(custom_weapons, scoreboard_el_parent.GetChild(1))

                                // create child panels
                                let panel_armor = $.CreatePanel("Image", custom_weapons, "armor", {
                                    textureheight: "17",
                                    style: "padding-left: 2px; padding-top: 3px; opacity: 0.2; padding-left: 5px;"
                                })
                                panel_armor.visible = false

                                let panel_helmet = $.CreatePanel("Image", custom_weapons, "helmet", {
                                    textureheight: "22",
                                    style: "padding-left: 2px; padding-top: 0px; opacity: 0.2; padding-left: 0px; margin-left: 3px; margin-right: -3px;"
                                })
                                panel_helmet.visible = false
                                panel_helmet.SetImage("file://{images}/icons/equipment/helmet.svg")

                                for(i=24; i >= 0; i--) {
                                    let panel_slot_parent = $.CreatePanel("Panel", custom_weapons, `weapon-${i}`)

                                    panel_slot_parent.visible = false
                                    panel_slot_parent.BLoadLayoutFromString(SLOT_LAYOUT, false, false)
                                }

                                // custom_weapons.style.border = "1px solid red;"
                                entity_panels[xuid] = custom_weapons

                                return custom_weapons
                            }
                        }
                    })
                }

                return entity_panels[xuid]
            }

            let _UpdatePlayer = function(entindex, weapons, selected_weapon, armor) {
                if(entindex == null || entindex == 0)
                    return

                entity_data[entindex] = arguments
            }

            let _ApplyPlayer = function(entindex, weapons, selected_weapon, armor) {
                let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)

                // $.Msg("applying for ", entindex, ": ", weapons)
                let panel = _GetOrCreateCustomPanel(xuid)

                if(panel == null)
                    return

                let team = GameStateAPI.GetPlayerTeamName(xuid)
                let wash_color = TEAM_COLORS[team] || "#ffffffff"

                // panel.style.marginRight = entity_flair_panels[entindex].actuallayoutwidth < 4 ? "-25px" : "0px"

                for(i=0; i < 24; i++) {
                    let panel_slot_parent = panel.FindChild(`weapon-${i}`)

                    if(weapons && weapons[i]) {
                        let weapon = weapons[i]
                        let selected = weapon == selected_weapon
                        panel_slot_parent.visible = true

                        let slot_override = SLOT_OVERRIDE[weapon] || "small"

                        let panel_slot
                        panel_slot_parent.Children().forEach(function(el){
                            if(el.id == slot_override){
                                el.visible = true
                                panel_slot = el
                            } else {
                                el.visible = false
                            }
                        })

                        panel_slot.style.opacity = selected ? "0.85" : "0.35"

                        let shadow_color = SHADOW_COLORS[team] || "#58534D"
                        // shadow_color = "rgba(64, 64, 64, 0.1)"
                        panel_slot.style.imgShadow = selected ? (shadow_color + " 0px 0px 3px 3.75") : "none"

                        panel_slot.style.washColorFast = wash_color
                        panel_slot.SetImage("file://{images}/icons/equipment/" + weapon + ".svg")
                        // panel_slot.style.border = "1px solid red;"

                        panel_slot.style.marginLeft = "-5px"
                        panel_slot.style.marginRight = "-5px"

                        if(weapon == "knife_ursus") {
                            panel_slot.style.marginLeft = "-2px"
                        } else if(weapon == "knife_widowmaker") {
                            panel_slot.style.marginLeft = "-3px"
                        } else if(weapon == "hkp2000") {
                            panel_slot.style.marginRight = "-4px"
                        } else if(weapon == "incgrenade") {
                            panel_slot.style.marginLeft = "-6px"
                        } else if(weapon == "flashbang") {
                            panel_slot.style.marginLeft = "-5px"
                        }

                        panel_slot_parent.style.minWidth = MIN_WIDTHS[weapon] || "0px"
                        panel_slot_parent.style.maxWidth = MAX_WIDTHS[weapon] || "1000px"
                    } else if(panel_slot_parent.visible) {
                        // $.Msg("removed!")
                        panel_slot_parent.visible = false
                        let panel_slot = panel_slot_parent.GetChild(0)
                        panel_slot.style.opacity = "0.01"
                    }
                }

                let panel_armor = panel.FindChild("armor")
                let panel_helmet = panel.FindChild("helmet")

                if(armor != null){
                    panel_armor.visible = true
                    panel_armor.style.washColorFast = wash_color

                    if(armor == "helmet") {
                        panel_armor.SetImage("file://{images}/icons/equipment/kevlar.svg")

                        panel_helmet.visible = true
                        panel_helmet.style.washColorFast = wash_color
                    } else {
                        panel_armor.SetImage("file://{images}/icons/equipment/" + armor + ".svg")
                    }
                } else {
                    panel_armor.visible = false
                    panel_helmet.visible = false
                }

                return true
            }

            let _ApplyData = function() {
                for(entindex in entity_data) {
                    entindex = parseInt(entindex)
                    let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)

                    if(!entity_data[entindex].applied || entity_panels[xuid] == null || !entity_panels[xuid].IsValid()) {
                        if(_ApplyPlayer.apply(null, entity_data[entindex])) {
                            // $.Msg("successfully appied for ", entindex)
                            entity_data[entindex].applied = true
                        }
                    }
                }
            }

            let _EnablePlayingMatchHook = function() {
                if(GameStateAPI_IsLocalPlayerPlayingMatch_prev == null) {
                    GameStateAPI_IsLocalPlayerPlayingMatch_prev = GameStateAPI.IsLocalPlayerPlayingMatch

                    GameStateAPI.IsLocalPlayerPlayingMatch = function() {
                        if(GameStateAPI.IsDemoOrHltv()) {
                            return true
                        }

                        return GameStateAPI_IsLocalPlayerPlayingMatch_prev.call(GameStateAPI)
                    }
                }
            }

            let _DisablePlayingMatchHook = function() {
                if(GameStateAPI_IsLocalPlayerPlayingMatch_prev != null) {
                    GameStateAPI.IsLocalPlayerPlayingMatch = GameStateAPI_IsLocalPlayerPlayingMatch_prev
                    GameStateAPI_IsLocalPlayerPlayingMatch_prev = null
                }
            }

            let _EnableSelectedPlayerMutedHook = function() {
                if(FriendsListAPI_IsSelectedPlayerMuted_prev == null) {
                    FriendsListAPI_IsSelectedPlayerMuted_prev = FriendsListAPI.IsSelectedPlayerMuted

                    FriendsListAPI.IsSelectedPlayerMuted = function(xuid) {
                        if(xuid == my_xuid) {
                            return false
                        }

                        return FriendsListAPI_IsSelectedPlayerMuted_prev.call(FriendsListAPI, xuid)
                    }
                }

                if(GameStateAPI_IsSelectedPlayerMuted_prev == null) {
                    GameStateAPI_IsSelectedPlayerMuted_prev = GameStateAPI.IsSelectedPlayerMuted

                    GameStateAPI.IsSelectedPlayerMuted = function(xuid) {
                        if(xuid == my_xuid) {
                            return false
                        }

                        return GameStateAPI_IsSelectedPlayerMuted_prev.call(GameStateAPI, xuid)
                    }
                }
            }

            let _DisableSelectedPlayerMutedHook = function() {
                if(FriendsListAPI_IsSelectedPlayerMuted_prev != null) {
                    FriendsListAPI.IsSelectedPlayerMuted = FriendsListAPI_IsSelectedPlayerMuted_prev
                    FriendsListAPI_IsSelectedPlayerMuted_prev = null
                }

                if(GameStateAPI_IsSelectedPlayerMuted_prev != null) {
                    GameStateAPI.IsSelectedPlayerMuted = GameStateAPI_IsSelectedPlayerMuted_prev
                    GameStateAPI_IsSelectedPlayerMuted_prev = null
                }
            }

            let _UnmutePlayer = function(xuid) {
                if(GameStateAPI.IsSelectedPlayerMuted(xuid)) {
                    GameStateAPI.ToggleMute(xuid)
                    unmuted_players[xuid] = true

                    return true
                }

                return false
            }

            let _RestoreUnmutedPlayers = function(xuid) {
                for(xuid in unmuted_players) {
                    if(!GameStateAPI.IsSelectedPlayerMuted(xuid) && GameStateAPI.IsPlayerConnected(xuid)) {
                        GameStateAPI.ToggleMute(xuid)
                    }
                }
                unmuted_players = {}
            }

            let _GetAllPlayers = function() {
                let result = []

                for(entindex=1; entindex <= 64; entindex++) {
                    let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)

                    if(xuid && xuid != "0") {
                        result.push(xuid)
                    }
                }

                return result
            }

            let _Create = function() {
                event_callbacks["OnOpenScoreboard"] = $.RegisterForUnhandledEvent("OnOpenScoreboard", _ApplyData)
                event_callbacks["Scoreboard_UpdateEverything"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateEverything", function(){
                    // $.Msg("cleared applied data")
                    for(entindex in entity_data) {
                        // entity_data[entindex].applied = false
                    }
                    _ApplyData()
                })
                event_callbacks["Scoreboard_UpdateJob"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateJob", _ApplyData)
            }

            let _Clear = function() {
                entity_data = {}
            }

            let _Destroy = function() {
                // clear entity data
                _Clear()
                _DestroyEntityPanels()

                for(event in event_callbacks){
                    $.UnregisterForUnhandledEvent(event, event_callbacks[event])

                    delete event_callbacks[event]
                }

                // $.GetContextPanel().FindChildTraverse("TeamSmallContainerCT").style.width = "400px"
                // $.GetContextPanel().FindChildTraverse("TeamSmallContainerT").style.width = "400px"
            }

            return {
                create: _Create,
                set_min_max_width: _SetMinMaxWidth,
                destroy: _Destroy,
                clear: _Clear,
                update_player: _UpdatePlayer,
                enable_playing_match_hook: _EnablePlayingMatchHook,
                disable_playing_match_hook: _DisablePlayingMatchHook,
                enable_selected_player_muted_hook: _EnableSelectedPlayerMutedHook,
                disable_selected_player_muted_hook: _DisableSelectedPlayerMutedHook,
                unmute_player: _UnmutePlayer,
                restore_unmuted_players: _RestoreUnmutedPlayers,
                get_all_players: _GetAllPlayers
            }
        }

        var CreatePanel = MainString();

        CreatePanel.set_min_max_width("knife", null, null, "small");
        CreatePanel.set_min_max_width("knife_t", null, null, "small");
        CreatePanel.set_min_max_width("knife_widowmaker", null, null, "small");
        CreatePanel.set_min_max_width("knife_butterfly", null, null, "small");
        CreatePanel.set_min_max_width("knife_survival_bowie", null, null, "large");
        CreatePanel.set_min_max_width("knife_gut", null, null, "medium");
        CreatePanel.set_min_max_width("knife_karambit", null, null, "medium");
        CreatePanel.set_min_max_width("knife_ursus", null, null, "small");

        CreatePanel.set_min_max_width("hkp2000", null, null, "medium");

        CreatePanel.set_min_max_width("incgrenade", "12px");
        CreatePanel.set_min_max_width("smokegrenade", "9px");
        CreatePanel.set_min_max_width("flashbang", "9px", "12px");
    ]],

    clear_panel = [[
        CreatePanel.clear();
    ]],

    create_panel = [[
        CreatePanel.create();
    ]],

    destroy_panel = [[
        CreatePanel.destroy();
    ]],

}

--[[ tips:
    update_player = {
        function(entindex, weapons, selected_weapon, armor)
        entindex -> number, weapons -> string table, selected_weapon -> string, armor -> string
        weapon string -> gsub("item_", ""):gsub("weapon_", "")
    }
]]--

-----> Main
function table_contains(tbl, val)
	for i = 1, #tbl do
		if tbl[i] == val then
			return true
		end
	end
	return false
end

function table_remove_item(tbl, item)
	for i = #tbl, 1, -1 do
		if tbl[i] == item then
			table.remove(tbl, i)
		end
	end
end

function sort_weapons_func(a, b)
    local a_type_value = GetWeaponTypeValue(a)
    local b_type_value = GetWeaponTypeValue(b)

    return a_type_value < b_type_value
end

function LuaToJs(content)
    local res = ""

    if type(content) == "string" then
        res = content
    elseif type(content) == "number" or type(content) == "boolean" then
        res = tostring(content)
    elseif type(content) == "table" then
        for _, value in ipairs(content) do
            res = res.."'"..value.."', "
        end
        res = "["..res.."]"
    else
        res = nil
    end

    return res
end

local panel_start = false
local PlayerInfoGroup = {}
function GetPlayerInfo()
	if not engine.is_connected() or not engine.is_in_game() or not entitylist.get_local_player() or not entitylist.get_local_player():is_alive() then
		PlayerInfoGroup = {}
		return
	end

    local free_kevlar = convars_group.mp_free_armor:get_int() > 0
	local free_helmet = convars_group.mp_free_armor:get_int() > 1
	local free_defuser = convars_group.mp_defuser_allocation:get_int() >= 2

	local players = entitylist.get_players(2)
    for i = 1, #players do
        local player = players[i]
        local player_index = player:get_index()

		if PlayerInfoGroup[player_index] == nil then -- Define
            PlayerInfoGroup[player_index] = {}
        end

        if PlayerInfoGroup[player_index].weapons == nil then -- Define
            PlayerInfoGroup[player_index].weapons = {}
        end

        local current_weapon_name = GetWeaponInfo("console_name", GetWeaponIndex(player)):gsub("item_", ""):gsub("weapon_", "")
        if not table_contains(PlayerInfoGroup[player_index].weapons, current_weapon_name) then
            table.insert(PlayerInfoGroup[player_index].weapons, current_weapon_name)
        end
        PlayerInfoGroup[player_index].current_weapon = current_weapon_name

        if player:get_prop_int(netvars_group.m_ArmorValue) > 0 then
            if player:get_prop_bool(netvars_group.m_bHasHelmet) then
                if not free_helmet then
                    PlayerInfoGroup[player_index].armor = "helmet"
                end
            elseif not free_kevlar then
                PlayerInfoGroup[player_index].armor = "kevlar"
            end
        else
            PlayerInfoGroup[player_index].armor = "null"
        end
	end
end

function UpdatePlayer(index)
    if not panel_start then
        panorama.loadstring(js_string.main_body..js_string.create_panel)
        panel_start = true
    end

    table.sort(PlayerInfoGroup[index].weapons, sort_weapons_func)

    local player_index = LuaToJs(index)
    local player_weapon_group = LuaToJs(PlayerInfoGroup[index].weapons)
    local player_current_weapon = LuaToJs(PlayerInfoGroup[index].current_weapon)
    local player_armor = PlayerInfoGroup[index].armor

    local update_player_info
    if player_armor ~= "null" then
        update_player_info = "CreatePanel.update_player("..player_index..", "..player_weapon_group..", '"..player_current_weapon.."', '"..player_armor.."');"
    else
        update_player_info = "CreatePanel.update_player("..player_index..", "..player_weapon_group..", '"..player_current_weapon.."', null);"
    end
    panorama.loadstring(update_player_info)
end

local events_start_time = {
    ["on_item_equip"] = globalvars.get_current_time(),
    ["round_freeze_end"] = false,
}
local events_index = {
    ["on_item_equip"] = 0,
}

function TimerListener()
    if globalvars.get_current_time() - events_start_time["on_item_equip"] < 0.01 then
        UpdatePlayer(events_index["on_item_equip"])
    end

    if events_start_time["round_freeze_end"] then
        local players = entitylist.get_players(2)
        for index = 1, #players do
            if PlayerInfoGroup[index] ~= nil then
                UpdatePlayer(index)
            end
        end

        events_start_time["round_freeze_end"] = false
    end
end

-----> Events
function on_player_death(event)
    local event_userid = event:get_int("userid", 0)
	local player_index = engine.get_player_for_user_id(event_userid)

    panorama.loadstring("CreatePanel.update_player("..player_index..", null, null, null);")
    PlayerInfoGroup[player_index] = {}
end

function on_player_spawn(event)
    local event_userid = event:get_int("userid", 0)
	local player_index = engine.get_player_for_user_id(event_userid)

	UpdatePlayer(player_index)
end

function on_item_remove(event)
    local event_userid = event:get_int("userid", 0)
	local player_index = engine.get_player_for_user_id(event_userid)

    local event_defindex = event:get_int("defindex", 0)
    local weapon_name = GetWeaponInfo("console_name", event_defindex):gsub("item_", ""):gsub("weapon_", "")

    if weapon_name ~= 'assaultsuit' and weapon_name ~= 'kevlar' and weapon_name ~= 'defuser' then
        if PlayerInfoGroup[player_index].weapons ~= nil then
            table_remove_item(PlayerInfoGroup[player_index].weapons, weapon_name)

            UpdatePlayer(player_index)
        end
    end
end

function on_item_pickup(event)
    local event_userid = event:get_int("userid", 0)
    local player_index = engine.get_player_for_user_id(event_userid)

    local event_defindex = event:get_int("defindex", 0)
    local weapon_name = GetWeaponInfo("console_name", event_defindex):gsub("item_", ""):gsub("weapon_", "")

    if weapon_name ~= 'assaultsuit' and weapon_name ~= 'kevlar' and weapon_name ~= 'defuser' then
        if not table_contains(PlayerInfoGroup[player_index].weapons, weapon_name) then
            table.insert(PlayerInfoGroup[player_index].weapons, weapon_name)
        end
    end

    UpdatePlayer(player_index)
end

function on_item_equip(event)
    local event_userid = event:get_int("userid", 0)
	local player_index = engine.get_player_for_user_id(event_userid)

    events_start_time["on_item_equip"] = globalvars.get_current_time()
    events_index["on_item_equip"] = player_index
end

function on_item_purchase(event)
    local event_userid = event:get_int("userid", 0)
    local player_index = engine.get_player_for_user_id(event_userid)

    local weapon = event:get_string("weapon", "")
    local weapon_name = weapon:gsub("item_", ""):gsub("weapon_", "")

    if weapon_name ~= 'assaultsuit' and weapon_name ~= 'kevlar' and weapon_name ~= 'defuser' then
        if not table_contains(PlayerInfoGroup[player_index].weapons, weapon_name) then
		    table.insert(PlayerInfoGroup[player_index].weapons, weapon_name)

            UpdatePlayer(player_index)
        end
	end
end

function on_round_freeze_end()
    events_start_time["round_freeze_end"] = true
end

-----> Callbacks
client.register_callback("paint", GetPlayerInfo)
client.register_callback("paint", TimerListener)

client.register_callback("player_death", on_player_death)
client.register_callback("player_spawn", on_player_spawn)
client.register_callback("item_remove", on_item_remove)
client.register_callback("item_pickup", on_item_pickup)
client.register_callback("item_equip", on_item_equip)
client.register_callback("item_purchase", on_item_purchase)
client.register_callback("round_freeze_end", on_round_freeze_end)

client.register_callback("unload", function()
    panorama.loadstring(js_string.destroy_panel)
end)
--------------------------------- Main End -------------------------------------