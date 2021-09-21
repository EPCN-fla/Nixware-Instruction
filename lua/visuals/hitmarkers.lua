--[===[

    Made by:
                ZZZZZZZZZZ  IIIIIIIIII  PPPPPPPPPP     PPPPPPPPPP        OOOOOOOOOO    KK    KKK     SSSSSSSSSS
                       ZZ      IIII     PPPPPPPPPPP    PPPPPPPPPPP      OO        OO   KK   KKK    SSS
                      ZZ       IIII     PP      PPPP   PP      PPPP    OO          OO  KK  KKK    SSS
                     ZZ        IIII     PP       PPPP  PP       PPPP   OO          OO  KK KKK      SSS
                    ZZ         IIII     PP      PPPP   PP      PPPP    OO          OO  KKKKKK        SSSSSSSSSS
                   ZZ          IIII     PPPPPPPPPPP    PPPPPPPPPPP     OO          OO  KK KKK                 SSS
                  ZZ           IIII     PPPPPPPPP      PPPPPPPPP       OO          OO  KK  KKK                  SSS
                 ZZ            IIII     PP             PP               OO        OO   KK   KKK               SSS
                ZZZZZZZZZZ  IIIIIIIIII  PP             PP                OOOOOOOOOO    KK    KKK     SSSSSSSSSS
    
--]===]

-- GUI
lua_hitmarker = ui.add_check_box("Hit Indicators", "lua_hitmarker", true); 
lua_hitmarker_color = ui.add_color_edit("Hitmarker color", "lua_hitmarker_color", true, color_t.new(255, 255, 255, 255));

lua_hitmarker_size = ui.add_slider_int("Hitmarker Size", "lua_hitmarker_size",  5, 25, 6);
lua_hitmarker_size_combo = ui.add_slider_float("Fade Time", "lua_hitmarker_size_combo", 1, 5, 1);

lua_hitmarker_dmg = ui.add_check_box("Dmg Indicators", "lua_hitmarker_dmg", true);  
lua_hitmarker_color_dmg = ui.add_color_edit("Dmg indicator color", "lua_hitmarker_color_dmg", true, color_t.new(255, 255, 255, 255));
lua_hitmarker_dmg_txtoutlined = ui.add_check_box("Outlined text", "lua_hitmarker_dmg_txtoutlined", true);  
lua_hitmarker_dmg_font_size = ui.add_slider_int("Font size - Dmg indicator", "lua_hitmarker_dmg_font_size", 12, 40, 18);


-- vars
local m_iTeamNum = se.get_netvar("DT_BaseEntity", "m_iTeamNum")
local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")
local font = renderer.setup_font("C:/Windows/Fonts/tahomabd.ttf", 50, 0)

-- tables
hitPositions = {};
hitTimes = {};
hitTypes = {};
dmgArr = {};
bulletImpactPositions = {};
deltaTimes = {};


-- vars
local hitCount = 0;
local newHitCount = 0;
local bulletImpactCount = 0;
local hitFlag = false;



-- functions
local function AddHit(hitPos, type)
    table.insert(hitPositions, hitPos);
    table.insert(hitTimes, globalvars.get_current_time())
    table.insert(hitTypes, type)
    hitCount = hitCount + 1;
end

local function RemoveHit(index)
    table.remove(hitPositions, index);
    table.remove(hitTimes, index);
    table.remove(hitTypes, index);
    table.remove(deltaTimes, index);
    newHitCount = newHitCount - 1;
end

local function GetClosestImpact(point)
    local bestImpactIndex;
    local bestDist = 11111111111;
    local pnt = point
    for i = 0, bulletImpactCount, 1 do
        if (bulletImpactPositions[i] ~= nil) then
            local delta = vec3_t.new(bulletImpactPositions[i].x - pnt.x, bulletImpactPositions[i].y - pnt.y, bulletImpactPositions[i].z - pnt.z);
            local dist = delta:length();
            if (dist < bestDist) then
                bestDist = dist;
                bestImpactIndex = i;
            end
        end
    end
	
    return bulletImpactPositions[bestImpactIndex];
end

client.register_callback("bullet_impact", function(GameEvent)
    -- local
    local local_player = engine.get_local_player()
    local pLocal = entitylist.get_entity_by_index(local_player)

    if pLocal:get_prop_int(m_iHealth) < 1 then
        return
    end

    local attacker = engine.get_player_for_user_id(GameEvent:get_int("userid", 0));
    if attacker ~= nil and attacker == pLocal:get_index() then
        hitFlag = true;
        local hitPos = vec3_t.new(GameEvent:get_float("x", 0), GameEvent:get_float("y", 0), GameEvent:get_float("z", 0));
        table.insert(bulletImpactPositions, hitPos);
        bulletImpactCount = bulletImpactCount + 1;
    end
end)

