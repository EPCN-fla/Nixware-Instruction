--[[
    # Author: linius#6847
    # Description: auto disable auto-strafer on low velocity
]]

local velocity = nil
local m_vecVelocity = {
    [0] = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]"),
    [1] = se.get_netvar("DT_BasePlayer", "m_vecVelocity[1]")
}

local function main()
    local player = entitylist.get_entity_by_index(engine.get_local_player())
    
    if player then
        velocity = math.sqrt(player:get_prop_float(m_vecVelocity[0]) ^ 2 + player:get_prop_float(m_vecVelocity[1]) ^ 2)
    end

    if velocity ~= nil then
        if velocity > 5 then
            ui.set_bool("misc_autostrafer", true)
        else
            ui.set_bool("misc_autostrafer", false)
        end
    end
end

client.register_callback("paint", main)