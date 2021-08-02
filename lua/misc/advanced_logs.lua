local notify = require "nixfications"
local c_print_chat = { }

--chat lib
c_print_chat.c_color_list = 
{
	"\x01", -- 1 -> Light Grey (Default Chat Color)
	"\x02", -- 2 -> Red
	"\x03", -- 3 -> Purple
	"\x04", -- 4 -> Lime
	"\x05", -- 5 -> Light Green
	"\x06", -- 6 -> Green
	"\x07", -- 7 -> Light Red
	"\x08", -- 8 -> Grey
	"\x09", -- 9 -> Yellow
	"\x0A", --10 -> Steel
	"\x0C", --11 -> Blue
	"\x10"  --12 -> Orange
}

c_print_chat.get_vfunc = function(ptr, typedef, index)
	return ffi.cast( typedef, ffi.cast( "void***", ptr )[0][index])
end

c_print_chat.this = ffi.cast( "unsigned long**", client.find_pattern( "client_panorama.dll", "B9 ? ? ? ? E8 ? ? ? ? 8B 5D 08" ) + 1 )[0]
c_print_chat.find_hud_element = ffi.cast( "unsigned long(__thiscall*)(void*, const char*)", client.find_pattern( "client_panorama.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28" ) )
c_print_chat.hud_chat = c_print_chat.find_hud_element( c_print_chat.this, "CHudChat" )
c_print_chat.chat_print = c_print_chat.get_vfunc( c_print_chat.hud_chat, "void(__cdecl*)(int, int, int, const char*, ...)", 27 )

local prev_say = 0
c_print_chat.say_table = {  }
c_print_chat.say_loop = function( )
	if globalvars.get_real_time( ) - prev_say < 1
	then
		return
	end

	if #c_print_chat.say_table >= 1
	then
		engine.execute_client_cmd(  c_print_chat.say_table[1] )
		table.remove( c_print_chat.say_table, 1 )
		prev_say = globalvars.get_real_time( )
	end
end

c_print_chat.say = function( text )
	table.insert( c_print_chat.say_table, text )
end
c_print_chat.print = function( args )
	local result_string = ""

	for i = 1, #args
	do
		if string.len( args[i][1] ) >= 1
		then
			result_string = result_string..( args[i][2] ~= nil and c_print_chat.c_color_list[args[i][2]]..args[i][1]..c_print_chat.c_color_list[1] or c_print_chat.c_color_list[1]..args[i][1] )
		end
	end
	c_print_chat.chat_print( c_print_chat.hud_chat, 0, 0, " "..result_string )
end
c_print_chat.native = function( text )
	c_print_chat.chat_print( c_print_chat.hud_chat, 0, 0, text )
end
local chat = c_print_chat
--

--combobox lib :D
local cb_box = { }
cb_box.__index = cb_box
function cb_box:new( visual_name, internal_name, values, defvalues )
	local object = { } 
	setmetatable(object, cb_box)

	object.values = values
	object.ref = ui.add_multi_combo_box( visual_name, internal_name, values, defvalues )
	return object
end
function cb_box:get( )
	local t_enabled = {  }
	for i = 0, #self.values - 1
	do
		if self.ref:get_value( i ) 
		then 
			table.insert( t_enabled, self.values[i+1] ) 
		end
	end
	return t_enabled
end
--combobox lib D:

local colors = 
{
	text = color_t.new( 236, 240, 241, 255 ),
	box = color_t.new( 50, 50, 50, 50 ), 
	tip_alpha = 255,

	black = color_t.new( 44, 62, 80, 255 ),
	white = color_t.new( 236, 240, 241, 255 ),
	green = color_t.new( 46, 204, 113, 255 ),
	red = color_t.new( 231, 76, 60, 255 ),
	blue = color_t.new( 52, 152, 219, 255 ),
	purple = color_t.new( 142, 68, 173, 255 ),
	pink = color_t.new( 253, 121, 168, 255 ),
	grey = color_t.new( 46, 43, 50, 200 ),
	yellow = color_t.new( 241, 196, 15, 255 ), 
	black1 = color_t.new( 45, 52, 54,255 ),
	purple1 = color_t.new( 108, 92, 231, 255 ),
	light = color_t.new( 99, 110, 114, 255 ),
	orange = color_t.new( 225, 112, 85, 255 )
}

