local ffi = require"ffi"

ffi.cdef[[
    typedef uintptr_t (__thiscall* GetClientEntity_4242425_t)(void*, int);
]]

local ENTITY_LIST_POINTER = ffi.cast("void***", se.create_interface("client.dll", "VClientEntityList003")) or error("Failed to find VClientEntityList003!")
local GET_CLIENT_ENTITY_FN = ffi.cast("GetClientEntity_4242425_t", ENTITY_LIST_POINTER[0][3])

local ffi_helpers = {
    get_entity_address = function(entity_index)
        local addr = GET_CLIENT_ENTITY_FN(ENTITY_LIST_POINTER, entity_index)
        return addr
    end
}

client.register_callback("paint", function()
    local localplayer = entitylist.get_local_player()
	if not localplayer then return end
    ffi.cast("float*", ffi_helpers.get_entity_address(localplayer:get_index()) + 10100)[0] = 0
    local antihit_extra_leg_movement = ui.get_combo_box("antihit_extra_leg_movement")
    if clientstate.get_choked_commands() == 0 then
        antihit_extra_leg_movement:set_value(2)
    else
        antihit_extra_leg_movement:set_value(1)
    end
end)