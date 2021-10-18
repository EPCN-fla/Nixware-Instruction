-- preserve killfeed
-- by mrnv / nixware.cc
-- modified by Fla1337
-- built date: 30 Jun 2021
-- update time: 2 Oct 2021

-- ffi
ffi.cdef[[
    typedef unsigned long DWORD;

    typedef DWORD( __thiscall* FindHudElement_t )( void*, const char* );
    typedef void( __thiscall* ClearDeathNotices_t )( void* );
]]

local offsets =
{
    CHud = 0,
    FindHudElement = 0,
    ClearDeathNotices = 0
}

-- find CHud
local CHud = client.find_pattern( "client.dll", "B9 ? ? ? ? E8 ? ? ? ? 8B 5D 08" );
if( CHud == nil ) then
    client.notify( "[ERROR] Failed to find CHud" );
    client.unload_script( client.get_script_name( ) );
    return;
end

offsets.CHud = ffi.cast( "uintptr_t**", CHud + 1 )[ 0 ];

-- find FindHudElement
local FindHudElement_func = client.find_pattern( "client.dll", "55 8B EC 53 8B 5D 08 56 57 8B F9 33 F6 39 77 28" );
if( FindHudElement_func == nil ) then
    client.notify( "[ERROR] Failed to find FindHudElement" );
    client.unload_script( client.get_script_name( ) );
    return;
end

offsets.FindHudElement = ffi.cast( "FindHudElement_t", FindHudElement_func );

-- find ClearDeathNotices
local ClearDeathNotices_func = client.find_pattern( "client.dll", "55 8B EC 83 EC 0C 53 56 8B 71 58" );
if( ClearDeathNotices_func == nil ) then
    client.notify( "[ERROR] Failed to find ClearDeathNotices" );
    client.unload_script( client.get_script_name( ) );
    return;
end

offsets.ClearDeathNotices = ffi.cast( "ClearDeathNotices_t", ClearDeathNotices_func );

-- utils
local function FindHudElement( hudelement )
    return offsets.FindHudElement( offsets.CHud, hudelement );
end

local function ClearDeathNotices( element )
    if( not engine.is_in_game( ) or not engine.is_connected( ) or entitylist.get_local_player( ) == nil ) then return end;

    offsets.ClearDeathNotices( ffi.cast( "void*", element - 20 ) );
end

-- main code
local deathnotice = 0;
local backuptime = -1;

-- ui
local time = ui.add_slider_float( "Preserve Time", "preservekillfeed_time", 0.0, 20.0, 1.5 );
local click_to_clear_notices = ui.add_check_box("Clear Notices", "preservekillfeed_click_to_clear_notices", false)

-- callbacks
local function Paint( )
    if( engine.is_in_game( ) and engine.is_connected( ) and entitylist.get_local_player( ) ~= nil ) then
        if( deathnotice == 0 ) then
            deathnotice = FindHudElement( "CCSGO_HudDeathNotice" );

            if( backuptime == -1 ) then
                backuptime = ffi.cast( "float*", deathnotice + 80 )[ 0 ];
            end
        else
            ffi.cast( "float*", deathnotice + 80 )[ 0 ] = time:get_value( );
        end
    else
        deathnotice = 0;
    end

    if click_to_clear_notices:get_value() then
        ClearDeathNotices( deathnotice );
        click_to_clear_notices:set_value(false)
    end
end
client.register_callback( "paint", Paint );

client.register_callback("round_start", function()  -- update
    ClearDeathNotices( deathnotice );
    deathnotice = 0;
end)

-- unload callback to restore original time
local function Unload( )
    if( deathnotice ~= 0 and backuptime ~= -1 ) then
        ffi.cast( "float*", deathnotice + 80 )[ 0 ] = backuptime;
    end
end
client.register_callback( "unload", Unload );