local s_hitbox_names = 
{ 
	"head", "head", "pelvis", "belly", "thorax", "lower chest", "upper chest", "right thigh", "left thigh", "right calf", "left calf", "right foot", "left foot","right hand","left hand","right upper arm","right forearm","left upper arm","left forearm","unknown"
}

local offsets = 
{
	m_iTeamNum = se.get_netvar( "DT_BaseEntity", "m_iTeamNum" ),
	m_iHealth = se.get_netvar( "DT_BasePlayer", "m_iHealth" ),

	m_iOnlyTeamToVote = se.get_netvar( "DT_VoteController", "m_iOnlyTeamToVote" ),
	m_iActiveIssueIndex = se.get_netvar( "DT_VoteController", "m_iActiveIssueIndex" ),

	m_iCompTeammateColor = se.get_netvar( "DT_CSPlayerResource", "m_iCompTeammateColor" ),
}

local keys = 
{
	mb_vote_reveal = cb_box:new( "Vote Reveal", "mb_vote_reveal", { "Notifications", "Local Chat" }, { true, true } ),
	mb_vote_say = cb_box:new( "Vote Say", "mb_vote_say", { "Enemy Start Vote", "Enemy Vote No", "Enemy Vote Yes", "Teammate Vote No", "Teammate Vote Yes" }, { false, false, false, false, false } ),
	c_vote_say_team = ui.add_check_box("Vote Say Only In Team Chat", "c_vote_say_team", false ),
	mb_shot_logger = cb_box:new( "Shot Logger", "mb_shot_logger", { "Notifications", "Local Chat" }, { true, true } ),
	mb_ddin_logger = cb_box:new( "Local Damage Received Logger", "mb_ddin_logger", { "Notifications", "Local Chat" }, { true, true } ),

	mb_weapon_purchases = cb_box:new( "Weapon Purchases", "mb_weapon_purchases", { "Notifications", "Local Chat" }, { true, true } ),

	clr_custom_box = ui.add_color_edit( "Notifications Box Color", "clr_custom_box", true, color_t.new( 50, 50, 50, 50 ) ), 
	clr_custom_text = ui.add_color_edit( "Notifications Text Color", "clr_custom_text", true, color_t.new( 236, 240, 241, 255 ) ),
	sl_tip_alpha = ui.add_slider_int( "Notifications Tip Alpha", "sl_tip_alpha", 0, 255, 255 ),
}

--main
notify.setup( )
notify.setup_color( colors.green, colors.box )
notify.add( 15, false, { colors.red, 'nix'}, { colors.text, 'fication loaded!' } )
se.register_event( "cs_win_panel_match" )
se.register_event( "vote_cast" )
se.register_event( "player_hurt" )
se.register_event( "item_purchase" )
--

local function in_table( tbl, value )
    for i = 1, #tbl 
    do
        if tbl[i] == value 
        then
            return true
        end
    end
    return false
end

local function get_player_name( index )
	if index == -1 then return "Mixer1337" end

	local info = engine.get_player_info( index )
	local temp_name = info and info.name or "Mixer1337"

	if string.find( temp_name, ";" ) ~= nil 
    then 
        temp_name = temp_name:gsub( '%;', '' )
    end
	return temp_name
end

local iCompTeammateColor = 
{
    [0] = { color_t.new( 241, 196, 15,  255 ), "Yellow", 9 },
    [1] = { color_t.new( 155, 89,  182, 255 ), "Purple", 3 },
    [2] = { color_t.new( 46,  204, 113, 255 ), "Green",  4 },
    [3] = { color_t.new( 52,  152, 219, 255 ), "Blue",   11 },
    [4] = { color_t.new( 211, 84,  0,   255 ), "Orange", 12 },
    [5] = { color_t.new( 149, 165, 166, 255 ), "Gray",   10 }
}
local function get_player_color( i )
	local player_resource = entitylist.get_entities_by_class( "CCSPlayerResource" )
	local iclr = #player_resource ~= 1 and -1 or ffi.cast("int*", player_resource[1]:get_address( ) + offsets.m_iCompTeammateColor + i * 4 )[0]

	if iclr < 0 or iclr > 5
	then
		iclr = 5
	end

    return { iCompTeammateColor[iclr][1], iCompTeammateColor[iclr][3], iCompTeammateColor[iclr][2] } --rgba, chat_color_id, color_name
