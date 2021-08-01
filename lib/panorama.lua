local ffi = require 'ffi'
local helper = require 'ffi_helper'

ffi.cdef[[
    typedef const char*(__thiscall* get_panel_id_t)(void*, void);
    typedef void*(__thiscall* get_parent_t)(void*);
    typedef void*(__thiscall* set_visible_t)(void*, bool);
]]

local panorama_engine = helper.find_interface('panorama.dll', 'PanoramaUIEngine001')
local access_ui_engine = panorama_engine:get_vfunc(11, 'void*(__thiscall*)(void*, void)')

-- UIEngine
local uiengine = helper.get_class(access_ui_engine())
local run_script = uiengine:get_vfunc(113, 'int (__thiscall*)(void*, void*, char const*, char const*, int, int, bool, bool)')
local is_valid_panel_ptr = uiengine:get_vfunc(36, 'bool(__thiscall*)(void*, void*)')
local get_last_target_panel = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
-- UIPanel
local get_panel_id = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
local get_parent = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')
local set_visible = uiengine:get_vfunc(56, 'void*(__thiscall*)(void*)')

local function get_panel_id(panelptr)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[9] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("get_panel_id_t", func)
    return ffi.string(fn(panelptr))
end

local function get_parent(panelptr)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[25] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("get_parent_t", func)
    return fn(panelptr)
end

local function set_visible(panelptr, state)
    local vtbl = panelptr[0] or error("panelptr is nil", 2)
    local func = vtbl[27] or error("panelptr_vtbl is nil", 2)
    local fn = ffi.cast("set_visible_t", func)
    fn(panelptr, state)
end

local function get_root(custompanel)
    local itr = get_last_target_panel()

    if itr == nil then return end

    local ret = nil
    local panelptr = nil

    while itr ~= nil and is_valid_panel_ptr(itr) do
        panelptr = ffi.cast('void***', itr)

        if custompanel and get_panel_id(panelptr) == custompanel then
            ret = itr
            break
        elseif get_panel_id(panelptr) == 'CSGOMainMenu' then
            ret = itr
            break
        elseif get_panel_id(panelptr) == 'CSGOHud' then
            ret = itr
            break
        end

        itr = get_parent(panelptr) or error('Couldn\'t get parent..', 2)
    end

    return ret
end

local rootpanel = get_root()

local function eval(code, custompanel, customfile)
    if custompanel then
        rootpanel = custompanel
    else
        if rootpanel == nil then
            rootpanel = get_root(custompanel) or error('Couldn\'t get parent..', 2)
        end
    end

    local file = customfile or 'panorama/layout/base_mainmenu.xml'

    return run_script(rootpanel, ffi.string(code), file, 8, 10, false, false)
end

local function get_child(name)
    return get_root(name) or error('Couldn\'t get parent..', 2)
end

local function change_visibility(ptr, state)
    local panelptr = ffi.cast('void***', ptr)

    if is_valid_panel_ptr(ptr) then
        return set_visible(panelptr, state)
    else
        error('Invalid panel', 2)
    end
end

local function get_child_name(ptr)
    local panelptr = ffi.cast('void***', ptr)

    if is_valid_panel_ptr(ptr) then
        return ffi.string(get_panel_id(panelptr))
    else
        error('Invalid panel', 2)
    end
end

return {
    eval = eval,
    get_child = get_child,
    get_child_name = get_child_name,
    set_visible = change_visibility
}
