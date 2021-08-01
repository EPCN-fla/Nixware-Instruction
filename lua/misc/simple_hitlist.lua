local screensize = engine.get_screen_size()
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")
local fonts = {
    verdana = renderer.setup_font('c:/windows/fonts/verdana.ttf', 12, 0),
    }

local color_hitlist = ui.add_color_edit("line color", "color_hitlist", true, color_t.new(0,70,140,255))
local style = ui.add_combo_box("hitlist style", "style", {"super minimal", "informative"}, 0)
local hitlog_clear = ui.add_check_box("Hitlist clear table", "hitlog_clear", false)
local hitlog_pos_x = ui.add_slider_int("Hitlist position x", "hitlog_pos_x", 0, screensize.x, 0)
local hitlog_pos_y = ui.add_slider_int("Hitlist position y", "hitlog_pos_y", 0, screensize.y, 0)

local utils = {
    to_rgba = function (params)
        return params[1], params[2], params[3], params[4]
    end,
}

local gui = {
    rect_filled = function(x, y, w, h, color)
        renderer.rect_filled(vec2_t.new(x,y), vec2_t.new(x+w,y+h), color_t.new(utils.to_rgba(color)))
    end,

    draw_text = function (x, y, text)
        renderer.text(tostring(text), fonts.verdana, vec2_t.new(x,y), 12, color_t.new(255, 255, 255, 255))
    end
}

local id = 0
local hitlog = {}

local hitboxes_hit = {
	"head",
	"neck",
	"pelvis",
	"stomach",
	"low chest",
	"chest",
	"up chest",
	"r thigh",
	"l thigh",
	"r calf",
	"l calf",
	"r foot",
	"l foot",
	"r hand",
	"left hand",
	"r up arm", 
	"r forearm",
	"r left arm", 
    "l forearm"
};

local function clear()
    id = 0
    hitlog = {}
end

local function get_damage_color(damage)
    if damage > 90 then
        return { 255, 0, 0, 255 }
    elseif damage > 70 then
        return { 255, 89, 0, 255 }
    elseif damage > 40 then
        return { 255, 191, 0, 255 }
    elseif damage > 1 then
        return { 9, 255, 0, 255 }
    else
        return { 0, 140, 255, 255 }
    end
end

local function get_size()
    if #hitlog > 8 then
        return 8
    end

    return #hitlog
end

local WINDOW_WIDTH = 210

local function on_object(mx, my, pos_x, pos_y, w, h)
    return mx <= pos_x + w and mx >= pos_x and my <= pos_y + h and my >= pos_y
end

