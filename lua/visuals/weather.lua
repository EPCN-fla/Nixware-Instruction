se.register_event("round_freeze_end")
se.register_event("round_prestart")

weather_type = ui.add_combo_box( "Weather", "weather_type", { "rain", "snow" }, 1 )
presets = ui.add_check_box( "Presets", "presets", true )

old_weather_type = nil
old_presets = nil

ffi.cdef[[
    typedef void*(*create_client_class)(int, int);
    typedef void*(*create_event)();

    typedef struct {
        create_client_class create_fn;
        create_event create_event_fn;
        char* network_name;
        void* recv_table;
        void* next;
        int class_id;
    } c_clientclass;

    typedef struct { float x; float y; float z; } vec3_t;


]]

client.register_callback("fire_game_event", function(event)

    if event:get_name() == "round_freeze_end" or event:get_name() == "round_prestart" then
        updated = false
    end

end) --for nixware server

client_interface, entitylist_interface = nil, nil
get_all_classes, get_entity_pointer = nil, nil

snow_created = false
snow_networkable = nil
precipitation_class = nil

function render_weather( stage )

    if stage ~= 4 then
        return
    end

    if not entitylist.get_local_player() then
        updated = false
        return
    end

    if not updated then
        remove_weather()
        snow_created = false

        client_interface = ffi.cast( "void***", se.create_interface( "client.dll", "VClient018" ) )
        entitylist_interface = ffi.cast( "void***", se.create_interface( "client.dll", "VClientEntityList003" ) )

        get_all_classes = ffi.cast( "c_clientclass*(__thiscall*)(void*)", client_interface[0][8] )
        get_entity_pointer = ffi.cast( "void*(__thiscall*)(void*, int)", entitylist_interface[0][3] )

        updated = true
    end

    get_precipitation_class( )

    if snow_created or not precipitation_class or not updated or not client_interface then
        return
    end

    apply_presets( )

    snow_networkable = ffi.cast( "void***", precipitation_class.create_fn( 2047, 0 ) )

    if not snow_networkable then
        return
    end

    local snow_entity = ffi.cast( "void***", get_entity_pointer( entitylist_interface, 2047 ) )
    entitylist.get_entity_by_index( 2047 ):set_prop_int( se.get_netvar( "DT_Precipitation", "m_nPrecipType" ), weather_type:get_value() )

    ffi.cast( "void(__thiscall*)(void*, int)", snow_networkable[0][6] )( snow_networkable, 0 )
    ffi.cast( "void(__thiscall*)(void*, int)", snow_networkable[0][4] )( snow_networkable, 0 )

    local collideable = ffi.cast( "void***(__thiscall*)(void*)", snow_entity[0][3] )( snow_entity )

    if collideable then
        local mins = ffi.cast( "vec3_t*(__thiscall*)(void*)", collideable[0][1] )( collideable )
        local maxs = ffi.cast( "vec3_t*(__thiscall*)(void*)", collideable[0][2] )( collideable )

        if mins and maxs then
            maxs.x, maxs.y, maxs.z = 2000, 2000, 2000
            mins.x, mins.y, mins.z = -2000, -2000, -2000
        end
    end

    ffi.cast( "void(__thiscall*)(void*, int)", snow_networkable[0][5] )( snow_networkable, 0 )
    ffi.cast( "void(__thiscall*)(void*, int)", snow_networkable[0][7] )( snow_networkable, 0 )

    snow_created = true

end

function get_precipitation_class( )

    local current_class = get_all_classes( client_interface )

    while current_class ~= nil do

        if current_class.class_id == 138 then
            precipitation_class = current_class
            break
        end

        if current_class.next == nil then
            break end

        current_class = ffi.cast( "c_clientclass*", current_class.next )

    end

end

old_settings = false

function apply_presets( )

    if presets:get_value() then
        if weather_type:get_value() == 1 then
            se.get_convar("r_rainspeed"):set_float(380)
            se.get_convar("r_rainlength"):set_float(0.035)
            se.get_convar("r_rainwidth"):set_float(0.45)
            se.get_convar("r_rainalpha"):set_float(0.75)
        elseif weather_type:get_value() == 0 then
            se.get_convar("r_rainspeed"):set_float(500)
            se.get_convar("r_rainlength"):set_float(0.08)
            se.get_convar("r_rainwidth"):set_float(0.5)
            se.get_convar("r_rainalpha"):set_float(0.6)
        end
        old_settings = true
    else
        if old_settings then
            se.get_convar("r_rainspeed"):set_float(600.0)
            se.get_convar("r_rainlength"):set_float(0.1)
            se.get_convar("r_rainwidth"):set_float(0.5)
            se.get_convar("r_rainalpha"):set_float(0.4)
            old_settings = false
        end
    end

end

function remove_weather( )

    if snow_created and precipitation_class and snow_networkable then
        local client_unknown = ffi.cast("void***(__thiscall*)(void*)", snow_networkable[0][0])( snow_networkable )
        local client_thinkable = ffi.cast("void***(__thiscall*)(void*)", client_unknown[0][8])( client_unknown )
        ffi.cast("void(__thiscall*)(void*)", client_thinkable[0][4])( client_thinkable )

        snow_created = false
    end

end

client.register_callback("frame_stage_notify", function( stage )

    render_weather( stage )

end)

client.register_callback("paint", function()

    if not engine.is_connected() then 
        updated = false
        snow_created = false
    end

    if old_weather_type ~= weather_type:get_value() then
        updated = false
        old_weather_type = weather_type:get_value()
    end

    if old_presets ~= presets:get_value() then
        updated = false
        old_presets = presets:get_value()
    end

end)

client.register_callback("unload", function()

    remove_weather( )

end)