end

local votes = {  }
local vote_reasons = 
{
	team = --3=ct,2=t
	{
		[1] = 'start a timeout', 
        [2] = 'surrender' 
	},
	no_team = 
	{
		[0] = "kick", 
        [1] = "change the map", 
        [3] = "scramble the teams", 
        [4] = "swap the teams" 
	}
}

local function output_votes( enabled_values, enabled_values_say, local_team )
	for i = 1, #votes
	do
		if votes[i] and votes[i].notified == false and votes[i].issue_text and votes[i].issue ~= -1
		then
			local is_team_vote = ( votes[i].team == 2 or votes[i].team == 3 )
			local team_text = "?"
			local team_color = { colors.blue, 11 }
			if is_team_vote
			then
				team_color = votes[i].team ~= local_team and { colors.red, 2 } or { colors.green, 4 }
				team_text = votes[i].team ~= local_team and "Enemies" or "Teammates"
			end

			if in_table( enabled_values, "Notifications" )
			then
				notify.setup_color( ( vote_text == 'NO' and colors.red or colors.green ), colors.box )
		        notify.add( 15, false, { team_color[1], team_text }, { colors.text, ' called a vote to: '}, { colors.purple, votes[i].issue_text } )
			end
			if in_table( enabled_values, "Local Chat" )
			then
				chat.print( { {"["}, {"nix", 2}, {"ware]"}, { team_text, team_color[2] }, { " called a vote to: "}, { votes[i].issue_text, 3 } } )
			end
			if in_table( enabled_values_say, "Enemy Start Vote" ) and ( ( votes[i].team == 2 or votes[i].team == 3 ) and votes[i].team ~= local_team )
			then
				chat.say( string.format( "%s Enemies called a vote to: ", keys.c_vote_say_team:get_value( ) and "say_team" or "say", votes[i].issue_text ) )
			end
			votes[i].notified = true
		end
	end
end

local function find_vote_controllers(  )
	local local_player = entitylist.get_local_player( )

	if not local_player
	then
		votes = { }
		return
	end

    local local_team = local_player:get_prop_int( offsets.m_iTeamNum )
	local controllers = entitylist.get_entities_by_class( "CVoteController" )
	for i = 1, #controllers
	do
		local controller = controllers[i]
		local issue_index = controller:get_prop_int( offsets.m_iActiveIssueIndex )
		local team_index = controller:get_prop_int( offsets.m_iOnlyTeamToVote )
		local team_text = "?"
		local issue_text = nil

		if ( team_index == 2 or team_index == 3 )
		then
			team_text = local_team == team_index and "Teammates" or "Enemies"
		end

		if issue_index ~= -1 
		then
			if ( team_index == 2 or team_index == 3 ) and vote_reasons.team[issue_index]
			then
				issue_text = vote_reasons.team[issue_index]
			elseif vote_reasons.no_team[issue_index]
			then
				issue_text = vote_reasons.no_team[issue_index]
			end
		end

		if issue_index ~= -1 
		then
			local exists = false
			for v = 1, #votes
			do
				if votes[v].index == controller:get_index( )
				then
					exists = true
				end
			end

			if not exists
			then
				table.insert( votes, 
					{ 
						index = controller:get_index( ),
						issue = issue_index, 
						issue_text = issue_text,
						team = team_index, 
						team_text = team_text,
						notified = false, 
						time = globalvars.get_real_time( ), 
					} )
			end
		end
	end

	--verify & update
	for i = 1, #votes
	do
		local time_since_controller_created = globalvars.get_real_time( ) - votes[i].time
		local vote_controller = entitylist.get_entity_by_index( votes[i].index )
		local issue_index = vote_controller:get_prop_int( offsets.m_iActiveIssueIndex )
		local team_index = vote_controller:get_prop_int( offsets.m_iOnlyTeamToVote )

		local issue_text = nil
		local team_text = "?"
		if ( team_index == 2 or team_index == 3 )
		then
			team_text = local_team == team_index and "Teammates" or "Enemies"
		end

		if issue_index ~= -1 and ( team_index == 2 or team_index == 3 ) and vote_reasons.team[issue_index]
		then
			issue_text = vote_reasons.team[issue_index]
		elseif issue_index ~= -1 and vote_reasons.no_team[issue_index]
		then
			issue_text = vote_reasons.no_team[issue_index]
		end

		if ( issue_index == -1 or votes[i].issue ~= issue_index or votes[i].team ~= team_index or time_since_controller_created > 120.0 ) 
		then
			if votes[i].issue == -1 or issue_text == nil
			then
				table.remove( votes, i )
			else
				votes[i].issue = issue_index
				votes[i].issue_text = issue_text
				votes[i].team = team_index
				votes[i].team_text = team_text
				votes[i].notified = false
			end
		end
	end
	--

	--notify
    local enabled_values = keys.mb_vote_reveal:get( )
	local enabled_values_say = keys.mb_vote_say:get( ) --"Enemy Start Vote", "Enemy Vote No", "Enemy Vote Yes", "Teammate Vote No", "Teammate Vote Yes"
	output_votes( enabled_values, enabled_values_say, local_team )
	--
