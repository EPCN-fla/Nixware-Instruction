local screen_ind = ui.add_multi_combo_box("Screen indicators", "screen_ind", { "Keybinds", "Watermark" }, { false, false })
local watermarkname = ui.add_text_input("Custom watermark name", "watermarkname", "gamesense.pub")
local watermarkusername = ui.add_text_input("Custom watermark username", "watermarkusername", "")
local animation_type = ui.add_combo_box("Animation type", "animation_type", { "Skeet", "Neverlose" }, 0)
local auto_resize_width = ui.add_check_box("Auto resize width", "auto_resize_width", false)
local style_line = ui.add_combo_box("Style line", "style_line", { "Static", "Fade", "Reverse fade", "Gradient", "Skeet", "Chroma" }, 0)
local chroma_dir = ui.add_combo_box("Chroma direction", "chroma_dir", { "Left", "Right", "Static" }, 0)
local color_line = ui.add_color_edit("Color line", "color_line", true, color_t.new(52, 164, 235, 255))
local keybinds_x = ui.add_slider_int("keybind_x", "keybinds_x", 0, engine.get_screen_size().x, 345)
local keybinds_y = ui.add_slider_int("keybind_y", "keybinds_y", 0, engine.get_screen_size().y, 215)

local verdana = renderer.setup_font("C:/windows/fonts/verdana.ttf", 12, 0)
local types = { "always", "hold", "toggle", "disabled" }

local function hsv2rgb(h, s, v, a)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return color_t.new(r * 255, g * 255, b * 255, a * 255)
end
function math.lerp(a, b, t) return a + (b - a) * t end
local function drag(x, y, width, height, xmenu, ymenu, item)
    local cursor = renderer.get_cursor_pos()
    if (cursor.x >= x) and (cursor.x <= x + width) and (cursor.y >= y) and (cursor.y <= y + height) then
        if client.is_key_pressed(1) and item[1] == 0 then
            item[1] = 1
            item[2] = x - cursor.x
            item[3] = y - cursor.y
        end
    end
    if not client.is_key_pressed(1) then item[1] = 0 end
    if item[1] == 1 and ui.is_visible() then
		xmenu:set_value(cursor.x + item[2])
		ymenu:set_value(cursor.y + item[3])
    end
end
local function filledbox(x, y, w, h, al)
	local rgb = hsv2rgb(globalvars.get_real_time() / 4, 0.9, 1, 1)
	local chromd = chroma_dir:get_value()
	local col = color_line:get_value()
	local stl = style_line:get_value()

	if stl ~= 4 then
	renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(15, 15, 15, col.a * al))
	else
	renderer.rect_filled(vec2_t.new(x, y - 2), vec2_t.new(x + w, y + h), color_t.new(30, 30, 30, col.a * al))
	renderer.rect_filled_fade(vec2_t.new(x + 1, y - 1), vec2_t.new(x + w / 2, y), color_t.new(0, 213, 255, 255 * al), color_t.new(204, 18, 204, 255 * al), color_t.new(204, 18, 204, 255 * al), color_t.new(0, 213, 255, 255 * al))
	renderer.rect_filled_fade(vec2_t.new(x + (w / 2), y - 1), vec2_t.new(x + w - 1, y), color_t.new(204, 18, 204, 255 * al), color_t.new(255, 250, 0, 255 * al), color_t.new(255, 250, 0, 255 * al), color_t.new(204, 18, 204, 255 * al))
	end
	
	gradient_color = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(0, 0, 0, 255 * al) or stl == 2 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 3 and color_t.new(0, 213, 255, 255 * al) or stl == 5 and color_t.new(chromd==1 and rgb.g or rgb.r, chromd==1 and rgb.b or rgb.g, chromd ==1 and rgb.g or rgb.b, 255 * al) or color_t.new(0, 0, 0, 0)
	gradient_color1 = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 2 and color_t.new(0, 0, 0, 255 * al) or stl == 3 and color_t.new(204, 18, 204, 255 * al) or stl == 5 and color_t.new(chromd==2 and rgb.r or rgb.b, chromd==2 and rgb.g or rgb.r, chromd==2 and rgb.b or rgb.g, 255 * al) or color_t.new(0, 0, 0, 0)
	gradient_color2 = stl == 0 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 1 and color_t.new(0, 0, 0, 255 * al) or stl == 2 and color_t.new(col.r, col.g, col.b, 255 * al) or stl == 3 and color_t.new(255, 250, 0, 255 * al) or stl == 5 and color_t.new(chromd==0 and rgb.g or rgb.r, chromd==0 and rgb.b or rgb.g, chromd ==0 and rgb.g or rgb.b, 255 * al) or color_t.new(0, 0, 0, 0)

	if stl ~= 4 then
		renderer.rect_filled_fade(vec2_t.new(x, y - 2), vec2_t.new(x + w / 2, y), gradient_color, gradient_color1, gradient_color1, gradient_color)
		renderer.rect_filled_fade(vec2_t.new(x + (w / 2), y - 2), vec2_t.new(x + w, y), gradient_color1, gradient_color2, gradient_color2, gradient_color1)
	end
