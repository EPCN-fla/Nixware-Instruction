local ffi = require('ffi')
local bind = ui.add_key_bind("key", "key", 0, 1)

ffi.cdef[[
    typedef void*(__thiscall* getnetchannel_t)(void*); // engineclient 78

    typedef void(__thiscall* set_timeout_t)(void*, float, bool); // netchan 31
]]

local engineclient = ffi.cast(ffi.typeof("void***"), se.create_interface("engine.dll", "VEngineClient014"))
local getnetchannel = ffi.cast("getnetchannel_t", engineclient[0][78])

local netchannel = {}
do
    function vfunc_wrapper(type, index)
        return function(...)
            -- only did this for netchannel, you can probably extend it to make it a proper wrapper
            local netchannel = ffi.cast(ffi.typeof("void***"), getnetchannel(engineclient))
            local fn = ffi.cast(type, netchannel[0][index])

            return fn(netchannel, ...)
        end
    end

    netchannel.set_timeout = vfunc_wrapper("void(__thiscall*)(void*, float, bool)", 31)
end

client.register_callback("paint", function()
    if not engine.is_in_game() then
        return
    end

    if bind:is_active() then
        netchannel.set_timeout(3600, false)
    end
end)