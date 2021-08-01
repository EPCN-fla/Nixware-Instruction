local ffi = require 'ffi'

local matrix_color = ui.add_color_edit('color', 'vis_matrixonshot_color', true, color_t.new(255, 255, 255, 130))
local duration = ui.add_slider_float('duration', 'vis_matrixonshot_duration', 0.1, 10.0, 2)

ffi.cdef[[
    typedef unsigned char byte;

    typedef struct
    {
        float x,y,z;
    } Vector;

    typedef struct
    {
        void*   fnHandle;               //0x0000
        char    szName[260];            //0x0004
        int nLoadFlags;             //0x0108
        int nServerCount;           //0x010C
        int type;                   //0x0110
        int flags;                  //0x0114
        Vector  vecMins;                //0x0118
        Vector  vecMaxs;                //0x0124
        float   radius;                 //0x0130
        char    pad[28];              //0x0134
    } model_t;
    
    typedef struct
    {
        int     m_bone;                 // 0x0000
        int     m_group;                // 0x0004
        Vector  m_mins;                 // 0x0008
        Vector  m_maxs;                 // 0x0014
        int     m_name_id;                // 0x0020
        Vector  m_angle;                // 0x0024
        float   m_radius;               // 0x0030
        int        pad2[4];
    } mstudiobbox_t;
    
    typedef struct
    {
        int sznameindex;
    
        int numhitboxes;
        int hitboxindex;
    } mstudiohitboxset_t;
    
    typedef struct
    {
        int id;                     //0x0000
        int version;                //0x0004
        long    checksum;               //0x0008
        char    szName[64];             //0x000C
        int length;                 //0x004C
        Vector  vecEyePos;              //0x0050
        Vector  vecIllumPos;            //0x005C
        Vector  vecHullMin;             //0x0068
        Vector  vecHullMax;             //0x0074
        Vector  vecBBMin;               //0x0080
        Vector  vecBBMax;               //0x008C
        int pad[5];
        int numhitboxsets;          //0x00AC
        int hitboxsetindex;         //0x00B0
    } studiohdr_t;
    
    typedef struct
    {
        float m_flMatVal[3][4];
    } matrix3x4_t;
    
    typedef struct
    {
        matrix3x4_t test[128];
    } matrix3x4_t2;
    
    typedef struct
    {
        unsigned memory;
        char pad[8];
        unsigned int count;
        unsigned pelements;
    } CUtlVectorSimple;
]]

local pHitboxSet = function(i, stdmdl)
    if i < 0 or i > stdmdl.numhitboxsets then return nil end
    return ffi.cast("mstudiohitboxset_t*", ffi.cast("byte*", stdmdl) + stdmdl.hitboxsetindex) + i
end

local pHitbox = function(i, stdmdl)
    if i > stdmdl.numhitboxes then return nil end
    return ffi.cast("mstudiobbox_t*", ffi.cast("byte*", stdmdl) + stdmdl.hitboxindex) + i
end

