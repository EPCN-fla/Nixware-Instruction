
local screen = engine.get_screen_size()
local AW = ui.add_key_bind("autowall", "AW", 0, 2)
local AF = ui.add_key_bind("autofire", "AF", 0, 2)
local baimb = ui.add_key_bind("body aim", "baimb", 0, 2)
local idnw = ui.add_check_box("Indicators", "idnw", true)
local sx = ui.add_slider_int('Position x', 'sr_indicators_pos_x', 0, screen.x, 20)
local sy = ui.add_slider_int('Position y', 'sr_indicators_pos_y', 0, screen.y, 120)

local wall_pen = ui.get_check_box("rage_wall_penetration")
local res_r = ui.get_check_box("rage_desync_correction")
local rage_bind = ui.get_key_bind("rage_enable_bind")

client.register_callback("paint", function()
    if AW:is_active() then
        wall_pen:set_value(true)
    else
        wall_pen:set_value(false)
    end
end)

client.register_callback("paint", function()
    if AF:is_active() then
        rage_bind:set_key(0)
        rage_bind:set_type(0)
    else
        rage_bind:set_key(1)
        rage_bind:set_type(1)
    end
end)

client.register_callback("create_move", function()
    local entity = entitylist.get_players(0)

	if baimb:is_active() then
		for i = 1, #entity do
			local player = entity[i]

			ragebot.override_hitscan(player:get_index(), 0, false)
			ragebot.override_hitscan(player:get_index(), 1, true)
			ragebot.override_hitscan(player:get_index(), 2, true)
			ragebot.override_hitscan(player:get_index(), 3, true)
			ragebot.override_hitscan(player:get_index(), 4, false)
			ragebot.override_hitscan(player:get_index(), 5, false)

		end
	end
end)

client.register_callback("paint", function()
    if misc_resolver:is_active() then
        res_r:set_value(false)
    else
        res_r:set_value(true)
    end
end)


local font56 = renderer.setup_font('C:/Windows/Fonts/Verdana.ttf', 30, 5)

local indicators = {}

local binds = {
    { name = 'FOV',             type = 'static' },
	{ name = 'AW',        cfg = AW, type = 'key_bind'},
    { name = 'AUTO',        cfg = AF, type = 'key_bind'},
    { name = 'BAIM',            cfg = baimb, type = 'key_bind'},
}

local function add_indicator(indicator)
    table.insert(indicators, indicator)
end

local function render_text(text, x, y, color)
    renderer.text(tostring(text), font56, vec2_t.new(x, y + 1), 30, color_t.new(0, 0, 0, 255))
    renderer.text(tostring(text), font56, vec2_t.new(x, y), 30, color)
end

local function render_filled_rect(x, y, w, h, color)
    renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x+w, y+h), color)
end

local function draw_indicators()
    local x = sx:get_value()
    local h = screen.y - 50 - sy:get_value()
    local y = 30 * #indicators
    for key, value in pairs(indicators) do
        local addition = 0
        local sizes = renderer.get_text_size(font56, 30, value.text)
       
        render_text(value.text, x, h - y, value.color)
        addition = addition + sizes.y
        y = y - addition
    end
end

local function on_paint()
    --[[if not indw:get_value() then 
        return
    end--]]

    if not engine.is_in_game() then return end
    local player = entitylist.get_local_player()
    indicators = {}
    if not player or not player:is_alive() then return end
    for i = 1, #binds do
        local bind = binds[i]
        local name = bind.name
           
        if type(name) == 'table' then
            name = name[e + 1]
        end

        local information = {}

        local fovr = ui.get_slider_float("rage_fov")
        local fov = fovr:get_value()

        if bind.type == 'static' then
            if name == 'FOV' then
                information = {
                    text = name .. " " .. tostring(fov),
                    color = color_t.new(255, 255, 255, 255),
                }
            end
        elseif bind.type == 'key_bind' then
            if bind.cfg:is_active() then
                information = {
                    text = name,
                    color = color_t.new(165, 135, 203, 230)
                }
            end
        end

        if information.text then
            add_indicator(information)
        end
    end

    draw_indicators()
end

client.register_callback('paint', on_paint)