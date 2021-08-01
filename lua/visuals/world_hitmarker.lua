local get_local_player, get_screen_size, get_local_player_index, get_index_by_userid = entitylist.get_local_player, engine.get_screen_size, engine.get_local_player, engine.get_player_for_user_id
local min, sqrt, floor, sin, cos, rad, ceil = math.min, math.sqrt, math.floor, math.sin, math.cos, math.rad, math.ceil
local get_tick_interval, get_latency, get_abs_frametime = globalvars.get_interval_per_tick, se.get_latency, globalvars.get_absolute_frametime
local draw_line = renderer.line
local draw_print_text = renderer.text
local get_netvar, setup_font, register_callback, is_in_game, get_realtime = se.get_netvar, renderer.setup_font, client.register_callback, engine.is_in_game, globalvars.get_real_time
local w2s, get_current_level_name, add_checkbox, ui_slider_int, get_entity_by_index = se.world_to_screen, engine.get_level_name_short, ui.add_check_box, ui.add_slider_int, entitylist.get_entity_by_index

local h1t_enable = add_checkbox("Enable", "h1t_enable", false)
local h1t_dmg = add_checkbox("Damage Hitmarker", "h1t_dmg", false)
local h1t_size = ui_slider_int("Hitmarker Size", "h1t_size", 0, 10, 4)
local h1t_duration = ui_slider_int("Duration", "h1t_duration", 0, 10, 1)

local h1t_clr = ui.add_color_edit("Color Pick", "h1t_clr", false, color_t.new(255, 0, 0, 255))

local bulletImpactData = { }
local hitmarkerQueue = { }

local mathFloor = math.floor
local mathSqrt = math.sqrt
local mathPow = math.pow
local tableInsert = table.insert

local m_vecOrigin = get_netvar("DT_BaseEntity", "m_vecOrigin")
local font = setup_font("C:/Windows/fonts/tahomaBD.ttf", 14, 8);
  
local function vectordistance(x1,y1,z1,x2,y2,z2)
    return mathSqrt(mathPow(x1 - x2, 2) + mathPow( y1 - y2, 2) + mathPow( z1 - z2 , 2) )
end

local function reset_pos()
    for i in ipairs(bulletImpactData) do
        bulletImpactData[i] = { 0 , 0 , 0 , 0 }
    end

    for i in ipairs(hitmarkerQueue) do
        hitmarkerQueue[i] = { 0 , 0 , 0 , 0, 0}
    end
end

local function on_bullet_impact(e)
    if get_index_by_userid(e:get_int("userid", 0)) == get_local_player_index() then
        local impactX = e:get_int("x", 0)
        local impactY = e:get_int("y", 0)
        local impactZ = e:get_int("z", 0)
        tableInsert(bulletImpactData, { impactX, impactY, impactZ, get_realtime() })
    end
end

local function on_player_hurt(e)
    local bestX, bestY, bestZ = 0, 0, 0
    local bestdistance = 100
    local realtime = get_realtime()
    --check if i shot at the player
    if get_index_by_userid(e:get_int("attacker", 0)) == get_local_player_index() then
        local victim = get_entity_by_index(get_index_by_userid(e:get_int("userid", 0)))  
        if victim ~= nil then
            local victimOrigin = victim:get_prop_vector(m_vecOrigin)
            local victimDamage = e:get_int("dmg_health", 0)

            for i in ipairs(bulletImpactData) do
                if bulletImpactData[i][4] + (h1t_duration:get_value()) >= realtime then
                    local impactX = bulletImpactData[i][1]
                    local impactY = bulletImpactData[i][2]
                    local impactZ = bulletImpactData[i][3]

                    local distance = vectordistance(victimOrigin.x, victimOrigin.y, victimOrigin.z, impactX, impactY, impactZ)
                    if distance < bestdistance then
                        bestdistance = distance
                        bestX = impactX
                        bestY = impactY
                        bestZ = impactZ
                    end
                end
            end

            if bestX == 0 and bestY == 0 and bestZ == 0 then
                victimOrigin.z = victimOrigin.z + 50
                bestX = victimOrigin.x
                bestY = victimOrigin.y
                bestZ = victimOrigin.z
            end

            for k in ipairs(bulletImpactData) do
                bulletImpactData[k] = { 0 , 0 , 0 , 0 }
            end
            tableInsert(hitmarkerQueue, {bestX, bestY, bestZ, realtime, victimDamage} )
        end
    end