end
--indicators
local item = { 0, 0, 0 }
local animwidth = 0;
local alpha = { 0 }
local bind = {
["Double tap"] = {reference = ui.get_key_bind("rage_active_exploit_bind"), exploit = 2, add = 0, multiply = 0},
["Hide shots"] = {reference = ui.get_key_bind("rage_active_exploit_bind"), exploit = 1, add = 0, multiply = 0},
["Inverter"] = {reference = ui.get_key_bind("antihit_antiaim_flip_bind"), exploit = 0, add = 0, multiply = 0},
["Auto peek"] = {reference = ui.get_key_bind("antihit_extra_autopeek_bind"), exploit = 0, add = 0, multiply = 0},
["Slow walk"] = {reference = ui.get_key_bind("antihit_extra_slowwalk_bind"), exploit = 0, add = 0, multiply = 0},
["Fake duck"] = {reference = ui.get_key_bind("antihit_extra_fakeduck_bind"), exploit = 0, add = 0, multiply = 0},
["Jump bug"] = {reference = ui.get_key_bind("misc_jump_bug_bind"), exploit = 0, add = 0, multiply = 0},
["Edge jump"] = {reference = ui.get_key_bind("misc_edge_jump_bind"), exploit = 0, add = 0, multiply = 0},
--["Название бинда"] = {reference = получение бинда, exploit = 0 (это не трогать), add = 0 (это не трогать), multiply = 0 (это не трогать)},
};
client.register_callback("paint", function()
	--ui visible
	local screen = screen_ind:get_value(1) or screen_ind:get_value(0)
	watermarkname:set_visible(screen_ind:get_value(1))
	watermarkusername:set_visible(screen_ind:get_value(1))
	animation_type:set_visible(screen_ind:get_value(0))
	auto_resize_width:set_visible(screen_ind:get_value(0))
	style_line:set_visible(screen) chroma_dir:set_visible(style_line:get_value() == 5) color_line:set_visible(screen)
	keybinds_x:set_visible(false) keybinds_y:set_visible(false)
	--timer
	local function watermark()
	--watermark
		if screen_ind:get_value(1) then
			local wtname = ""
			local user = ""
			if watermarkname:get_value() ~= "" then wtname = tostring(watermarkname:get_value()) else wtname = "nixware.cc" end
			if watermarkusername:get_value() ~= "" then user = tostring(watermarkusername:get_value()) else user = client.get_username() end
			local username = client.get_username()
			local ping = se.get_latency()
			local tickcount = 1 / globalvars.get_interval_per_tick()
			local text = ""
			if engine.is_connected() then
			text = wtname .. " | " .. user .. " | delay: " .. ping .. "ms | " .. tickcount .. "tick | " .. os.date("%X") else 
			text = wtname .. " | " .. user .. " | " .. os.date("%X") end
			local screen = engine.get_screen_size()
			local w = renderer.get_text_size(verdana, 12, text).x + 10
			local h = 17
			local x = screen.x - w - 10
			filledbox(x, 8, w, h, 1)
			renderer.text(text, verdana, vec2_t.new(x + 6, 10 + 1), 12, color_t.new(0, 0, 0, 255))
			renderer.text(text, verdana, vec2_t.new(x + 5, 10), 12, color_t.new(255, 255, 255, 255))
		end
	end
	--keybinds
	local function keybinds()
		if screen_ind:get_value(0) and engine.is_connected() then
			local pos = {x = keybinds_x:get_value(), y = keybinds_y:get_value()}
			local alphak, keybinds = {}, {}
			local width, maxwidth = 25, 0;
			local height = 17;
			local bind_y = height + 4
			
			for i,v in pairs(bind) do
				local exploits = ui.get_combo_box("rage_active_exploit"):get_value(); v.add = math.lerp(v.add, v.reference:is_active() and 255 or 0, 0.1); v.multiply = v.add > 4 and 1 or 0;
				if v.add > 4 then if v.exploit == 0 then table.insert(keybinds, i) end; if v.exploit ~= 0 and exploits == v.exploit then table.insert(keybinds, i) end; end;
				if v.exploit == 0 and v.reference:is_active() then table.insert(alphak, i) end; if v.exploit ~= 0 and exploits == v.exploit and v.reference:is_active() then table.insert(alphak, i) end;
			end
			if #alphak ~= 0 or ui.is_visible() then alpha[1] = math.lerp(alpha[1], 255, 0.1) end; if #alphak == 0 and not ui.is_visible() then alpha[1] = math.lerp(alpha[1], 0, 0.1) end		
			for k,f in pairs(keybinds) do if renderer.get_text_size(verdana, 12, f .. "["..types[bind[f].reference:get_type() + 1].."]").x > maxwidth then maxwidth = renderer.get_text_size(verdana, 12, f .. "["..types[bind[f].reference:get_type() + 1].."]").x; end; end
			if maxwidth == 0 then maxwidth = 50 end; width = width + maxwidth; if width < 130 then width = 130 end if animwidth == 0 then animwidth = width end; animwidth = math.lerp(animwidth, width, 0.1)
			w = auto_resize_width:get_value() and (animation_type:get_value() == 1 and animwidth or width) or 150
			for k,f in pairs(keybinds) do  
				local v = bind[f]; bind_y = bind_y + (animation_type:get_value() == 1 and 20 * (v.add / 255) or 20 * v.multiply); plus = bind_y - (animation_type:get_value() == 1 and 20 * (v.add / 255) or 20 * v.multiply);
				renderer.text(f, verdana, vec2_t.new(pos.x + 5, pos.y + plus + 1), 12, color_t.new(0, 0, 0, 255 * (v.add / 255)))
				renderer.text(f, verdana, vec2_t.new(pos.x + 4, pos.y + plus), 12, color_t.new(255, 255, 255, 255 * (v.add / 255)))
				renderer.text("["..types[v.reference:get_type() + 1].."]", verdana, vec2_t.new(pos.x + w - renderer.get_text_size(verdana, 12, "["..types[v.reference:get_type() + 1].."]").x - 3, pos.y + plus + 1), 12, color_t.new(0, 0, 0, 255 * (v.add / 255)))
				renderer.text("["..types[v.reference:get_type() + 1].."]", verdana, vec2_t.new(pos.x + w - renderer.get_text_size(verdana, 12, "["..types[v.reference:get_type() + 1].."]").x - 4, pos.y + plus), 12, color_t.new(255, 255, 255, 255 * (v.add / 255)))
			end
			if alpha[1] > 1 then
				filledbox(pos.x, pos.y, w, height, (alpha[1] / 255))
				renderer.text("keybinds", verdana, vec2_t.new(pos.x + (w /2) - (renderer.get_text_size(verdana, 12, "keybinds").x /2) + 1, pos.y + 3), 12, color_t.new(0, 0, 0, 255 * (alpha[1] / 255)))
				renderer.text("keybinds", verdana, vec2_t.new(pos.x + (w /2) - (renderer.get_text_size(verdana, 12, "keybinds").x /2), pos.y + 2), 12, color_t.new(255, 255, 255, 255 * (alpha[1] / 255)))
				drag(pos.x, pos.y, w, height + 2, keybinds_x, keybinds_y, item)
			end
		end
	end
	watermark(); keybinds();
end)