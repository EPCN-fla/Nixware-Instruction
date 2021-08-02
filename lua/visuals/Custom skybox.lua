local skyboxes = {
    'custom',
    'cs_tibet',
    'embassy',
    'italy',
    'jungle',
    'office',
    'sky_cs15_daylight01_hdr',
    'sky_csgo_cloudy01',
    'sky_csgo_night02',
    'sky_csgo_night02b',
    'sky_day02_05_hdr',
    'sky_day02_05',
    'sky_dust',
    'vertigo_hdr',
    'vertigo',
}

local vis_skybox = ui.add_combo_box('skybox', 'vis_skybox', skyboxes, 0)
local custom_skybox_name = ui.add_text_input('custom skybox', 'vis_custom_skybox', '')
local sv_skyname = se.get_convar('sv_skyname')

local function on_create_move()
    local skybox = vis_skybox:get_value() + 1

    if skybox == 1 and custom_skybox_name:get_value() == '' then
        return
    end

    local sky = skybox > 1 and skyboxes[skybox] or custom_skybox_name:get_value()

    if sv_skyname:get_string() == sky then return end

    sv_skyname:set_string(sky)
end

client.register_callback('create_move', on_create_move)