client.register_callback("player_hurt", function(GameEvent)
    local local_player = engine.get_local_player()
    local pLocal = entitylist.get_entity_by_index(local_player)

    if pLocal:get_prop_int(m_iHealth) < 1 then
        return
    end

    local victim = engine.get_player_for_user_id(GameEvent:get_int("userid", 0));
    local attacker = engine.get_player_for_user_id(GameEvent:get_int("attacker", 0));
    if (attacker ~= nil and victim ~= nil and attacker == pLocal:get_index()) then
        local hitGroup = GameEvent:get_int("hitgroup", 0);
        if (hitFlag) then
            hitFlag = false;
            local vic = entitylist.get_entity_by_index(victim)
            local hitboxPos = vic:get_player_hitbox_pos(hitGroup)
            local impact = GetClosestImpact(hitboxPos);

            AddHit(impact, 0);

            bulletImpactPositions = {};
            bulletImpactCount = 0;
            if lua_hitmarker_dmg:get_value() then
                local damage = "-" .. tostring(GameEvent:get_int("dmg_health", 0)) .. "HP";
                table.insert(dmgArr, damage);
            end
        end
    end
end)

local function hDraw()
    -- local
    local local_player = engine.get_local_player()
    local pLocal = entitylist.get_entity_by_index(local_player)
	
    if ((lua_hitmarker:get_value() or lua_hitmarker_dmg:get_value()) and pLocal:is_alive()) then
        newHitCount = hitCount;
        for i = 0, hitCount, 1 do
            if (hitTimes[i] ~= nil and hitPositions[i] ~= nil and hitTypes[i] ~= nil) then
                local deltaTime = globalvars.get_current_time() - hitTimes[i];
                if (deltaTime > lua_hitmarker_size:get_value()) then
                    RemoveHit(i);
                    if lua_hitmarker_dmg:get_value() then
                        --if table.getn(dmgArr) >= i then
                            table.remove(dmgArr, i)
                       -- end
                    end
                    goto continue;
                end

                if (hitTypes[i] == 1) then
                    hitPositions[i].z = hitPositions[i].z + deltaTime / headshotSpeed;
                end

                local hit = se.world_to_screen(hitPositions[i]);
                local xHit = hit.x
                local yHit = hit.y
				
                if xHit ~= nil and yHit ~= nil then
                    local alpha;
                    if (deltaTime > lua_hitmarker_size_combo:get_value() / 2) then
                        alpha = (1 - (deltaTime - deltaTimes[i]) / lua_hitmarker_size_combo:get_value() * 2) * 255;
                        if (alpha < 0) then
                            alpha = 0
                        end
                    else
                        table.insert(deltaTimes, i, deltaTime)
                        alpha = 255;
                    end
                    if lua_hitmarker:get_value() then
                        local color_variable = lua_hitmarker_color:get_value()
                        local r_color, g_color, b_color, a_color = color_variable.r, color_variable.g, color_variable.b, alpha
                        local size = lua_hitmarker_size:get_value()
                        renderer.line(vec2_t.new(xHit - size, yHit - size), vec2_t.new(xHit - (6 / 4), yHit - (6 / 4)), color_t.new(r_color, g_color, b_color, a_color));
                        renderer.line(vec2_t.new(xHit - size, yHit + size), vec2_t.new(xHit - (6 / 4), yHit + (6 / 4)), color_t.new(r_color, g_color, b_color, a_color));
                        renderer.line(vec2_t.new(xHit + size, yHit - size), vec2_t.new(xHit + (6 / 4), yHit - (6 / 4)), color_t.new(r_color, g_color, b_color, a_color));
                        renderer.line(vec2_t.new(xHit + size, yHit + size), vec2_t.new(xHit + (6 / 4), yHit + (6 / 4)), color_t.new(r_color, g_color, b_color, a_color));
                    end
                    if lua_hitmarker_dmg:get_value() then
                        local color_variable = lua_hitmarker_color_dmg:get_value()
                        local r_color, g_color, b_color, a_color = color_variable.r, color_variable.g, color_variable.b, alpha
                        local fontSize =  lua_hitmarker_dmg_font_size:get_value()
                        if fontSize ~= nil then 
                            if dmgArr[i] ~= nil then
                                if lua_hitmarker_dmg_txtoutlined:get_value() then
                                    renderer.text(dmgArr[i], font, vec2_t.new(xHit-1, yHit-24), fontSize, color_t.new(0, 0, 0, a_color))
                                end
                                renderer.text(dmgArr[i], font, vec2_t.new(xHit, yHit-25), fontSize, color_t.new(r_color, g_color, b_color, a_color))
                            end
                        else
                            if dmgArr[i] ~= nil then
                                if lua_hitmarker_dmg_txtoutlined:get_value() then
                                    renderer.text(dmgArr[i], font, vec2_t.new(xHit-1, yHit-24), 18, color_t.new(0, 0, 0, a_color))
                                end
                                renderer.text(dmgArr[i], font, vec2_t.new(xHit, yHit-25), 18, color_t.new(r_color, g_color, b_color, a_color))
                            end
                        end

                    end
                end
            end

            ::continue::
        end

        hitCount = newHitCount;
    end
end


-- callbacks
client.register_callback("paint", hDraw);