local old_counter = 20
local counter = 20

local thidperson_bind = ui.add_key_bind("Thirdperson bind", "thirdperson_bind", 0, 2)

ui.get_key_bind("visuals_other_thirdperson_bind"):set_key(0x00)
ui.get_key_bind("visuals_other_thirdperson_bind"):set_type(0)
ui.get_check_box("visuals_other_thirdperson"):set_value(false)
ui.get_check_box("visuals_other_force_thirdperson"):set_value(false)

client.register_callback("frame_stage_notify", function(stage) 
	if thidperson_bind:is_active() then

		if counter ~= 150 then
		 	counter = counter + 2
		end

	else

		if counter ~= 20 then
			counter = counter - 2
	   end

	end
	
	if old_counter ~= counter then
		engine.execute_client_cmd("cam_idealdist " .. counter .. "")
		old_counter = counter
	end

	if counter >= 40 then
		ui.get_check_box("visuals_other_thirdperson"):set_value(true)
		ui.get_check_box("visuals_other_force_thirdperson"):set_value(true)
	else
		ui.get_check_box("visuals_other_thirdperson"):set_value(false)
		ui.get_check_box("visuals_other_force_thirdperson"):set_value(false)
	end
end)

local function on_unload()
	engine.execute_client_cmd("cam_idealdist 150")
end

client.register_callback("unload", on_unload)