end

local function on_vote_cast( e )    
	local local_player = entitylist.get_local_player( )
    local local_team = local_player:get_prop_int( offsets.m_iTeamNum )

    local enabled_values = keys.mb_vote_reveal:get( )
	local enabled_values_say = keys.mb_vote_say:get( ) --"Enemy Start Vote", "Enemy Vote No", "Enemy Vote Yes", "Teammate Vote No", "Teammate Vote Yes"

    local team = e:get_int( "team", -1 )
    local e_id = e:get_int( "entityid", -1 ) 
   	local name = get_player_name( e_id )
   	local color = get_player_color( e_id )
   	local vote_option = e:get_int( "vote_option", -1 )
   	local vote_text = "?"

   	if vote_option == 1 
   	then
		vote_text = "NO"
	elseif vote_option == 0 
	then
		vote_text = "YES"
	end

	local team_name = name
	if team == 2 or team == 3
	then
		team_name = team == local_team and "teammate" or "enemy"
	end

	if in_table( enabled_values, "Notifications" )
	then
		notify.setup_color( ( vote_text == 'NO' and colors.red or colors.green ), colors.box )
        notify.add( 15, false, { color[1], name }, { colors.text, ': voted '}, { ( vote_text == 'NO' and colors.red or colors.green ), vote_text } )
	end
	if in_table( enabled_values, "Local Chat" )
	then
		chat.print( { {"["}, {"nix", 2}, {"ware]"}, { name, color[2]}, { " voted "}, {  vote_text, ( vote_text == 'NO' and 2 or 6 ) } })
	end
	if ( ( in_table( enabled_values_say, "Enemy Vote No" ) and vote_text == 'NO' and team ~= local_team ) or 
		( in_table( enabled_values_say, "Enemy Vote Yes" ) and vote_text == 'YES' and team ~= local_team ) or 
		( in_table( enabled_values_say, "Teammate Vote No" ) and vote_text == 'NO' and team == local_team ) or
		( in_table( enabled_values_say, "Teammate Vote Yes" ) and vote_text == 'YES' and team == local_team ) ) and e_id ~= local_player:get_index( )
	then
		local prefix = ( team == local_team or keys.c_vote_say_team:get_value( ) ) and "say_team" or "say"
		chat.say( string.format( "%s \"%s voted %s \"", prefix, name, vote_text ) )
	end
end

