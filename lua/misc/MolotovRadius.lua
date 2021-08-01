local flame_color = ui.add_color_edit("color", "misc_flame_color", true, color_t.new(255, 255, 255, 255))

local m_bFireIsBurning = se.get_netvar("DT_Inferno", "m_bFireIsBurning")
local m_fireCount = se.get_netvar("DT_Inferno", "m_fireCount")
local m_fireXDelta = se.get_netvar("DT_Inferno", "m_fireXDelta")
local m_fireYDelta = se.get_netvar("DT_Inferno", "m_fireYDelta")
local m_fireZDelta = se.get_netvar("DT_Inferno", "m_fireZDelta")
local m_vecOrigin = se.get_netvar("DT_BaseEntity", "m_vecOrigin")

local flame_radius = 60.0
local flame_points = 32

local function draw_flame(pos)
    local points = { }
	for i = 1, flame_points do
		local item = vec3_t.new(
			pos.x + flame_radius * math.cos(i * (360.0 / flame_points) * 0.017453),
			pos.y + flame_radius * math.sin(i * (360.0 / flame_points) * 0.017453),
			pos.z + 0.0
		)
		table.insert(points, se.world_to_screen(item))
	end
    renderer.filled_polygon(points, flame_color:get_value())
end

local function on_paint()
	local infernos = entitylist.get_entities_by_class("CInferno")
	for i=1, #infernos do
		local inferno = infernos[i]
		local fires = {}
		
		local local_player = entitylist.get_local_player()
		local origin = inferno:get_prop_vector(m_vecOrigin)
		local count = inferno:get_prop_int(m_fireCount)
		
		for j=1, count do
			local is_burning = inferno:get_prop_bool(m_bFireIsBurning + (j - 1) * 1)
			if is_burning then
				local pos_x = inferno:get_prop_int(m_fireXDelta + (j - 1) * 4) + origin.x
				local pos_y = inferno:get_prop_int(m_fireYDelta + (j - 1) * 4) + origin.y
				local pos_z = inferno:get_prop_int(m_fireZDelta + (j - 1) * 4) + origin.z
				if not pos_x ~= pos_x then
					if not pos_y ~= pos_y then
						if not pos_z ~= pos_z then 
							table.insert(fires, vec3_t.new(pos_x, pos_y, pos_z))
						end
					end
				end
			end
		end
		
		for j=1, #fires do
			draw_flame(fires[j])
		end
	end
end

client.register_callback("paint", on_paint)