local rpg_ball_texture = renderer.setup_texture("E:/Game (SSD)/steamapps/common/Counter-Strike Global Offensive/nix/images/flower.png")

local screensize = engine.get_screen_size()

local rpg_ball_on  = ui.add_check_box("rpg ball", "rpg_ball_on", false)

local rpg_ballx = ui.add_slider_int("rpg ball x", "rpg_ball_x", 0, screensize.x, 10)

local rpg_bally = ui.add_slider_int("rpg ball y", "rpg_ball_y", 0, screensize.y, 10)

local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")

local Verdana_bold = renderer.setup_font("C:/windows/fonts/verdana.ttf", 15, 1)



local function render_image(image, x, y, w, h)

    renderer.texture(image, vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(255, 255, 255, 255))

end



local function rect_filled_fade(x,y,w,h,c1,c2,c3,c4)

    renderer.rect_filled_fade( vec2_t.new(x, y), vec2_t.new(x + w, y + h) ,c1,c2,c3,c4)

end



local function rect_filled(x,y,w,h)

    renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(45,45,45, 255))

end



local function text(x,y,te,size,color)

    renderer.text(te,Verdana_bold, vec2_t.new(x, y), size, color)

end



local function render_arc(x, y, radius, radius_inner, start_angle, end_angle, segments, color)

        local segments = 360 / segments;

        for i = start_angle,start_angle + end_angle,segments / 2 do

            local rad = i * math.pi / 180;

            local rad2 = (i + segments) * math.pi / 180;

            local rad_cos = math.cos(rad);

            local rad_sin = math.sin(rad);

            local rad2_cos = math.cos(rad2);

            local rad2_sin = math.sin(rad2);

            local x1_inner = x + rad_cos * radius_inner;

            local y1_inner = y + rad_sin * radius_inner;

            local x1_outer = x + rad_cos * radius;

            local y1_outer = y + rad_sin * radius;

            local x2_inner = x + rad2_cos * radius_inner;

            local y2_inner = y + rad2_sin * radius_inner;

            local x2_outer = x + rad2_cos * radius;

            local y2_outer = y + rad2_sin * radius;

            renderer.filled_polygon({ vec2_t.new(x1_outer, y1_outer),vec2_t.new(x2_outer, y2_outer),vec2_t.new(x1_inner, y1_inner) },color)

            renderer.filled_polygon({ vec2_t.new(x1_inner, y1_inner),vec2_t.new(x2_outer, y2_outer),vec2_t.new(x2_inner, y2_inner) },color)

    end

end

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

local function rpg_paint()

    if not engine.is_in_game() then

        return

    end

    local local_player = engine.get_local_player()

    local me = entitylist.get_entity_by_index(local_player)

    local health = me:get_prop_int(m_iHealth)

    local heal = "" .. health .. "hp"

    local username = client.get_username()

    if rpg_ball_on:get_value() then

    render_image(rpg_ball_texture,rpg_ballx:get_value()-5,rpg_bally:get_value()-5,90,90)



    rect_filled_fade(rpg_ballx:get_value() - 80,rpg_bally:get_value() + 30,20,20,color_t.new(45,45,45,0),color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,0))

    rect_filled_fade(rpg_ballx:get_value() - 60,rpg_bally:get_value() + 30,40,20,color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255))



    rect_filled_fade(rpg_ballx:get_value() + 212,rpg_bally:get_value() + 5,20,20,color_t.new(45,45,45,255),color_t.new(45,45,45,0),color_t.new(45,45,45,0),color_t.new(45,45,45,255))

    rect_filled_fade(rpg_ballx:get_value() + 92,rpg_bally:get_value() + 5,120,20,color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255))



    rect_filled_fade(rpg_ballx:get_value() + 222,rpg_bally:get_value() + 55,20,20,color_t.new(45,45,45,255),color_t.new(45,45,45,0),color_t.new(45,45,45,0),color_t.new(45,45,45,255))

    rect_filled_fade(rpg_ballx:get_value() + 92,rpg_bally:get_value() + 55,130,20,color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255),color_t.new(45,45,45,255))



    text(rpg_ballx:get_value() - 61,rpg_bally:get_value() + 33,heal,13,color_t.new(250 - health * 2.5, 5 + health * 2.5, 0, 255))



    text(rpg_ballx:get_value() + 104,rpg_bally:get_value() + 8,username,12,color_t.new(255,255,255, 255))

    text(rpg_ballx:get_value() + 149,rpg_bally:get_value() + 8,"|  Welcome !",12,color_t.new(255,255,255, 255))



    text(rpg_ballx:get_value() + 103,rpg_bally:get_value() + 58,"Never win & Get beaten",12,color_t.new(255,255,255, 255))



    render_arc(rpg_ballx:get_value() + 40,rpg_bally:get_value() + 40,62,47, 270, 360,50,color_t.new(45,45,45, 255))

    render_arc(rpg_ballx:get_value() + 40,rpg_bally:get_value() + 40,62,61, 0, health * 3.6, 50,color_t.new(250 - health * 2.5, 5 + health * 2.5, 0, 255))

    render_arc(rpg_ballx:get_value() + 40,rpg_bally:get_value() + 40,47,44, 0, 360,50,RGB(rainbow, 1, 1, 1))
    
    rainbow = rainbow + (globalvars.get_frame_time() * 0.15)
    
    if rainbow > 1.0 then
        rainbow = 0.0
    end

    end

end

client.register_callback("paint", rpg_paint)
