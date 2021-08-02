local verdana_def = renderer.setup_font( "C:/windows/fonts/verdana.ttf", 13, 0 )
local verdana_bold = renderer.setup_font( "C:/windows/fonts/verdana.ttf", 30, 32 )

local origin = se.get_netvar( "DT_BaseEntity", "m_vecOrigin" )
local vec_view = se.get_netvar( "DT_BasePlayer", "m_vecViewOffset[0]" )
local tick = se.get_netvar( "DT_BaseCSGrenadeProjectile", "m_nExplodeEffectTickBegin" )

math.round = function( num, idp )
  local mult = 10^( idp or 0 )
  return math.floor( num * mult + 0.5 ) / mult
end

local function distance_in_ft( o, dest )
	local yo = vec3_t.new( dest.x - o.x, dest.y - o.y, dest.z - o.z )
	return math.round( math.sqrt( yo.x * yo.x + yo.y * yo.y + yo.z * yo.z ) / 12, 3 )
end

local function arc( x, y, r1, r2, s, d, col )
	local i = s
	
	while i < s + d do
		i = i + 1
		
		local m_rad = i * math.pi / 180
		renderer.line( vec2_t.new( x + math.cos( m_rad ) * r1, y + math.sin( m_rad ) * r1 ), vec2_t.new( x + math.cos( m_rad ) * r2, y + math.sin( m_rad ) * r2 ), col )
	
	end
end

local function call_molotov_fire( pos )
	local get_int = 150
	local eye_pos = pos
	
	local grenades1 = entitylist.get_entities_by_class_id( 100 )
	local correct_shit = 0
	
	if grenades1 then
		for i = 1, #grenades1 do
		
			local grenade = grenades1[ i ]
			
			if grenade then
			
				local ent_origin = grenade:get_prop_vector( origin )
				local m_tick = grenade:get_prop_float( 0x20 )
		
				local n_fact = ( m_tick + 7 - globalvars.get_current_time( ) ) / 7
				local pos2d = se.world_to_screen( ent_origin )
		
				local fraction, hit_entity_index = trace.line( engine.get_local_player( ), 33570827, eye_pos, ent_origin )
		
				local dist = distance_in_ft( eye_pos, ent_origin )
				local safe = dist > 5 or fraction < 0.61
	
				if dist > 99 then
					correct_shit = 4
				else
					correct_shit = 0
				end
		
				if dist < get_int then
			
					if safe then
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 255, 20, 20, 175) )
					else
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 225, 20, 20, 175) )
					end
			
					renderer.text( "!", verdana_bold, vec2_t.new( pos2d.x - 5, pos2d.y - 75 ), 32, color_t.new( 255, 250, 175, 200 ) )
					renderer.text( tostring( math.round( dist, 0 ) ) .. " ft", verdana_def, vec2_t.new( pos2d.x - 13 - correct_shit, pos2d.y - 43 ), 13, color_t.new( 255, 255, 255, 200 ) )
			
					arc( pos2d.x, pos2d.y - 50, 30, 32, -90, 360 * n_fact, color_t.new( 255, 255, 255, 200 ) );
				end
			
			end
		
		end
	end
	
	
end

local function call_molotov( pos )
	local get_int = 150	
	local eye_pos = pos
	
	local grenades = entitylist.get_entities_by_class("CMolotovProjectile")
	local correct_shit = 0
	
	if grenades then
		for i = 1, #grenades do
		
			local grenade = grenades[ i ]
			
			if grenade then
				
				local ent_origin = grenade:get_prop_vector( origin )
		
				local pos2d = se.world_to_screen( ent_origin )
				local fraction, hit_entity_index = trace.line( engine.get_local_player( ), 33570827, eye_pos, ent_origin )
		
				local dist = distance_in_ft( eye_pos, ent_origin )
				local safe = dist > 5 or fraction < 0.61
		
				if dist > 99 then
					correct_shit = 4
				else
					correct_shit = 0
				end
		
				if dist < get_int then
			
					if safe then
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 20, 20, 20, 175) )
					else
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 225, 20, 20, 175) )
					end
			
					renderer.text( "!", verdana_bold, vec2_t.new( pos2d.x - 5, pos2d.y - 75 ), 32, color_t.new( 255, 250, 175, 200) )
					renderer.text( tostring( math.round( dist, 0) ) .. " ft", verdana_def, vec2_t.new( pos2d.x - 13 - correct_shit, pos2d.y - 43 ), 13, color_t.new( 255, 255, 255, 200 ) )
			
					
						arc( pos2d.x, pos2d.y - 50, 30, 32, -90, 360, color_t.new( 232, 232, 232, 200 ) );
					
					
				end
			end
		end	
	end
end

local function call_he( pos )
	local get_int = 150
	local eye_pos = pos
	
	local grenades = entitylist.get_entities_by_class_id( 9 )
	local correct_shit = 0
	
	if grenades then
		for i = 1, #grenades do
		
			local grenade = grenades[ i ]
			
			if grenade then
			
				local mm_tick = grenade:get_prop_int( tick )
				local ent_origin = grenade:get_prop_vector( origin )
				local pos2d = se.world_to_screen( ent_origin )
			
				local fraction, hit_entity_index = trace.line( engine.get_local_player( ), 33570827, eye_pos, ent_origin )
		
				local dist = distance_in_ft( eye_pos, ent_origin )
				local safe = dist > 5 or fraction < 0.61
		
				if dist > 99 then
					correct_shit = 4
				else
					correct_shit = 0
				end
		
				if dist < get_int and mm_tick == 0 then
			
					if safe then
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 20, 20, 20, 175 ) )
					else
						renderer.circle( vec2_t.new( pos2d.x, pos2d.y - 50 ), 30, 30, true, color_t.new( 225, 20, 20, 175 ) )
					end
				
					renderer.text( "!", verdana_bold, vec2_t.new( pos2d.x - 5, pos2d.y - 75 ), 32, color_t.new( 255, 250, 175, 200 ) )
					renderer.text( tostring( math.round( dist, 0 ) ) .. " ft", verdana_def, vec2_t.new( pos2d.x - 13 - correct_shit, pos2d.y - 43 ), 13, color_t.new( 255, 255, 255, 200 ) )
				end				
			end			
		end		
	end	
end

local function nade_esp( )	
	local m_local = entitylist.get_local_player( )
	local local_origin = m_local:get_prop_vector( origin )
	local local_view = m_local:get_prop_vector( vec_view )
	local _pos = vec3_t.new( local_origin.x + local_view.x, local_origin.y + local_view.y, local_origin.z + local_view.z )
	
	if m_local then
			call_he( _pos )
			call_molotov_fire( _pos )
			call_molotov( _pos )	
	end	
end

client.register_callback( "paint", nade_esp )