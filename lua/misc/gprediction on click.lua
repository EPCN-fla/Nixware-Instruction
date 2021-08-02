local function main()
	if client.is_key_pressed(1) or client.is_key_pressed(2) then
		ui.get_check_box("visuals_other_grenade_prediction"):set_value(true)
	else
		ui.get_check_box("visuals_other_grenade_prediction"):set_value(false)
	end
end
client.register_callback("paint", main)