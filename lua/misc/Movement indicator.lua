-- Init Global
local MaxSpeed = 300
local font = renderer.setup_font("C:/windows/fonts/arial.ttf", 25, 0)
local vVelocity_Offset = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]")
local fFlags_Offset = se.get_netvar("DT_BasePlayer", "m_fFlags")
local size = engine.get_screen_size()
local x,y = size.x, size.y
local TicksShow = 0

-- Graph
local Mnoj = 5
local SpeedArray = { }
local SpeedArraySize = 300
for i = 1, SpeedArraySize do
    SpeedArray[i] = MaxSpeed / Mnoj
end

-- Customize Pos
local SpeedPos = vec3_t.new(x / 2 - 330, y - y / 2 - 400, 0)
local GraphPos = vec3_t.new(x / 2 - SpeedArraySize / 2 - 500, y - y / 2 - 430, 0)

-- Func
client.register_callback("paint", function()
    local LocalPlayer = entitylist.get_local_player()

    -- Show Speed
    local r = 0
    local g = 255
    local b = 0
    local fSpeed = LocalPlayer:get_prop_vector(vVelocity_Offset):length()
    local iSpeed = math.floor(fSpeed)
    local Raz = (MaxSpeed - fSpeed)
    
     if Raz > 49 then
        r = r + (Raz / 1.18)
        g = (g - (Raz / 1.18)) / 1.25
    elseif Raz > 0 and Raz < 49 then
       r = r + (Raz / 1.18)
        g = (g - (Raz / 1.18))
    end

    renderer.text(tostring(iSpeed), font, vec2_t.new(SpeedPos.x, SpeedPos.y), 25, color_t.new(r, g, b, 255))

    -- Show Grapth
    for i = 2, SpeedArraySize do
        SpeedArray[i - 1] = SpeedArray[i]
    end
    SpeedArray[SpeedArraySize] = MaxSpeed / Mnoj - iSpeed / Mnoj

    for i = 2, SpeedArraySize do
        if (SpeedArray[i]) then
            renderer.line(vec2_t.new(GraphPos.x + i - 1, GraphPos.y + SpeedArray[i - 1]), vec2_t.new(GraphPos.x + i, GraphPos.y + SpeedArray[i]), color_t.new(255,255,255,255))
        else
            break
        end
    end

    SpeedArrayStep = SpeedArrayStep + 1
    if (SpeedArrayStep >= SpeedArraySize) then
        SpeedArrayStep = 0
    end
end)