local player_models = {
    [0] = {
        name = 'theresa',
        path = 'models/player/custom_player/piggy/theresa/moonknight/theresa.mdl'
    },

    {
        name = 'haku_wd',
        path = 'models/player/custom_player/2018g/haku_wd_v1/tm_pirate.mdl'
    },

    {
        name = 'keqing',
        path = 'models/player/custom_player/piggy/genshin_impact/keqing/keqing.mdl'
    }
};

local model_names = {}

for key, value in pairs(player_models) do
    table.insert(model_names, value.name) 
end

local vis_custommodels_enable = ui.add_check_box('custom localplayer', 'vis_custommodels_enable', false)
local vis_custommodel = ui.add_combo_box('model', 'vis_custommodel_path', model_names, 0)

ffi.cdef[[
    typedef struct {
    	void*   fnHandle;        
    	char    szName[260];     
    	int     nLoadFlags;      
    	int     nServerCount;    
    	int     type;            
    	int     flags;           
    	float  vecMins[3];       
    	float  vecMaxs[3];       
    	float   radius;          
    	char    pad[0x1C];       
    } model_t;

    typedef int(__thiscall* get_model_index_t)(void*, const char*);
    typedef const model_t(__thiscall* find_or_load_model_t)(void*, const char*);
    typedef int(__thiscall* add_string_t)(void*, bool, const char*, int, const void*);
    typedef void*(__thiscall* find_table_t)(void*, const char*);
    typedef void(__thiscall* set_model_index_t)(void*, int);
    typedef int(__thiscall* precache_model_t)(void*, const char*, bool);
    typedef void*(__thiscall* get_client_entity_t)(void*, int);
]]

local class_ptr = ffi.typeof('void***')

local rawientitylist = se.create_interface('client.dll', 'VClientEntityList003')
local ientitylist = ffi.cast(class_ptr, rawientitylist)
local get_client_entity = ffi.cast('get_client_entity_t', ientitylist[0][3])

local rawivmodelinfo = se.create_interface('engine.dll', 'VModelInfoClient004')
local ivmodelinfo = ffi.cast(class_ptr, rawivmodelinfo)
local get_model_index = ffi.cast('get_model_index_t', ivmodelinfo[0][2])
local find_or_load_model = ffi.cast('find_or_load_model_t', ivmodelinfo[0][39])

local rawnetworkstringtablecontainer = se.create_interface('engine.dll', 'VEngineClientStringTable001')
local networkstringtablecontainer = ffi.cast(class_ptr, rawnetworkstringtablecontainer)
local find_table = ffi.cast('find_table_t', networkstringtablecontainer[0][3])

local function precache_model(modelname)
    local rawprecache_table = find_table(networkstringtablecontainer, "modelprecache") or error("couldnt find modelprecache", 2)
    if rawprecache_table then 
        local precache_table = ffi.cast(class_ptr, rawprecache_table) or error("couldnt cast precache_table", 2)
        if precache_table then 
            local add_string = ffi.cast("add_string_t", precache_table[0][8]) or error("add_string is nil", 2)

            find_or_load_model(ivmodelinfo, modelname)
            local idx = add_string(precache_table, false, modelname, -1, nil)
            if idx == -1 then 
                return false
            end
        end
    end
    return true
end

local function set_model_index(entity, idx)
    local raw_entity = get_client_entity(ientitylist, entity)
    if raw_entity then 
        local gce_entity = ffi.cast(class_ptr, raw_entity)
        local a_set_model_index = ffi.cast("set_model_index_t", gce_entity[0][75])
        if a_set_model_index == nil then 
            error("set_model_index is nil")
        end
        a_set_model_index(gce_entity, idx)
    end
end

local function change_model(ent, model)
    if model:len() > 5 then
        if precache_model(model) == false then
            error("invalid model", 2)
        end
        local idx = get_model_index(ivmodelinfo, model)
        if idx == -1 then 
            return
        end
        set_model_index(ent, idx)
    end
end

client.register_callback('frame_stage_notify', function (stage)
    if stage ~= 2 then return end

    local me = entitylist.get_local_player()

    if not me or not me:is_alive() then return end

    if vis_custommodels_enable:get_value() then
        change_model(me:get_index(), player_models[vis_custommodel:get_value()].path)
    end
end)