local function on_paint()

    if not engine.is_in_game() then return end
    
    if hitlog_clear:get_value() or not engine.is_in_game() then
        clear()
        hitlog_clear:set_value(false)
    end

    local pos_x = hitlog_pos_x:get_value()
    local pos_y = hitlog_pos_y:get_value()

    local size = 18 + 18 * get_size()


    gui.rect_filled(pos_x, pos_y, WINDOW_WIDTH, size, { 22, 20, 26, 100 })
	gui.rect_filled(pos_x, pos_y, WINDOW_WIDTH, 18, { 22, 20, 26, 170 })
    renderer.line(vec2_t.new(pos_x,pos_y), vec2_t.new(pos_x+WINDOW_WIDTH,pos_y), color_hitlist:get_value())


    local text_pos = pos_x + 7
    if style:get_value() == 0 then
        gui.draw_text(text_pos, pos_y + 3, "player")
        text_pos = text_pos + 80
        gui.draw_text(text_pos, pos_y + 3, "result")
        WINDOW_WIDTH = 210
    elseif style:get_value() == 1 then 
        gui.draw_text(text_pos, pos_y + 3, "id")
        text_pos = text_pos + 20
    
        gui.draw_text(text_pos, pos_y + 3, "player")
        text_pos = text_pos + 73
    
        gui.draw_text(text_pos, pos_y + 3, "damage")
        text_pos = text_pos + 50
    
        gui.draw_text(text_pos, pos_y + 3, "hitbox")
        text_pos = text_pos + 78
    
        gui.draw_text(text_pos, pos_y + 3, "hit.c")
        text_pos = text_pos + 35  
    
        gui.draw_text(text_pos, pos_y + 3, "left")
        text_pos = text_pos + 30
    
        gui.draw_text(text_pos, pos_y + 3, "result")
        text_pos = text_pos + 48
    
        gui.draw_text(text_pos, pos_y + 3, "bt")
        text_pos = text_pos + 20
        WINDOW_WIDTH = 358
    end



    for i = 1, get_size(), 1 do
        local data = hitlog[i]

        if data then
            local pitch = pos_x + 10
            local yaw = pos_y + 18 + (i - 1) * 18 + 1

            if style:get_value() == 0 then

                gui.rect_filled(pos_x, yaw - 1, 2, 17, get_damage_color(data.server_damage))

                text_pos = pitch - 3

                gui.draw_text(text_pos, yaw, data.player)
                text_pos = text_pos + 80

                
                if data.server_damage > 0 then
                    gui.draw_text(text_pos, yaw, "-" .. data.server_damage)
                else
                    gui.draw_text(text_pos, yaw, data.result .. " in " .. data.client_hitbox .. " (-" .. data.client_damage .. ")")
                end
            
            elseif style:get_value() == 1 then
                gui.rect_filled(pos_x, yaw - 1, 2, 17, get_damage_color(data.server_damage))
 
                text_pos = pitch - 3
                gui.draw_text(text_pos, yaw, data.id)
                text_pos = text_pos + 20
    
                gui.draw_text(text_pos, yaw, data.player)
                text_pos = text_pos + 73
    
                gui.draw_text(text_pos, yaw, tostring(data.server_damage) .. (data.server_damage == data.client_damage and "" or "(" .. tostring(data.client_damage) .. ")"))
                text_pos = text_pos + 50
            
                gui.draw_text(text_pos, yaw, tostring(data.client_hitbox) .. (data.client_hitbox == data.server_hit and "" or "(" .. tostring(data.server_hit) .. ")"))
                text_pos = text_pos + 78
    
                gui.draw_text(text_pos, yaw, data.hitchance .. "%")
                text_pos = text_pos + 35
    
                gui.draw_text(text_pos, yaw, data.HPrem)
                text_pos = text_pos + 30
    
                gui.draw_text(text_pos, yaw, data.result)
                text_pos = text_pos + 48
            
                gui.draw_text(text_pos, yaw, data.backtrack)
                text_pos = text_pos + 20
            end

        end 
    end
end

local function get_hitgroup(index)
 
    if index == 1 then
        return "head"
    elseif index == 6 or index == 7 then
        return "leg"
    elseif index == 4 or index == 5 then
        return "arm"
    end
 
    return "body"
end

local function hitlist(shot)
    if shot.manual then
        return
    end    

    local client_hitbox = hitboxes_hit[shot.hitbox + 1]
    local server_hit = shot.server_damage > 0 and get_hitgroup(shot.server_hitgroup) or "-"

    for i = 8, 2, -1 do
        hitlog[i] = hitlog[i-1]
    end

    id = id + 1

    hitlog[1] = {
        ["id"] = id,
        ["player"] = string.sub(engine.get_player_info(shot.target:get_prop_int(0x64)).name, 0, 14),
        ["client_damage"] = shot.client_damage,
        ["server_damage"] = shot.server_damage,
        ["HPrem"] = shot.target:get_prop_int(m_iHealth),
        ["client_hitbox"] = client_hitbox,
        ["server_hit"] = server_hit,
        ["hitchance"] = shot.hitchance,
        ["safepoint"] = shot.safe_point,
        ["result"] = shot.result,
        ["backtrack"] = shot.backtrack,
    }
end

client.register_callback("paint", on_paint)
client.register_callback("shot_fired", hitlist)