end

local function on_player_spawned(e)
    if get_index_by_userid(e:get_int("userid", 0)) == get_local_player_index() then
        reset_pos()
    end
end

client.register_callback("fire_game_event", function(event)
    if event:get_name() == "player_hurt" then
        on_player_hurt(event)
    elseif event:get_name() == "bullet_impact" then
        on_bullet_impact(event)
    elseif event:get_name() == "player_spawned" then
        on_player_spawned(event)
    end
end)

client.register_callback("paint", function()
    if h1t_enable:get_value() == true then
        local HIT_MARKER_DURATION = h1t_duration:get_value()
        local realtime = get_realtime()
        local maxTimeDelta = HIT_MARKER_DURATION / 2
        local maxtime = realtime - maxTimeDelta / 2
       
        for i in ipairs(hitmarkerQueue) do
            if hitmarkerQueue[i][4] + HIT_MARKER_DURATION > maxtime then
                if hitmarkerQueue[i][1] ~= nil then

                    local add = 0
                    if h1t_dmg:get_value() == true then
                        add = (hitmarkerQueue[i][4] - realtime) * 20
                    end

                    local w2c = w2s(vec3_t.new((hitmarkerQueue[i][1]), (hitmarkerQueue[i][2]), (hitmarkerQueue[i][3]) - add))      
                    if w2c.x ~= nil and w2c.y ~= nil then
                        local alpha = 255      
                        -- do fade out stuff
                        if (hitmarkerQueue[i][4] - (realtime - HIT_MARKER_DURATION)) < (HIT_MARKER_DURATION / 2) then                          
                            alpha = mathFloor((hitmarkerQueue[i][4] - (realtime - HIT_MARKER_DURATION)) / (HIT_MARKER_DURATION / 2) * 255)

                            if alpha < 5 then
                                hitmarkerQueue[i] = { 0 , 0 , 0 , 0, 0 }
                            end              
                        end--]]

                        local HIT_MARKER_SIZE = h1t_size:get_value()
                        local col = h1t_clr:get_value()

                        if h1t_dmg:get_value() == true then
                                draw_print_text("-" .. tostring(hitmarkerQueue[i][5]), font, vec2_t.new(w2c.x+18, w2c.y-21), 16, color_t.new(0, 0, 0, 255))
                                draw_print_text("-" .. tostring(hitmarkerQueue[i][5]), font, vec2_t.new(w2c.x+20, w2c.y-20), 14, color_t.new(col.r, col.g, col.b, alpha))
                                
                                draw_line(vec2_t.new(w2c.x - HIT_MARKER_SIZE * 2, w2c.y - HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x - ( HIT_MARKER_SIZE ), w2c.y - ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                                draw_line(vec2_t.new(w2c.x - HIT_MARKER_SIZE * 2, w2c.y + HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x - ( HIT_MARKER_SIZE ), w2c.y + ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                                draw_line(vec2_t.new(w2c.x + HIT_MARKER_SIZE * 2, w2c.y + HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x + ( HIT_MARKER_SIZE ), w2c.y + ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                                draw_line(vec2_t.new(w2c.x + HIT_MARKER_SIZE * 2, w2c.y - HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x + ( HIT_MARKER_SIZE ), w2c.y - ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha)) 
                        else
                            draw_line(vec2_t.new(w2c.x - HIT_MARKER_SIZE * 2, w2c.y - HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x - ( HIT_MARKER_SIZE ), w2c.y - ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                            draw_line(vec2_t.new(w2c.x - HIT_MARKER_SIZE * 2, w2c.y + HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x - ( HIT_MARKER_SIZE ), w2c.y + ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                            draw_line(vec2_t.new(w2c.x + HIT_MARKER_SIZE * 2, w2c.y + HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x + ( HIT_MARKER_SIZE ), w2c.y + ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))
                            draw_line(vec2_t.new(w2c.x + HIT_MARKER_SIZE * 2, w2c.y - HIT_MARKER_SIZE * 2), vec2_t.new(w2c.x + ( HIT_MARKER_SIZE ), w2c.y - ( HIT_MARKER_SIZE )), color_t.new(col.r, col.g, col.b, alpha))  
                        end
                 
                    end
                end
            end
        end
    end
end)