local DotProduct = function(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local VectorTransform = function(in1, in2)
    return ffi.new("Vector", {
        DotProduct(in1, vec3_t.new(in2[0][0], in2[0][1], in2[0][2])) + in2[0][3],
        DotProduct(in1, vec3_t.new(in2[1][0], in2[1][1], in2[1][2])) + in2[1][3],
        DotProduct(in1, vec3_t.new(in2[2][0], in2[2][1], in2[2][2])) + in2[2][3]
    })
end

local DEG2RAD = function(x)
    return x * (math.pi / 180)
end

local RAD2DEG = function(x)
    return x * (180 / math.pi)
end

local AngleMatrix = function(angles)
    local sr, sp, sy, cr, cp, cy
    
    sy = math.sin(DEG2RAD(angles.y))
    cy = math.cos(DEG2RAD(angles.y))
    
    sp = math.sin(DEG2RAD(angles.x))
    cp = math.cos(DEG2RAD(angles.x))
    
    sr = math.sin(DEG2RAD(angles.z))
    cr = math.sin(DEG2RAD(angles.z))
    
    local matrix = ffi.new("matrix3x4_t").m_flMatVal
    
    matrix[0][0] = cp * cy
    matrix[1][0] = cp * sy
    matrix[2][0] = -sp
    
    local crcy = cr * cy;
    local crsy = cr * sy;
    local srcy = sr * cy;
    local srsy = sr * sy;
    
    matrix[0][1] = sp * srcy - crsy;
    matrix[1][1] = sp * srsy + crcy;
    matrix[2][1] = sr * cp;
 
    matrix[0][2] = sp * crcy + srsy;
    matrix[1][2] = sp * crsy - srcy;
    matrix[2][2] = cr * cp;
 
    matrix[0][3] = 0.0
    matrix[1][3] = 0.0
    matrix[2][3] = 0.0
    
    return matrix
end

local ConcatTransforms = function(in1, in2)
    local out = ffi.new("matrix3x4_t").m_flMatVal
    
    out[ 0 ][ 0 ] = in1[ 0 ][ 0 ] * in2[ 0 ][ 0 ] + in1[ 0 ][ 1 ] * in2[ 1 ][ 0 ] + in1[ 0 ][ 2 ] * in2[ 2 ][ 0 ];
    out[ 0 ][ 1 ] = in1[ 0 ][ 0 ] * in2[ 0 ][ 1 ] + in1[ 0 ][ 1 ] * in2[ 1 ][ 1 ] + in1[ 0 ][ 2 ] * in2[ 2 ][ 1 ];
    out[ 0 ][ 2 ] = in1[ 0 ][ 0 ] * in2[ 0 ][ 2 ] + in1[ 0 ][ 1 ] * in2[ 1 ][ 2 ] + in1[ 0 ][ 2 ] * in2[ 2 ][ 2 ];
    out[ 0 ][ 3 ] = in1[ 0 ][ 0 ] * in2[ 0 ][ 3 ] + in1[ 0 ][ 1 ] * in2[ 1 ][ 3 ] + in1[ 0 ][ 2 ] * in2[ 2 ][ 3 ] + in1[ 0 ][ 3 ];

    out[ 1 ][ 0 ] = in1[ 1 ][ 0 ] * in2[ 0 ][ 0 ] + in1[ 1 ][ 1 ] * in2[ 1 ][ 0 ] + in1[ 1 ][ 2 ] * in2[ 2 ][ 0 ];
    out[ 1 ][ 1 ] = in1[ 1 ][ 0 ] * in2[ 0 ][ 1 ] + in1[ 1 ][ 1 ] * in2[ 1 ][ 1 ] + in1[ 1 ][ 2 ] * in2[ 2 ][ 1 ];
    out[ 1 ][ 2 ] = in1[ 1 ][ 0 ] * in2[ 0 ][ 2 ] + in1[ 1 ][ 1 ] * in2[ 1 ][ 2 ] + in1[ 1 ][ 2 ] * in2[ 2 ][ 2 ];
    out[ 1 ][ 3 ] = in1[ 1 ][ 0 ] * in2[ 0 ][ 3 ] + in1[ 1 ][ 1 ] * in2[ 1 ][ 3 ] + in1[ 1 ][ 2 ] * in2[ 2 ][ 3 ] + in1[ 1 ][ 3 ];

    out[ 2 ][ 0 ] = in1[ 2 ][ 0 ] * in2[ 0 ][ 0 ] + in1[ 2 ][ 1 ] * in2[ 1 ][ 0 ] + in1[ 2 ][ 2 ] * in2[ 2 ][ 0 ];
    out[ 2 ][ 1 ] = in1[ 2 ][ 0 ] * in2[ 0 ][ 1 ] + in1[ 2 ][ 1 ] * in2[ 1 ][ 1 ] + in1[ 2 ][ 2 ] * in2[ 2 ][ 1 ];
    out[ 2 ][ 2 ] = in1[ 2 ][ 0 ] * in2[ 0 ][ 2 ] + in1[ 2 ][ 1 ] * in2[ 1 ][ 2 ] + in1[ 2 ][ 2 ] * in2[ 2 ][ 2 ];
    out[ 2 ][ 3 ] = in1[ 2 ][ 0 ] * in2[ 0 ][ 3 ] + in1[ 2 ][ 1 ] * in2[ 1 ][ 3 ] + in1[ 2 ][ 2 ] * in2[ 2 ][ 3 ] + in1[ 2 ][ 3 ];
    
    return out
end

local MatrixAngles = function(matrix)
    local forward, left, up
    
    local angles = ffi.new("Vector")
    
    forward = vec3_t.new( matrix[ 0 ][ 0 ], matrix[ 1 ][ 0 ], matrix[ 2 ][ 0 ] )
    left = vec3_t.new( matrix[ 0 ][ 1 ], matrix[ 1 ][ 1 ], matrix[ 2 ][ 1 ] )
    up = vec3_t.new( 0, 0, 0 )
    
    local len = math.sqrt(forward.x^2+forward.y^2)
    
    if len > 0.001 then
        angles.x = RAD2DEG( math.atan2( -forward.z, len ) )
        angles.y = RAD2DEG( math.atan2( forward.y, forward.x ) )
        angles.z = RAD2DEG( math.atan2( left.z, up.z ) )
    else
        angles.x = RAD2DEG( math.atan2( -forward.z, len ) )
        angles.y = RAD2DEG( math.atan2( -left.x, left.y ) )
        angles.z = 0
    end
    
    return angles
end

local MatrixOrigin = function(matrix)
    return ffi.new("Vector", {
        matrix[0][3],
        matrix[1][3],
        matrix[2][3]
    })
end

local DebugOverlay = ffi.cast(ffi.typeof("void***"), se.create_interface("engine.dll", "VDebugOverlay004"))
local AddBoxOverlay = ffi.cast("void(__thiscall*)(void*, Vector&, Vector&, Vector&, Vector&, int, int, int, int, float)", DebugOverlay[0][1])
local AddCapsuleOverlay = ffi.cast(ffi.typeof("void(__thiscall*)(void*, Vector&, Vector&, float&, int, int, int, int, float, int, int)"), DebugOverlay[0][23])

local ModelInfo = ffi.cast(ffi.typeof("void***"), se.create_interface("engine.dll", "VModelInfoClient004"))
local GetStudioModel = ffi.cast(ffi.typeof("studiohdr_t*(__thiscall*)(void*, model_t*)"), ModelInfo[0][32])

local ClientEntityList = ffi.cast(ffi.typeof("void***"), se.create_interface("client.dll", "VClientEntityList003"))
local GetClientEntity = ffi.cast(ffi.typeof("unsigned long(__thiscall*)(void*, int)"), ClientEntityList[0][3])

local matrix_data = { }

local AddMatrix = function(index, r, g, b, a, duration, hitgroup)
    if index == engine.get_local_player() then return end
    
    local ClientRenderable = ffi.cast(ffi.typeof("void***"), GetClientEntity(ClientEntityList, index) + 0x4)
    local GetModel = ffi.cast(ffi.typeof("model_t*(__thiscall*)(void*)"), ClientRenderable[0][8])

    local matrix = ffi.cast("matrix3x4_t2*", ffi.cast("CUtlVectorSimple*", ffi.cast("unsigned long", GetClientEntity(ClientEntityList, index)) + 0x2910).memory)

    if not matrix then return end

    local model = GetModel(ClientRenderable)

    if not model then return end

    local hdr = GetStudioModel(ModelInfo, model)

    if not hdr then return end
            
    local set = pHitboxSet(entitylist.get_entity_by_index(index):get_prop_int(se.get_netvar("CBasePlayer", "m_nHitboxSet")), hdr)

    if not set then return end

    for i=0, set.numhitboxes - 1 do
        local bbox = pHitbox(i, set)
        
        if not bbox then goto continue end
        
        if bbox.m_radius == -1 then
            local rot_matrix = AngleMatrix(bbox.m_angle)
                    
            local matrix_out = ConcatTransforms(matrix[0].test[bbox.m_bone].m_flMatVal, rot_matrix)
                    
            local bbox_angles = MatrixAngles(matrix_out)
                    
            local origin = MatrixOrigin(matrix_out)
            
            AddBoxOverlay(DebugOverlay, origin, bbox.m_mins, bbox.m_maxs, bbox_angles, r, g, b, 0, duration)
        else
            local mins = VectorTransform(bbox.m_mins, matrix[0].test[bbox.m_bone].m_flMatVal)
            local maxs = VectorTransform(bbox.m_maxs, matrix[0].test[bbox.m_bone].m_flMatVal)
            
            AddCapsuleOverlay(DebugOverlay, mins, maxs, ffi.new("float[1]", bbox.m_radius), hitgroup == bbox.m_group and 255 or r, hitgroup == bbox.m_group and 0 or g, hitgroup == bbox.m_group and 0 or b, a, duration, 0, 1)
        end
            
        ::continue::
    end
end

local function to_rgba(color)
    return color.r, color.g, color.b, color.a
end

client.register_callback('fire_game_event', function (e)
    if e:get_name() == 'player_hurt' then
        local attacker_idx = engine.get_player_for_user_id(e:get_int("attacker", 0))
        local victim_idx = engine.get_player_for_user_id(e:get_int("userid", 0))

        local r, g, b, a = to_rgba(matrix_color:get_value())

        if attacker_idx == engine.get_local_player() then
            AddMatrix(victim_idx, r, g, b, a, duration:get_value(), e:get_int("hitgroup", 0))
        end
    end
end)
