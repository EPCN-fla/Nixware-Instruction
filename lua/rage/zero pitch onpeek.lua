local pitch_onpeek = ui.add_key_bind("Zero Pitch On Peek", "pitch_onpeek", 0, 1)
local antihit_antiaim_pitch = ui.get_combo_box("antihit_antiaim_pitch")

client.register_callback("create_move", function(cmd) 
    if pitch_onpeek:is_active() then
        antihit_antiaim_pitch:set_value(2)
    else
        antihit_antiaim_pitch:set_value(1)
    end
end)


