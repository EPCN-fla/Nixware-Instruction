--[[
    modified by Fla1337
    copy from Semi-Rage Helper: https://nixware.cc/threads/12530/
--]]

local screen = engine.get_screen_size()
local legb = ui.add_key_bind("wash leg", "legb", 0, 2)

local idnw = ui.add_check_box("Indicators", "idnw", true)
local sx = ui.add_slider_int('Position x', 'sr_indicators_pos_x', 0, screen.x, 0)
local sy = ui.add_slider_int('Position y', 'sr_indicators_pos_y', 0, screen.y, 295)

client.register_callback("create_move", function()
    local entity = entitylist.get_players(0)

	if legb:is_active() then
		for i = 1, #entity do
			local player = entity[i]

			ragebot.override_hitscan(player:get_index(), 0, false)
			ragebot.override_hitscan(player:get_index(), 1, false)
			ragebot.override_hitscan(player:get_index(), 2, false)
			ragebot.override_hitscan(player:get_index(), 3, false)
			ragebot.override_hitscan(player:get_index(), 4, true)
			ragebot.override_hitscan(player:get_index(), 5, true)

		end
	end
end)

local font56 = renderer.setup_font('C:/Windows/Fonts/Verdana.ttf', 30, 5)

local indicators = {}

local binds = {
    { name = 'LAIM',            cfg = legb, type = 'key_bind'},
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

        if bind.type == 'key_bind' then
            if bind.cfg:is_active() then
                information = {
                    text = name,
                    color = color_t.new(0, 255, 0, 255)
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