client.register_callback( "shot_fired", function( info )
	local shot_result = info.result
	local shot_target = info.target:get_index( )
	local color = get_player_color( shot_target )
	local target_hitbox = s_hitbox_names[info.server_hitgroup+1]
	local shot_damage = info.server_damage
	local expected_hitbox = s_hitbox_names[info.hitbox+1]
	local lp = info.target

	if shot_result == "" or info.manual
	then
		return
	elseif shot_result == "unk" 
	then
		shot_result = "?"
	end

	if shot_result ~= 'hit' and math.random( 0, 1000 ) == 228
	then
		shot_result = "cfg"
	end

	local target_name =get_player_name( shot_target )
	local remaining_hp = lp:get_prop_int( offsets.m_iHealth )

	local chat_text = {  }
	local message_text = ""

	local a_flags = { }
	if info.safe_point then table.insert( a_flags, "SP" ) end
	if info.backtrack > 0 then table.insert( a_flags, "BT="..tostring( info.backtrack ) ) end

	if shot_result == 'hit' 
	then
		message_text = string.format( "Hit | %s | hb: %s | hc: %s%s | dd: %d (%s) | fl: (%s)", 
			target_name, 
			( expected_hitbox ~= target_hitbox and string.format( "%s (expected: %s)", target_hitbox, expected_hitbox ) or target_hitbox ), 
			tostring( info.hitchance ), 
			"%",
			shot_damage, 
			( ( info.client_damage > shot_damage and remaining_hp > 0 ) and string.format( "expected: %d, remaining: %d", info.client_damage, remaining_hp ) or string.format( "remaining: %d", remaining_hp ) ),
			#a_flags >= 1 and table.concat( a_flags, ", " ) or "none" )

		chat_text = 
		{ 
			{"["}, {"nix", 2}, {"ware]"}, 
			{ "Hit | "},
			{ target_name, color[2] },
			{" | hb: "},
			{ target_hitbox, ( target_hitbox == "head" ) and 7 or 4 },
			{ ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and " (expected: " or "" },
			{ ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and expected_hitbox or "", 9 },
			{ ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and ")" or "" },
			{" | hc: "},
			{ tostring( info.hitchance ), 4 },
			{" | dd: "},
			{ tostring( shot_damage ), remaining_hp > 0 and 10 or 7 },
			{" (remaining: " },
			{ remaining_hp, 7 },
			{ ( info.client_damage ~= shot_damage and remaining_hp > 0 ) and ", expected: " or "" },
			{ ( info.client_damage ~= shot_damage and remaining_hp > 0 ) and tostring( info.client_damage ) or "", 9 },
			{ ")" }
		}

		if #a_flags >= 1
		then
			table.insert( chat_text, {" | fl: ("} )
			table.insert( chat_text, { table.concat(a_flags, ", " ), 12} )
			table.insert( chat_text, {")"} )
		end
	else
		message_text = string.format( "Missed | %s | hb: %s | hc: %s%s | fl: (%s) | due to %s", target_name, expected_hitbox, tostring( info.hitchance ), "%", ( #a_flags >= 1 and table.concat( a_flags, ", " ) or "none" ), shot_result )
		chat_text = 
		{ 
			{"["}, {"nix", 2}, {"ware]"},
			{ "Missed | "},
			{ target_name, color[2] },
			{" | hb: "},
			{ target_hitbox, 7 },
			{" | hc: "},
			{ tostring( info.hitchance ), 4 }
		}

		if #a_flags >= 1
		then
			table.insert( chat_text, {" | fl: ("} )
			table.insert( chat_text, { table.concat(a_flags, ", " ), 12} )
			table.insert( chat_text, {")"} )
		end
		table.insert( chat_text, {" | due to: "} )

		local color_reason = 11 --spread/desync/?/occlusion/
		if shot_result == "spread"
		then
			color_reason = 9
		elseif shot_result == "desync" or shot_result == "?"
		then
			color_reason = 7
		elseif shot_result == "occlusion"
		then
			color_reason = 3
		end
		table.insert( chat_text, { shot_result, color_reason } )
	end

	local l_enabled = keys.mb_shot_logger:get( )
	if ( in_table( l_enabled, "Local Chat" ) )
	then
		chat.print( chat_text )
	end
	if ( in_table( l_enabled, "Notifications" ) )
	then
		if shot_result == 'hit' 
		then
			local tip_color = color_t.new( colors.green.r, colors.green.g, colors.green.b, colors.tip_alpha )
			notify.setup_color( tip_color, colors.box )
			notify.add( 15, false,
				{ colors.text, "Hit " }, 
				{ color[1], target_name }, 
				{ colors.text, " in " }, 
				{ ( target_hitbox == "head" and colors.red or colors.green ), target_hitbox },
				{ colors.text, ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and " (expected " or "" },
				{ colors.yellow, ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and expected_hitbox or "" },
				{ colors.text, ( target_hitbox ~= expected_hitbox and remaining_hp > 0 ) and ")" or "" },
				{ colors.text, " for " },
				{ remaining_hp > 0 and colors.light or colors.red, tostring( shot_damage ) },
				{ colors.text, " (remaining: " },
				{ remaining_hp > 0 and colors.light or colors.red, tostring( remaining_hp ) },
				{ colors.text, ( info.client_damage ~= shot_damage and remaining_hp > 0 ) and ", expected: " or "" },
				{ colors.yellow, ( info.client_damage ~= shot_damage and remaining_hp > 0 ) and tostring( info.client_damage ) or "" },
				{ colors.text, ")"},
				{ colors.text, #a_flags >= 1 and " flags: " or ""}, 
				{ colors.orange, #a_flags >= 1 and table.concat( a_flags, ", " ) or ""})
		else
			local clr = colors.blue
			if shot_result == "spread"
			then
				clr = colors.yellow
			elseif shot_result == "desync" or shot_result == "?"
			then
				clr = colors.red
			elseif shot_result == "occlusion"
			then
				clr = colors.purple
			end

			notify.setup_color( color_t.new( clr.r, clr.g, clr.b, colors.tip_alpha ), colors.box )
			notify.add( 15, false, 
				{ colors.text, "Missed | " }, 
				{ color[1], target_name }, 
				{ colors.text, " | hitbox: " },
				{ colors.red, target_hitbox },
				{ colors.text, " | hitchance: "},
				{ colors.green, tostring( info.hitchance ) },
				{ colors.text, "%" },
				{ colors.text, #a_flags >= 1 and " | flags: " or "" },
				{ colors.orange, #a_flags >= 1 and table.concat( a_flags, " , ") or ""},
				{ colors.text, " | due to " },
				{ clr, shot_result }
			)
		end
	end
end)

local weapon_icons = 
{
	defuser =  "E",
    item_kevlar = "C",
	assaultsuit = "D",
    decoy =  "F",
    flashbang = "G",
    hegrenade = "H",
    weapon_smokegrenade = "I",
    molotov = "J" ,
    incgrenade = "K",
    taser = "L",
    hkp2000 = "1",
    usp_silencer = "2",
    p250 = "3",
    elite = "4",
    cz75a = "5",
    tec9 = "6",
    fiveseven = "7",
    deagle = "8",
    revolver = "9",
    glock = "0",
    mac10 = "a",
    mp9 = "b",
    ump45 = "c",
    mp7 = "d",
    p90 = "e",
    bizon = "f",
    nova = "g",
    sawedoff = "h",
    mag7 = "i",
    xm1014 = "j",
    negev = "k",
    m249 = "l",
    galilar = "m",
    ak47 = "n",
    sg556 = "o",
    famas = "p",
    m4a1 = "q",
    m4a1_silencer = "r",
    aug = "s",
    ssg08 = "t",
    awp = "u",
    g3sg1 = "v",
    scar20 = "w",
    mp5sd = "x",
}
local function on_item_purchase( e )
	local selected_values = keys.mb_weapon_purchases:get( ) --"Notifications", "Local Chat" 
	if #selected_values < 1 then return end
	local me = entitylist.get_local_player( )
	if not me then return end

	local entity_index = engine.get_player_for_user_id( e:get_int( "userid", 0 ) )
	local player_color = get_player_color( entity_index )
	local target_name = get_player_name( entity_index )
	local weapon = e:get_string( "weapon", "unknown" )

	if e:get_int( "team", -1 ) == me:get_prop_int( offsets.m_iTeamNum ) then return end

	if weapon == nil then return end
	weapon = weapon:gsub("weapon_", "")
    weapon = weapon:gsub("item_", "")

    if weapon == "unknown" then return end

    if ( in_table( selected_values, "Local Chat" ) )
    then
    	if weapon == 'assaultsuit'
	    then 
	        weapon = 'kelvar and helmet'
	    elseif weapon == 'incgrenade' 
	    then 
	        weapon = 'molotov'
	    elseif weapon == 'flashbang' 
	    then 
	        weapon = 'flash' 
	    elseif weapon == 'smokegrenade' 
	    then 
	        weapon = 'smoke'
	    elseif weapon == 'hegrenade' 
	    then 
	        weapon = 'he'
	    end

        local weapon_name = { weapon, 3 }
        if ( weapon == 'awp' ) 
        then 
            weapon_name = { weapon, 2 }
        elseif ( in_table( { 'kelvar and helmet', 'kevlar', 'molotov', 'he', 'smoke', 'flash', 'defuser', 'taser', 'decoy' }, weapon ) )
        then
            weapon_name = { weapon, 8 }
        elseif ( weapon == 'deagle' or weapon == 'ssg08' ) 
        then 
            weapon_name = { weapon, 9 }
        end
        chat.print( { {"["}, {"nix", 2}, {"ware]"}, { target_name, player_color[2] }, { " purchased " }, weapon_name } )
    end

    local weapon_icon = weapon_icons[weapon]
    if ( in_table( selected_values, "Notifications" ) ) and weapon_icon
    then 
        local weapon_array = { colors.text, weapon_icon, "icon" }
                
        notify.setup_color( colors.purple, colors.box )
        if notify.exists( target_name )
        then
            notify.insert_text( target_name, weapon_array, 20 )
            notify.insert_text( target_name, { colors.text, "  " } )
        else
            notify.add_indexed( target_name, 20, true, { player_color[1], target_name }, { colors.text, ' purchased ' }, weapon_array, { colors.text, "  " } )
        end
    end
end

local function on_player_hurt( event )
	local me = entitylist.get_local_player( )
	local was_hurt = entitylist.get_entity_by_index( engine.get_player_for_user_id( event:get_int( "userid", 0 ) ) )
	local attacker = event:get_int( "attacker", -1 ) 
	local damage = event:get_int( "dmg_health", 0 )
	local hitgroup = s_hitbox_names[event:get_int( "hitgroup", -1 ) + 1]
	local weapon = event:get_string( "weapon", "-1" )

	if attacker == -1 or weapon == "-1" or was_hurt:get_index( ) ~= me:get_index( ) then return end

	attacker = entitylist.get_entity_by_index( engine.get_player_for_user_id( attacker ) ) 
	local target_name = get_player_name( attacker:get_index( ) )

	local my_hp = me:get_prop_int( offsets.m_iHealth )

	weapon = weapon:gsub( "weapon_", "" )
	weapon = weapon:gsub( "item_", "" )
	local e_v = keys.mb_ddin_logger:get( )
	if in_table( e_v, "Notifications" )
	then
		notify.setup_color( color_t.new( colors.blue.r, colors.blue.g, colors.blue.b, colors.tip_alpha ), colors.box )
		notify.add(15, false, 
			{ colors.text, "Damage received from "}, 
			{ colors.blue, target_name }, 
			{ colors.text, " | dd: "}, 
			{ ( ( my_hp > 0 ) and colors.text or colors.red ), tostring( damage ) },
			{ colors.text, " (remaining: " },
			{ ( ( my_hp > 0 ) and colors.green or colors.red ), tostring( my_hp ) },
			{ colors.text, ") | hb: "}, 
			{ ( ( hitgroup == "head" ) and colors.red or colors.green ), hitgroup },
			{ colors.text, " | weapon: "}, 
			{ colors.blue, weapon })
	end

	if in_table( e_v, "Local Chat" )
	then
		local log_string = 
		{ 
			{"["}, {"nix", 2}, {"ware]"}, 
			{ "Damage received from | " },
			{ target_name,11 },
			{ " | dd: " },
			{ tostring( damage ), my_hp > 0 and 8 or 2 }, 
			{ " (remaining: " },
			{ tostring( my_hp ), my_hp > 0 and 6 or 2 },
			{ ") | hb: " },
			{ hitgroup, hitgroup == "head" and 7 or 6 },
			{ " | weapon: " },
			{ weapon, 11 }
		}
		chat.print(log_string)
	end
end

client.register_callback( "fire_game_event", function( event )
	local event_name = event:get_name( )

	if event_name == "vote_cast"
	then
		on_vote_cast( event )
	elseif event_name == "cs_win_panel_match"
	then
		votes = { }
	elseif event_name == "item_purchase"
	then
		on_item_purchase( event )
	elseif event_name == "player_hurt"
	then
		on_player_hurt( event )
	end
end )

client.register_callback( 'paint', function( e )
	notify:listener( )
	c_print_chat.say_loop( )
	find_vote_controllers( )

	colors.box = keys.clr_custom_box:get_value( )
	colors.text = keys.clr_custom_text:get_value( )
	colors.tip_alpha = keys.sl_tip_alpha:get_value( )
end )