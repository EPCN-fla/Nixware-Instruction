local lowdelta = ui.add_key_bind("Low Delta On Key","low_delta", 0, 1)
local desync = ui.get_slider_int("antihit_antiaim_desync_length")
local desync_lua = ui.add_slider_int("Desync length", "desync_lua", 0, 60, 40)

local function cydelta()

    if lowdelta:is_active() then
        desync:set_value(10) --- Desync value when lowdelta bind actived
    else
        local desync_backup = desync_lua:get_value()
        desync:set_value(desync_backup) --- Desync value when lowdelta bind not actived
    end
end


client.register_callback("paint", cydelta)