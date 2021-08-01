local sv_maxspeed = se.get_convar('sv_maxspeed')
local stop_bind = ui.add_key_bind("Stop bind", 'stop_bind', 0, 1)
local smoothness = ui.add_slider_int('Autostop smothness', 'smoothness', 4, sv_maxspeed:get_int(), 4)
local misc_autostrafer = ui.get_check_box('misc_autostrafer')

local backup = misc_autostrafer:get_value()

local m_vecVelocity = se.get_netvar("DT_BasePlayer", "m_vecVelocity[0]")
local m_fFlags = se.get_netvar("DT_BasePlayer", "m_fFlags")
local cl_forwardspeed = se.get_convar('cl_forwardspeed')
local cl_sidespeed = se.get_convar('cl_sidespeed')

local function vector_angles(angles) 
    local tmp, yaw, pitch

    if angles.y == 0 and angles.x == 0 then
        yaw = 0
        if angles.z > 0 then
            pitch = 270
        else
            pitch = 90
        end
    else
        yaw = math.atan2(angles.y, angles.x) * 180.0 / math.pi
		if yaw < 0 then
			yaw = yaw + 360
		end
		
		tmp = math.sqrt(angles.x * angles.x + angles.y * angles.y)
		pitch = math.atan2(-angles.z, tmp) * 180.0 / math.pi
		if pitch < 0 then
			pitch = pitch + 360
		end
    end

    return vec3_t.new(pitch, yaw, 0)
end

function deg2rad(x)
    return x * 0.0174533
end    

local function angle_vectors(angles) 
	local sp = math.sin(deg2rad(angles.x))
	local cp = math.cos(deg2rad(angles.x))
	
    local sy = math.sin(deg2rad(angles.y))
    local cy = math.cos(deg2rad(angles.y))

	local sr = math.sin(deg2rad(angles.z))
	local cr = math.cos(deg2rad(angles.z))
	
	return vec3_t.new(cp * cy, cp * sy, -sp)
end

local function stop(cmd)
    local lp = entitylist.get_local_player()
    local velocity = lp:get_prop_vector(m_vecVelocity)

    if velocity:length() < smoothness:get_value() then
        return
    end

    local direction = vector_angles(velocity)
    local view_angles = engine.get_view_angles()

    direction.y = view_angles.yaw - direction.y	

    local forward = angle_vectors(direction)

    cmd.forwardmove = forward.x * -cl_forwardspeed:get_float()
    cmd.sidemove = forward.y * -cl_sidespeed:get_float()
end

client.register_callback('create_move', function(cmd)
    local lp = entitylist.get_local_player()
    if not lp then
        return
    end

    if stop_bind:is_active() and bit32.band(lp:get_prop_int(m_fFlags), 1) == 0 then
        stop(cmd)
    end
end)