ffi.cdef[[ 
		typedef struct { 
			float x,y,z; 
		} vec3_t; 
		
		struct tesla_info_t { 
			vec3_t m_pos; 
			vec3_t m_ang;
			int m_entindex;
			const char *m_spritename;
			float m_flbeamwidth;
			int m_nbeams;
			vec3_t m_color;
			float m_fltimevis;
			float m_flradius;
		}; 
		
		typedef void(__thiscall* FX_TeslaFn)(struct tesla_info_t&); 
]] 
local match = client.find_pattern("client.dll", "55 8B EC 81 EC ? ? ? ? 56 57 8B F9 8B 47 18")
local fs_tesla = ffi.cast("FX_TeslaFn", match)

local uidtoentindex = engine.get_player_for_user_id
local get_local_player = engine.get_local_player()
ui.add_checkbox("Tesla on hit", "enable_tesla", false)
ui.add_color_edit("Color", "color_tesla", false, color_t.new(255, 255, 255, 255))
ui.add_slider_int("Tesla width", "width_tesla", 0, 30, 10)
ui.add_slider_int("Tesla radius", "radius_tesla", 0, 1000, 500)
ui.add_slider_int("Beams", "beams_tesla", 0, 100, 12)
ui.add_checkbox("Other sprite", "sprite_tesla", true)
local function on_fire_game_event(e)
if e:get_name() == "player_hurt" then
    if ui.get_bool("enable_tesla") then
        local me = get_local_player
        local attacker = uidtoentindex(e:get_int("attacker", 0))
        if attacker == me then
            local hurt = uidtoentindex(e:get_int("userid", 0))
            local r,g,b = ui.get_color("color_tesla").r, ui.get_color("color_tesla").g, ui.get_color("color_tesla").b
            local x,y,z = 0,0,0
            local tesla_info = ffi.new("struct tesla_info_t")
            tesla_info.m_flbeamwidth = ui.get_int("width_tesla")
			tesla_info.m_flradius = ui.get_int("radius_tesla")
			tesla_info.m_entindex = attacker
			tesla_info.m_color = {r/255, g/255, b/255}
            tesla_info.m_pos = { entitylist.get_entity_by_index(uidtoentindex(e:get_int("userid", 0))):get_player_hitbox_pos(6).x, entitylist.get_entity_by_index(uidtoentindex(e:get_int("userid", 0))):get_player_hitbox_pos(6).y, entitylist.get_entity_by_index(uidtoentindex(e:get_int("userid", 0))):get_player_hitbox_pos(6).z }
            tesla_info.m_ang = {x,y,z} 
			tesla_info.m_fltimevis = 0.75 
			tesla_info.m_nbeams = ui.get_int("beams_tesla")
            tesla_info.m_spritename = ui.get_bool("sprite_tesla") and "sprites/physbeam.vmt" or "sprites/purplelaser1.vmt"
            fs_tesla(tesla_info)
        end
    end
end
end
client.register_callback('fire_game_event', on_fire_game_event)