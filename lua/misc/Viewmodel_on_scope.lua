local line_color_in_game = ui.add_color_edit("Color", "line_color_in_game", true, color_t.new(255, 255, 255, 255))
local line_color_in_game_second = ui.add_color_edit("Color second", "line_color_in_game_second", true, color_t.new(255, 255, 255, 0))
local line_width = ui.add_slider_int("Line width", "line_width", 0, 1250, 150)
local line_length = ui.add_slider_int("Line length", "line_length", 25, 960, 25)
local viewmodel_on_scope = ui.add_check_box("Viewmodel on scope", "viewmodel_on_scope", true)

local visuals_other_removals = ui.get_multi_combo_box("visuals_other_removals")
visuals_other_removals:set_value(0, false)

local function on_paint()
   -- if not engine.is_in_game() then return end

    local player = entitylist.get_local_player()
    local is_scoped = player:get_prop_bool( se.get_netvar( "DT_CSPlayer", "m_bIsScoped" ) )

    local view_scope = viewmodel_on_scope:get_value()

    local r_drawvgui = se.get_convar("r_drawvgui")
    local fov_cs_debug = se.get_convar("fov_cs_debug")

    if is_scoped then
        local screensize = engine.get_screen_size()

        local line_color = line_color_in_game:get_value()
        local r_first = line_color.r
        local g_first = line_color.g
        local b_first = line_color.b
        local a_first = line_color.a

        local line_color_second = line_color_in_game_second:get_value()
        local r_second = line_color_second.r
        local g_second = line_color_second.g
        local b_second = line_color_second.b
        local a_second = line_color_second.a

        local width = line_width:get_value()
        local length = line_length:get_value()

		renderer.rect_filled_fade(vec2_t.new(screensize.x/2 + width, screensize.y/2 + 1),  vec2_t.new(screensize.x/2 + length, screensize.y/2), color_t.new(r_second, g_second, b_second, a_second), color_t.new(r_first, g_first, b_first, a_first), color_t.new(r_first, g_first, b_first, a_first),     color_t.new(r_second, g_second, b_second, a_second)) -- LEFT
        renderer.rect_filled_fade(vec2_t.new(screensize.x/2 - width, screensize.y/2 + 1),  vec2_t.new(screensize.x/2 - length, screensize.y/2), color_t.new(r_second, g_second, b_second, a_second), color_t.new(r_first, g_first, b_first, a_first), color_t.new(r_first, g_first, b_first, a_first),     color_t.new(r_second, g_second, b_second, a_second)) -- RIGHT
        renderer.rect_filled_fade(vec2_t.new(screensize.x/2 + 1, screensize.y/2 - length), vec2_t.new(screensize.x/2, screensize.y/2 - width),  color_t.new(r_first, g_first, b_first, a_first),     color_t.new(r_first, g_first, b_first, a_first), color_t.new(r_second, g_second, b_second, a_second), color_t.new(r_second, g_second, b_second, a_second)) -- UP
        renderer.rect_filled_fade(vec2_t.new(screensize.x/2 + 1, screensize.y/2 + length), vec2_t.new(screensize.x/2, screensize.y/2 + width),  color_t.new(r_first, g_first, b_first, a_first),     color_t.new(r_first, g_first, b_first, a_first), color_t.new(r_second, g_second, b_second, a_second), color_t.new(r_second, g_second, b_second, a_second)) -- DOWN

        r_drawvgui:set_float(0)
    else
        r_drawvgui:set_float(1)
    end

    if view_scope and is_scoped then
        fov_cs_debug:set_float(90)
    else
        fov_cs_debug:set_float(0)
    end
end
client.register_callback("paint", on_paint)

