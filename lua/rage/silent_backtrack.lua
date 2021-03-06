local class_ptr = ffi.typeof("void***")
local raw_entlist = se.create_interface("client.dll", "VClientEntityList003")
local entlist = ffi.cast(class_ptr, raw_entlist)
local entlist_vtbl = entlist[0]
local raw_get_client_entity = entlist_vtbl[3]
local get_client_entity = ffi.cast("void*(__thiscall*)(void*, int)", raw_get_client_entity)

local fn = ffi.cast("void(__thiscall*)(void*, float*)", client.find_pattern("client.dll", "55 8B EC 83 E4 F8 51 53 56 57 8B F1 E8"))

local function set_abs_origin(entity, x, y, z)
    fn(entity, ffi.new('float[3]', { x, y, z }))
end

local m_hPlayer_offset = se.get_netvar("DT_CSRagdoll", "m_hPlayer")
local m_vecOrigin_offset = se.get_netvar("DT_BaseEntity", "m_vecOrigin")

local positions = {}
client.register_callback("frame_stage_notify", function(stage)
    if stage == 1 then
        local players = entitylist.get_players(0)

        for i = 1, #players do
            local player = players[i]

            if not player:is_dormant() and player:is_alive() then
                positions[players[i]:get_index()] = players[i]:get_prop_vector(m_vecOrigin_offset)
            end
        end
    end
    if stage == 4 then
        local ragdolls = entitylist.get_entities_by_class("CCSRagdoll")

        if ragdolls then
            if ragdolls then
                for i=1, #ragdolls do
                    local ragdoll = ragdolls[i]
                    local m_hPlayer = entitylist.get_entity_from_handle(ragdoll:get_prop_int(m_hPlayer_offset))
                    if m_hPlayer then
                        local ragdoll_entity = get_client_entity(entlist, ragdoll:get_index())
                        if ragdoll_entity ~= nil then
                            local vec = positions[m_hPlayer:get_index()]
                            if vec then
                                set_abs_origin(ragdoll_entity, vec.x,vec.y,vec.z)
                            end
                        end
                    end
                end
            end
        end
    end
end)
