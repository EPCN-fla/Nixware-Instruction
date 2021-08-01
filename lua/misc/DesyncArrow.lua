local font_verdana = renderer.setup_font("C:/windows/fonts/verdana.ttf", 25, 32)
local screen = engine.get_screen_size()
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")

local antihit_antiaim_flip_bind = ui.get_key_bind('antihit_antiaim_flip_bind')

local function on_paint()
    local local_player = engine.get_local_player()
    local me = entitylist.get_entity_by_index(local_player)

    if me:get_prop_int(m_iHealth) < 0 or not engine.is_in_game() then
        return
    end

    if antihit_antiaim_flip_bind:is_active() then
        renderer.text('<', font_verdana, vec2_t.new(screen.x / 2 - 95, screen.y / 2 - 10), 25, color_t.new(0, 0, 0, 220))
        renderer.text('>', font_verdana, vec2_t.new(screen.x / 2 + 72, screen.y / 2 - 10), 25, color_t.new(0, 255, 0, 220))
    else
        renderer.text('<', font_verdana, vec2_t.new(screen.x / 2 - 95, screen.y / 2 - 10), 25, color_t.new(0, 255, 0, 220))
        renderer.text('>', font_verdana, vec2_t.new(screen.x / 2 + 72, screen.y / 2 - 10), 25, color_t.new(0, 0, 0, 220))
    end
end

client.register_callback("paint", on_paint);