
FLT_MAX = 2147483647.0

client.register_callback( "create_move", function(cmd)

	local current_player = entitylist.get_entity_by_index( get_player(  ) )

	local local_origin = entitylist.get_local_player():get_prop_vector(se.get_netvar("DT_BaseEntity", "m_vecOrigin"))
	local player_origin = current_player:get_prop_vector( se.get_netvar( "DT_BaseEntity", "m_vecOrigin" ) )

	local current_dist = vec3_t.new( local_origin.x - player_origin.x, local_origin.y - player_origin.y, local_origin.z - player_origin.z ):length()
	local current_angles = calculate_angles(local_origin, player_origin)

	if math.floor(current_dist) <= get_dist( current_player ) then
	    cmd.viewangles = current_angles
	    cmd.buttons = set_bit(cmd.buttons, get_attack( current_player ))
	end

end )


function has_bit(x, p) return x % (p + p) >= p end
function set_bit(x, p) return has_bit(x, p) and x or x + p end

function get_player(  )

	local closet_index, most_close = -1, FLT_MAX

	local entities = entitylist.get_players(0)

	for index = 1,#entities do
		local entity = entities[index]

		if not entity:is_alive() or entity:is_dormant() then
            goto continue
        end

        local origin_var = entitylist.get_local_player():get_prop_vector( se.get_netvar( "DT_BaseEntity", "m_vecOrigin" ) )
        local player_origin = entity:get_prop_vector( se.get_netvar( "DT_BaseEntity", "m_vecOrigin" ) )

        local difference_between_players = vec3_t.new(origin_var.x - player_origin.x, origin_var.y - player_origin.y, origin_var.z - player_origin.z):length()

        if difference_between_players < most_close then
        	most_close = difference_between_players; closet_index = entity:get_index();
        end

        ::continue::
	end

	return closet_index

end

function get_attack( enemy )

	local tickbase     = entitylist.get_local_player():get_prop_int( se.get_netvar( "DT_BasePlayer", "m_nTickBase" ) )
	local weapon   	   = entitylist.get_entity_from_handle( entitylist.get_local_player():get_prop_int( se.get_netvar( "DT_BaseCombatCharacter", "m_hActiveWeapon" ) ) )
	local enemy_health = enemy:get_prop_int( se.get_netvar( "DT_BasePlayer", "m_iHealth" ) )
	local enemy_armor  = enemy:get_prop_int( se.get_netvar( "DT_CSPlayer", "m_ArmorValue" ) )

	if enemy_armor > 55 then

		if get_next_left_attack_health( enemy_armor ) > enemy_health then
			return 1
		else
			if (enemy_health - get_next_left_attack_health( enemy_armor )) > 24 then
				return 1
			else
				return 2048
			end
		end

	else

		if get_next_left_attack_health( enemy_armor ) > enemy_health then
			return 1
		else
			if (enemy_health - get_next_left_attack_health( enemy_armor )) > 35 then
				return 1
			else
				return 2048
			end
		end

	end 

end

function get_dist( enemy )

	return get_attack( enemy ) == 1 and 78 or 63

end

function get_next_left_attack_health( armor )

	local tickbase = entitylist.get_local_player():get_prop_int( se.get_netvar( "DT_BasePlayer", "m_nTickBase" ) )
	local weapon   = entitylist.get_entity_from_handle( entitylist.get_local_player():get_prop_int( se.get_netvar( "DT_BaseCombatCharacter", "m_hActiveWeapon" ) ) )

	if (globalvars.get_interval_per_tick() * tickbase) > ( weapon:get_prop_float( se.get_netvar("DT_BaseCombatWeapon", "m_flNextPrimaryAttack") ) + 0.4 ) then
		return armor > 55 and 34 or 40
	end

	return armor > 55 and 21 or 25

end

function normalize_angles( angles_var, delta_var )
	if delta_var.x >= 0 then
		angles_var.yaw = angles_var.yaw + 180
	end

	if angles_var.yaw <= -180 then
        angles_var.yaw = angles_var.yaw + 360
    end

    if angles_var.yaw >= 180 then
		angles_var.yaw = angles_var.yaw - 360
    end
end

function calculate_angles( start, to )
	
	local new_angles_var = angle_t.new(0,0,0)
	
	local delta_between_positions = vec3_t.new(start.x - to.x, start.y - to.y, start.z - to.z)
	local calculate_position = math.sqrt(delta_between_positions.x*delta_between_positions.x + delta_between_positions.y*delta_between_positions.y)

	new_angles_var.pitch = math.atan(delta_between_positions.z / calculate_position) * 180 / math.pi
	new_angles_var.yaw = math.atan(delta_between_positions.y / delta_between_positions.x) * 180 / math.pi
	new_angles_var.roll = 0

	normalize_angles( new_angles_var, delta_between_positions )

	return new_angles_var

end