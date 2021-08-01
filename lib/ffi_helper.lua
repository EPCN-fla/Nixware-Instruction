local helper_mt = {}
local interface_mt = {}

local iface_ptr = ffi.typeof('void***')
local char_ptr = ffi.typeof('char*')
local nullptr = ffi.new('void*')

local function iface_cast(raw)
    return ffi.cast(iface_ptr, raw)
end
local function is_valid_ptr(p)
    return p ~= nullptr and p or nil
end
local function get_adress_of(raw)
    return ffi.cast('int*', raw)[0]
end
local function function_cast(thisptr, index, typedef, tdef)
    local vtblptr = thisptr[0]

    if is_valid_ptr(vtblptr) then
        local fnptr = vtblptr[index]

        if is_valid_ptr(fnptr) then
            local ret = ffi.cast(typedef, fnptr)

            if is_valid_ptr(ret) then
                return ret
            end

            error('function_cast: couldn\'t cast function typedef: ' ..tdef)
        end
        error('function_cast: function pointer is invalid, index might be wrong typedef: ' .. tdef)
    end
    error("function_cast: virtual table pointer is invalid, thisptr might be invalid typedef: " .. tdef)
end

local seen = {}
local function check_or_create_typedef(tdef)
    if seen[tdef] then
        return seen[tdef]
    end

    local success, typedef = pcall(ffi.typeof, tdef)
    if not success then
        error("error while creating typedef for " ..  tdef .. "\n\t\t\terror: " .. typedef)
    end
    seen[tdef] = typedef
    return typedef
end

function interface_mt.get_vfunc(self, index, tdef)
    local thisptr = self[1]

    if is_valid_ptr(thisptr) then
        local typedef = check_or_create_typedef(tdef)
        local fn = function_cast(thisptr, index, typedef, tdef)

        if not is_valid_ptr(fn) then
            error("get_vfunc: couldnt cast function (" .. index .. ")")
        end

        return function(...)
            return fn(thisptr, ...)
        end
    end

    error('get_vfunc: thisptr is invalid')
end

function helper_mt.find_interface(module, interface)
    local iface = se.create_interface(module, interface)
    if is_valid_ptr(iface) then
        return setmetatable({iface_cast(iface), module}, {__index = interface_mt})
    else
        error("find_interface: interface pointer is invalid (" .. module .. " | " .. interface .. ")")
    end
end

function helper_mt.get_class(raw, module)
    if is_valid_ptr(raw) then 
        local ptr = iface_cast(raw)
        if is_valid_ptr(ptr) then 
            return setmetatable({ptr, module}, {__index = interface_mt})
        else
            error("get_class: class pointer is invalid")
        end
    end
    error("get_class: argument is nullptr")
end

return helper_mt