local misc_blockbot = ui.add_key_bind('blockbot key', 'misc_blockbot', 0, 1)

local font_verdana = renderer.setup_font("C:/windows/fonts/verdana.ttf", 20, 32)

local m_vecOrigin = se.get_netvar('DT_BaseEntity', 'm_vecOrigin')
local m_vecVelocity = {
    [0] = se.get_netvar('DT_BasePlayer', 'm_vecVelocity[0]'),
    [1] = se.get_netvar('DT_BasePlayer', 'm_vecVelocity[1]')
}

local local_player = nil
local local_player_index = nil
local target = nil

local function yaw3(v)
    return math.atan2(v.y, v.x) * 180 / math.pi
end

local function sub3(a, b)
    return vec3_t.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function dist3(a, b)
    local d = vec3_t.new(
        a.x - b.x,
        a.y - b.y,
        a.z - b.z
    )

    return math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
end

local function deg_to_rad(deg)
    return deg * math.pi / 180
end

local function on_paint()
    local_player = entitylist.get_local_player()
    local_player_index = local_player:get_index()

    if not local_player then return end

    if target and local_player:is_alive() and target:is_alive() then
        local to_screen = se.world_to_screen(target:get_player_hitbox_pos(5))

        if to_screen.x ~= nil and to_screen.y ~= nil then
            renderer.text('x', font_verdana, vec2_t.new(to_screen.x, to_screen.y), 20, color_t.new(255, 0, 0, 255))
        end
    end

    if not local_player:is_alive() then return end

    if misc_blockbot:is_active() then
        local players = entitylist.get_players(1)

        for i = 1, #players do
            local entity = players[i]

            if local_player_index ~= entity:get_index() and entity:is_alive() then
                if not target then
                    target = entity
                else
                    local player_origin = local_player:get_prop_vector(m_vecOrigin)
                    local entity_origin = entity:get_prop_vector(m_vecOrigin)
                    local target_origin = target:get_prop_vector(m_vecOrigin)

                    if dist3(player_origin, target_origin) > dist3(player_origin, entity_origin) then
                        target = entity

                        client.notify('Selected new target: ' .. tostring(engine.get_player_info(entity:get_index()).name))
                    end
                end
            end
        end
    elseif not misc_blockbot:is_active() or not target:is_alive() then
        target = nil
    end
end

local function on_move(cmd)
    if target and misc_blockbot:is_active() then
        local local_angles = engine.get_view_angles()
        local vec_forward = sub3(target:get_prop_vector(m_vecOrigin), local_player:get_prop_vector(m_vecOrigin))
        local other_yaw = yaw3(vec_forward)
        local target_speed = math.sqrt(target:get_prop_float(m_vecVelocity[0]) ^ 2 + target:get_prop_float(m_vecVelocity[1]) ^ 2);
    
        local diff_yaw = other_yaw - local_angles.yaw

        if diff_yaw > 180 then
            diff_yaw = diff_yaw - 360
        elseif diff_yaw < -180 then
            diff_yaw = diff_yaw + 360
        end

        if target_speed > 285 then
            cmd.forwardmove = -math.abs(target_speed)
        end

        if diff_yaw > 0.25 then
            cmd.sidemove = -450
        elseif diff_yaw < -0.25 then
            cmd.sidemove = 450
        end
    end
end

client.register_callback('create_move', on_move)
client.register_callback('paint', on_paint)
