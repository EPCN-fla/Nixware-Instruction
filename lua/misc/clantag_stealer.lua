--
local cb_box = { }
cb_box.__index = cb_box

function cb_box:new( visual_name, internal_name, values )
	local object = { } 

	object.values = values
	object.ref = ui.add_combo_box( visual_name, internal_name, values, 0 )

	setmetatable(object, cb_box)
	return object
end

function cb_box:get( )
	return self.values[self.ref:get_value( ) + 1]
end
--

local keys = 
{
	c_enable_clantag_stealer = ui.add_check_box( "Steal Clantag", "c_enable_clantag_stealer", false ),
	c_enable_clantag_stealer_output_targets = ui.add_check_box( "Update Targets", "c_enable_clantag_stealer_output_targets", false ),
	ref_nixtag = ui.get_check_box( "misc_clantag" ),
	c_stealer_targets = nil,
	c_stealer_targets_i = 0
}
keys.c_enable_clantag_stealer:set_value( false )
keys.c_enable_clantag_stealer_output_targets:set_value( false )
keys.ref_nixtag:set_value( false )
se.set_clantag( " " )

local offsets =
{
	m_iTeamNum = se.get_netvar( "DT_BaseEntity", "m_iTeamNum" ),
	m_szClan = se.get_netvar( "DT_CSPlayerResource", "m_szClan" )
}

local function get_clantag( i )
	local player_resource = entitylist.get_entities_by_class( "CCSPlayerResource" )

	if #player_resource ~= 1 then return '' end

	return ffi.string( ffi.cast("const char*", player_resource[1]:get_address( ) + offsets.m_szClan + i * 16 ) )
end

local prev_clantag = nil
local function update_clantag( str )
	if prev_clantag ~= str
	then
		se.set_clantag( str )
		prev_clantag = str
	end
end

local function proccess_update( local_player )
	if not keys.c_enable_clantag_stealer_output_targets:get_value( ) 
	then 
		return 
	end

	local target_names = { "Disabled" }
	local players = entitylist.get_players( 2 )
	for i = 1, #players --
	do
		local entity = players[i]
		local ientity =  entity:get_index( )
		local info = engine.get_player_info( ientity )

		if ( info and string.lower( info.name ) ~= "gotv" and ientity ~= local_player:get_index( ) and info.steam_id64 ~= "0" )
		then
			table.insert( target_names, string.format( "(%d)%s", ientity, info.name ) )
		end
	end

	if #target_names > 1
	then
		if keys.c_stealer_targets ~= nil
		then
			keys.c_stealer_targets.ref:set_visible( false )
			keys.c_stealer_targets = nil
			keys.c_stealer_targets_i = keys.c_stealer_targets_i + 1
		end

		if keys.c_stealer_targets == nil
		then
			keys.c_stealer_targets = cb_box:new( "Stealer Target", string.format( "cb_stealer_target%d", keys.c_stealer_targets_i ), target_names )
		end
	end

	keys.c_enable_clantag_stealer_output_targets:set_value( false )
end

local to_reset = false
local function steal_target_clantag( )
	if not keys.c_enable_clantag_stealer:get_value( ) 
	then 
		if to_reset
		then
			se.set_clantag( " " )
			to_reset = false
		end
		return 
	end

	local id = nil
	if keys.c_stealer_targets == nil then return end

	local name = keys.c_stealer_targets:get( )
	if name == "Disabled" then return end

	local id = tonumber( string.match( name, "(%d+)" ) )
	if id and id > 0 and id < 256
	then
		local entity = entitylist.get_entity_by_index( id )
		local team = entity:get_prop_int( offsets.m_iTeamNum )

		if team ~= 2 and team ~= 3 then return end

		local clantag = get_clantag( id )

		if clantag
		then
			keys.ref_nixtag:set_value( false )
			update_clantag( clantag )
			to_reset = true
		end
	end
end

client.register_callback( 'paint', function( e )
	if not engine.is_in_game( ) or not engine.is_connected( ) then return end

	local local_player = entitylist.get_local_player( )
	if not local_player then return end

	proccess_update( local_player )
	steal_target_clantag( )
end )

