rage_active_exploit = ui.get_combo_box("rage_active_exploit")
antihit_extra_fakeduck_bind = ui.get_key_bind("antihit_extra_fakeduck_bind")
rage_active_exploit_bind = ui.get_key_bind("rage_active_exploit_bind")

local hitscan = {'head', 'chest', 'pelvis', 'stomach', 'legs', 'foot'}
local scar_hitscan_hs = ui.add_multi_combo_box('Auto HS/FL Hitscan', 'scar_hitscan_hs', hitscan, { false, false, false, false, false, false })
local scar_hitscan_noscope_dt = ui.add_multi_combo_box('Auto DT NoScope Hitscan', 'scar_hitscan_noscope_dt', hitscan, { false, false, false, false, false, false })
local scar_hitscan_dt = ui.add_multi_combo_box('Auto DT Hitscan', 'scar_hitscan_dt', hitscan, { false, false, false, false, false, false })
local scar_safepoint_hs = ui.add_combo_box('Auto HS/FL Safepoints', 'scar_safepoint_hs', {'default', 'prefer', 'force'}, 0)
local scar_headscale_hs = ui.add_slider_int('Auto HS/FL Head Scale', 'scar_headscale_hs', 0, 100, 0)
local scar_bodyscale_hs = ui.add_slider_int('Auto HS/FL Body Scale', 'scar_bodyscale_hs', 0, 100, 0)
local scar_hitchance_hs = ui.add_slider_int('Auto HS/FL HitChance', 'scar_hitchance_hs', 0, 100, 0)
local scar_safepoint_noscope_dt = ui.add_combo_box('Auto DT NoScope Safepoints', 'scar_safepoint_noscope_dt', {'default', 'prefer', 'force'}, 0)
local scar_headscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Head Scale', 'scar_headscale_noscope_dt', 0, 100, 0)
local scar_bodyscale_noscope_dt = ui.add_slider_int('Auto DT NoScope Body Scale', 'scar_bodyscale_noscope_dt', 0, 100, 0)
local scar_hitchance_noscope_dt = ui.add_slider_int('Auto DT NoScope HitChance', 'scar_hitchance_noscope_dt', 0, 100, 0)
local scar_safepoint_dt = ui.add_combo_box('Auto DT Safepoints', 'scar_safepoint_dt', {'default', 'prefer', 'force'}, 0)
local scar_headscale_dt = ui.add_slider_int('Auto DT Head Scale', 'scar_headscale_dt', 0, 100, 0)
local scar_bodyscale_dt = ui.add_slider_int('Auto DT Body Scale', 'scar_bodyscale_dt', 0, 100, 0)
local scar_hitchance_dt = ui.add_slider_int('Auto DT HitChance', 'scar_hitchance_dt', 0, 100, 0)

local auto_hitscan = ui.get_multi_combo_box("rage_auto_hitscan")
local auto_head = ui.get_slider_int("rage_auto_head_pointscale") 
local auto_body = ui.get_slider_int("rage_auto_body_pointscale")
local auto_sp = ui.get_combo_box("rage_auto_safepoints")
local auto_hitchance = ui.get_slider_int("rage_auto_hitchance")
local auto_autoscope = ui.get_check_box("rage_auto_autoscope")

local function scar_override()   
    player = entitylist.get_local_player()
    is_scoped = player:get_prop_bool( se.get_netvar( "DT_CSPlayer", "m_bIsScoped" ) )

    if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
        auto_head:set_value(scar_headscale_noscope_dt:get_value())
        auto_body:set_value(scar_bodyscale_noscope_dt:get_value())
        auto_sp:set_value(scar_safepoint_noscope_dt:get_value())
        auto_hitchance:set_value(scar_hitchance_noscope_dt:get_value())
        auto_autoscope:set_value(false)
    elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
        auto_head:set_value(scar_headscale_dt:get_value())
        auto_body:set_value(scar_bodyscale_dt:get_value())
        auto_sp:set_value(scar_safepoint_dt:get_value())
        auto_hitchance:set_value(scar_hitchance_dt:get_value())
        auto_autoscope:set_value(false)
    elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
        auto_head:set_value(scar_headscale_hs:get_value())
        auto_body:set_value(scar_bodyscale_hs:get_value())
        auto_sp:set_value(scar_safepoint_hs:get_value())
        auto_hitchance:set_value(scar_hitchance_hs:get_value())
        auto_autoscope:set_value(true)
    elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
        auto_head:set_value(scar_headscale_hs:get_value())
        auto_body:set_value(scar_bodyscale_hs:get_value())
        auto_sp:set_value(scar_safepoint_hs:get_value())
        auto_hitchance:set_value(scar_hitchance_hs:get_value())
        auto_autoscope:set_value(true)
    elseif antihit_extra_fakeduck_bind:is_active() then
        auto_head:set_value(scar_headscale_hs:get_value())
        auto_body:set_value(scar_bodyscale_hs:get_value())
        auto_sp:set_value(scar_safepoint_hs:get_value())
        auto_hitchance:set_value(scar_hitchance_hs:get_value())
        auto_autoscope:set_value(true)
    end
end

local function scar_hitscan()
    for i = 0, #hitscan - 1 do
        if rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and not is_scoped then
            auto_hitscan:set_value(i, (scar_hitscan_noscope_dt):get_value(i))
        elseif rage_active_exploit:get_value() == 2 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() and is_scoped then
            auto_hitscan:set_value(i, (scar_hitscan_dt):get_value(i))
        elseif rage_active_exploit:get_value() == 1 and rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
            auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
        elseif not rage_active_exploit_bind:is_active() and not antihit_extra_fakeduck_bind:is_active() then
            auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
        elseif antihit_extra_fakeduck_bind:is_active() then
            auto_hitscan:set_value(i, (scar_hitscan_hs):get_value(i))
        end
    end
end

client.register_callback('create_move', scar_override)
client.register_callback('create_move', scar_hitscan)