

materialsystem = ffi.cast("void***", se.create_interface("materialsystem.dll", "VMaterialSystem080"))

get_material = ffi.cast("int(__thiscall*)(void*)", materialsystem[0][86])
next_material = ffi.cast("int(__thiscall*)(void*, int)", materialsystem[0][87])
invalid_material = ffi.cast("int(__thiscall*)(void*)", materialsystem[0][88])
find_material = ffi.cast("void*(__thiscall*)(void*, int)", materialsystem[0][89])

function set_props_alpha( alpha )

	local temp_material = get_material( materialsystem )

    while temp_material ~= invalid_material( materialsystem ) do

        local founded_material = ffi.cast("void***", find_material( materialsystem, temp_material ))

        local get_group = ffi.cast("const char*(__thiscall*)(void*)", founded_material[0][1])
		local set_alpha = ffi.cast("void(__thiscall*)(void*, float)", founded_material[0][27])

		if ffi.string( get_group( founded_material ) ):find("StaticProp")then
			set_alpha( founded_material, alpha )
		end

        temp_material = next_material( materialsystem, temp_material )

    end

end

set_props_alpha( 0.65 )

client.register_callback("unload", function()

	set_props_alpha( 1 )

end)