--[[
    author: linius#5149
    description: just heartmarker
--]]

local ui_add_checkbox = ui.add_check_box

local is_enabled = ui_add_checkbox('Heartmarkers', 'vis_heartmarkers_enable', false)
local is_colored = ui_add_checkbox('Colored', 'vis_heartmarkers_colored', false)

local hearts = {}

local function rectangle(x, y, w, h, color)
    renderer.rect_filled(vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(color[1], color[2], color[3], color[4]))
end

-- wtf
local function draw_heart(x, y, color)
    rectangle(x + 2, y + 14, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x, y + 12, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x - 2, y + 10, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x - 4, y + 4, 2, 6, { 0, 0, 0, color[4] })
    rectangle(x - 2, y + 2, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x, y, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 2, y, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 4, y + 2, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 6, y, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 8, y, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 10, y + 2, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 12, y + 4, 2, 6, { 0, 0, 0, color[4] })
    rectangle(x + 10, y + 10, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 8, y + 12, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 6, y + 14, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x + 4, y + 16, 2, 2, { 0, 0, 0, color[4] })
    rectangle(x - 2, y + 4, 2, 6, { color[1], color[2], color[3], color[4] })
    rectangle(x, y + 2, 4, 2, { color[1], color[2], color[3], color[4] })
    rectangle(x, y + 6, 4, 6, { color[1], color[2], color[3], color[4] })
    rectangle(x + 2, y + 4, 2, 2, { color[1], color[2], color[3], color[4] })
    rectangle(x + 2, y + 12, 2, 2, { color[1], color[2], color[3], color[4] })
    rectangle(x + 4, y + 4, 2, 12, { color[1], color[2], color[3], color[4] })
    rectangle(x + 6, y + 2, 4, 10, { color[1], color[2], color[3], color[4] })
    rectangle(x + 6, y + 12, 2, 2, { color[1], color[2], color[3], color[4] })
    rectangle(x + 10, y + 4, 2, 6, { color[1], color[2], color[3], color[4] })

    rectangle(x, y + 4, 2, 2, { 254, 199, 199, color[4] })
end

local function on_render()
    if not is_enabled:get_value() then return end

    local realtime = globalvars.get_real_time()
    local colored = is_colored:get_value()

    for i = 1, #hearts do
        if hearts[i] == nil then return end
        local heart = hearts[i]

        local vec = se.world_to_screen(
            vec3_t.new(heart.position.x, heart.position.y, heart.position.z)
        )

        local x = vec.x
        local y = vec.y

        local alpha = math.floor(255 - 255 * (realtime - heart.start_time))

        if realtime - heart.start_time >= 1 then
            alpha = 0
        end

        if x ~= nil and y ~= nil then
            if colored then
                if heart.damage <= 15 then
                    draw_heart(x - 5, y - 5, { 60, 255, 0, alpha })
                elseif heart.damage <= 30 then
                    draw_heart(x - 5, y - 5, { 255, 251, 0, alpha })
                elseif heart.damage <= 60 then
                    draw_heart(x - 5, y - 5, { 255, 140, 0, alpha })
                else
                    draw_heart(x - 5, y - 5, { 254, 19, 19, alpha })
                end
            else
                draw_heart(x - 5, y - 5, { 254, 19, 19, 255 })
            end
        end

        heart.position.z = heart.position.z + (realtime - heart.frame_time) * 50
        heart.frame_time = realtime

        if realtime - heart.start_time >= 1 then
            table.remove(hearts, i)
        end
    end
end

local function on_shot(e)
    if e.result ~= 'hit' then return end

    local time = globalvars.get_real_time()

    table.insert(hearts, {
        position = { x = e.aim_point.x, y = e.aim_point.y, z = e.aim_point.z },
        damage = e.server_damage,
        start_time = time,
        frame_time = time
    })
end

client.register_callback('paint', on_render)
client.register_callback('shot_fired', on_shot)
