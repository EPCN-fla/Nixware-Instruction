-----------------------------------------------------------------------------------------------------------------------------------------\
--Credits--                                                                                                                                                                                          /
--Доработан:AnimeshnikKen--                                                                                                                                                     \
--Создатель:Lunatrius--                                                                                                                                                                 /
--Официальная тема:https://nixware.cc/threads/14169/--                                                                                                    \
--Огромное спасибо за помощь:linius:https://nixware.cc/members/5936(твой труд не будет проёбан зря)/--     /
--P.S KUKURUZKA top--                                                                                                                                                                  \
-----------------------------------------------------------------------------------------------------------------------------------------/
text_font = renderer.setup_font( "nix/fonts/MuseoSansBlack.ttf", 13, 8 )
ui_color = ui.get_color_edit( "misc_ui_color" )

ffi.cdef[[ struct c_color { unsigned char clr[4]; }; ]]
console_color = ffi.new('struct c_color'); console_color.clr[3] = 255;

updated = false

function add_colored_message( text, once )

	if not updated then
		engine_cvar = ffi.cast("void***", se.create_interface("vstdlib.dll", "VEngineCvar007"))
		console_print = ffi.cast("void(__cdecl*)(void*, const struct c_color&, const char*, ...)", engine_cvar[0][25])
	end

	if not once then
		return
	end

	local new_color = ui_color:get_value()

	console_color.clr[0] = new_color.r
	console_color.clr[1] = new_color.g 
	console_color.clr[2] = new_color.b

	console_print(engine_cvar, console_color, "[neverwin.cc] "..tostring(text).."\n")

	updated = true

end

messages = {}
messages.text = ""
messages.bg_position = 0
messages.once = true

function add_message( text )
	table.insert(messages, { text=tostring(text), time=globalvars.get_current_time() + 2.5, bg_position=0, once=true })
end

client.register_callback("paint", function()

	if not engine.is_connected() then updated = false end

	local current_time = globalvars.get_current_time()

	local last_y_position = 1

	for i = 1,#messages do

		local msg = messages[i]
		msg.bg_position = (msg.time - globalvars.get_current_time()) > 1.35 and math.min(msg.bg_position + 50, engine.get_screen_size().x / 3.15 ) or (msg.time - globalvars.get_current_time()) < 0.15 and math.max(msg.bg_position - 50, 0 ) or engine.get_screen_size().x / 3.15

		if msg.time - globalvars.get_current_time() > 0 then
			render_message( msg.text, last_y_position, msg.bg_position )
			add_colored_message( msg.text, msg.once )
			msg.once = false
		else
			table.remove(messages, i)
		end

		last_y_position = last_y_position + 16

	end

end)

function render_message( text, y_position, bg_position )

	filled_rect( false, y_position, color_t.new( 5, 21, 39, 255 ), bg_position )
	filled_rect( true, y_position, color_t.new( 32, 213, 225, 255 ), bg_position )
	message( text, y_position, bg_position )

end

function filled_rect( is_end, y_position, color, bg_position )
	renderer.rect_filled( vec2_t.new( is_end and bg_position - 5 or 0, y_position ), vec2_t.new(  bg_position, y_position + 15 ), color )
end

function message( text, y_position, bg_position )
	renderer.text( text, text_font, vec2_t.new( -(engine.get_screen_size().x / 3.15) + 15 + bg_position, y_position + 1 ), 13, color_t.new( 255, 255, 255, 255 )  )
end

client.register_callback("shot_fired", function(info)

	local shot_result, shot_target, target_hitbox, shot_damage = info.result, info.target, info.hitbox+1, info.server_damage

	if shot_result == "" then
		return
	end

	local temp_name = engine.get_player_info( shot_target:get_index() ).name
	local target_name = string.len(temp_name) > 40 and string.lower( string.sub( temp_name, 0, 40 ) ).."..." or string.lower(temp_name)

	local message_text = string.format('missed shot due to %s (%s)', shot_result, get_hitbox(target_hitbox))

	if shot_result == 'hit' then
		message_text = string.format('give damage %d in %s', shot_damage, get_hitbox(target_hitbox))
	end

	add_message( message_text )

end)

se.register_event("item_purchase") --flshbang, incgrenade, smokegrenade, hegrenade, decoy

client.register_callback("fire_game_event", function(event)

	if event:get_name() == "player_hurt" then

		local event_player   = engine.get_player_for_user_id( event:get_int( "userid", -1 ) )
		local event_attacker = engine.get_player_for_user_id( event:get_int( "attacker", -1 ) )
		local local_player   = engine.get_local_player()
		local event_damage   = event:get_int( "dmg_health", -1 )
		local event_hitbox   = event:get_int( "hitgroup", -1 )

		if event_player == local_player then
			
			local temp_name = engine.get_player_info( event_attacker ).name
			local event_name = string.len(temp_name) > 40 and string.lower( string.sub( temp_name, 0, 40 ) ).."..." or string.lower(temp_name)

			local message_text = (temp_name == "" and "world" or event_name ) .. " did " .. tostring(event_damage) .. (temp_name == "" and " to you" or " damage in your " .. get_hitbox( event_hitbox ))

			add_message( message_text )

		end

	end

	if event:get_name() == "item_purchase" then

		local local_player = engine.get_local_player()
		local event_player = engine.get_player_for_user_id( event:get_int( "userid", -1 ) )
		local event_weapon = string.sub( event:get_string( "weapon", "unk" ), 8, -1 )

		if event_player ~= local_player then

			local temp_name = engine.get_player_info( event_player ).name
			local event_name = string.len(temp_name) > 40 and string.lower( string.sub( temp_name, 0, 40 ) ).."..." or string.lower(temp_name)

			local message_text = event_name .. " purchased " .. get_weapon( event_weapon )

			add_message( message_text )
		end

	end

end)

hitboxes = { 
	"head", 
	"neck", 
	"pelvis", 
	"belly", 
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
	"left forearm",
	"hitbox max"
}

function get_hitbox(hitbox)
	return hitboxes[hitbox]
end

function get_weapon(event_weapon)

	if event_weapon == "usp_silencer" then
		return "usp-s"
	elseif event_weapon == "m4a1_silencer" then
		return "m4a1-s"
	elseif event_weapon == "vlar" then
		return "armor"
	elseif event_weapon == "saultsuit" then
		return "helmet + armor"
	end

	return event_weapon

end