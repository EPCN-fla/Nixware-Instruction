local function RGB(h, s, v, a)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

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

local rainbow = 0.00

local function on_paint()
    local screen = engine.get_screen_size()
	local line = RGB(rainbow, 1, 1, 1)
	
    rainbow = rainbow + (globalvars.get_frame_time() * 0.1)

    if rainbow > 1.0 then
        rainbow = 0.0
    end
	
    renderer.line(vec2_t.new(0, 0), vec2_t.new(screen.x, 0), line)
    renderer.line(vec2_t.new(0, 1), vec2_t.new(screen.x, 1), line)
end

client.register_callback("paint", on_paint)