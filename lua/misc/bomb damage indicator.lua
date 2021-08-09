local bomb_dmg_enable = ui.add_check_box("Enable", "bomb_dmg_enable", false)
local screen = engine.get_screen_size()
local bomb_indicator_color = ui.add_color_edit("Line color", "bomb_indicator_color", true, color_t.new(0, 255, 255, 255))
local bomb_indicator_pos_x = ui.add_slider_int("Indicator Pos X", "bomb_indicator_pos_x", 0, screen.x, 300)
local bomb_indicator_pos_y = ui.add_slider_int("Indicator Pos Y", "bomb_indicator_pos_y", 0, screen.x, 300)


local bomb_font = renderer.setup_font('C:/windows/fonts/verdana.ttf', 14, 0)

--Damage Calculate
local function calcDist(local_pos, target_pos)
    local lx = local_pos.x;
    local ly = local_pos.y;
    local lz = local_pos.z;
    local tx = target_pos.x;
    local ty = target_pos.y;
    local tz = target_pos.z;
    local dx = lx - tx;
    local dy = ly - ty;
    local dz = lz - tz;

    return math.sqrt(dx * dx + dy * dy + dz * dz);
end

local m_iHealth = se.get_netvar("DT_BasePlayer", "m_iHealth")
local m_ArmorValue = se.get_netvar("DT_CSPlayer", "m_ArmorValue")

local function p2c(per, alpha)
    local red = per > 50 and 255 or math.floor((per * 2) * 255 / 100);
    local green = per < 50 and 255 or math.floor(255 - (per * 2 - 100) * 255 / 100);

    return color_t.new(red, green, 0, alpha or 255);
end

local function bomb_dmg_calc()
    local me = entitylist.get_local_player()
    local bombs = entitylist.get_entities_by_class( "CPlantedC4" )

    local health = me:get_prop_int(m_iHealth)
    local armor = me:get_prop_int(m_ArmorValue)

    local bomb_pos = bombs[1]:get_prop_vector( 0x138 )
    local lp_pos = me:get_prop_vector(se.get_netvar("DT_BaseEntity", "m_vecOrigin"))

    local distance = calcDist(bomb_pos, lp_pos)
    local willKill = false

    local a = 450.7;
    local b = 75.68;
    local c = 789.2;

    local d = (distance - b) / c;

    local damage = a * math.exp(-d * d)

    if armor > 0 then
        local newDmg = damage * 0.5;
        local armorDmg = (damage - newDmg) * 0.5;

        if armorDmg > armor then
            armor = armor * (1 / .5)
            newDmg = damage - armorDmg;
        end
        damage = newDmg;
    end

    local dmg = 0
    if damage >= 0.5 then
        dmg = math.ceil(damage)
    end

    if dmg >= health then
        willKill = true
    else
        willKill = false
    end

    local bindicator_pos_x= bomb_indicator_pos_x:get_value()
    local bindicator_pos_y= bomb_indicator_pos_y:get_value()
    
    local dmg_color = dmg
    if dmg > 100 then
        dmg_color = 100
    end
    local HP_color = p2c(dmg_color)
    local HP_r = HP_color.r
	local HP_g = HP_color.g
    local HP_b = HP_color.b

    local bindicator_color = bomb_indicator_color:get_value()
	local bindicator_r = bindicator_color.r
	local bindicator_g = bindicator_color.g
    local bindicator_b = bindicator_color.b

    renderer.rect_filled(vec2_t.new(bindicator_pos_x - 1, bindicator_pos_y - 1), vec2_t.new(bindicator_pos_x + 199, bindicator_pos_y + 27), color_t.new(30, 30, 30, 150))
    renderer.rect_filled(vec2_t.new(bindicator_pos_x, bindicator_pos_y), vec2_t.new(bindicator_pos_x + 198, bindicator_pos_y + 1), color_t.new(bindicator_r, bindicator_g, bindicator_b, 255))
    renderer.text("Bomb Damage:", bomb_font, vec2_t.new(bindicator_pos_x + 3, bindicator_pos_y + 7), 14, color_t.new(255, 255, 255, 255))
    renderer.text(string.format("%s HP", dmg), bomb_font, vec2_t.new(bindicator_pos_x + 100, bindicator_pos_y + 7) , 14, color_t.new(HP_r, HP_g, HP_b, 255))

    if willKill then
        renderer.text("(FATAL)", bomb_font, vec2_t.new(bindicator_pos_x + 148, bindicator_pos_y + 7) , 14, color_t.new(255, 0, 0, 255))
    end

end

local function on_paint()
    if bomb_dmg_enable:get_value() then
        bomb_dmg_calc()
    end
end

client.register_callback('paint', on_paint)