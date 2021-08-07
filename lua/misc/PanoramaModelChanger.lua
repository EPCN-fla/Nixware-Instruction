local panorama = require 'panorama'

local emotions = {
    {"Fonzie_Pistol", "Emote_Fonzie_Pistol"},
    {"Bring_It_On", "Emote_Bring_It_On"},
    {"ThumbsDown", "Emote_ThumbsDown"},
    {"ThumbsUp", "Emote_ThumbsUp"},
    {"Celebration_Loop", "Emote_Celebration_Loop"},
    {"BlowKiss", "Emote_BlowKiss"},
    {"Calculated", "Emote_Calculated"},
    {"Confused", "Emote_Confused",},
    {"Chug", "Emote_Chug"},
    {"Cry", "Emote_Cry"},
    {"DustingOffHands", "Emote_DustingOffHands"},
    {"DustOffShoulders", "Emote_DustOffShoulders",},
    {"Facepalm", "Emote_Facepalm"},
    {"Fishing", "Emote_Fishing"},
    {"Flex", "Emote_Flex"},
    {"golfclap", "Emote_golfclap",},
    {"HandSignals", "Emote_HandSignals"},
    {"HeelClick", "Emote_HeelClick"},
    {"Hotstuff", "Emote_Hotstuff"},
    {"IBreakYou", "Emote_IBreakYou",},
    {"IHeartYou", "Emote_IHeartYou"},
    {"Kung", "Emote_Kung-Fu_Salute"},
    {"Laugh", "Emote_Laugh"},
    {"Luchador", "Emote_Luchador",},
    {"Make_It_Rain", "Emote_Make_It_Rain"},
    {"NotToday", "Emote_NotToday"},
    {"[RPS] Paper", "Emote_RockPaperScissor_Paper"},
    {"[RPS] Rock", "Emote_RockPaperScissor_Rock",},
    {"[RPS] Scissor", "Emote_RockPaperScissor_Scissor"},
    {"Salt", "Emote_Salt"},
    {"Salute", "Emote_Salute"},
    {"SmoothDrive", "Emote_SmoothDrive",},
    {"Snap", "Emote_Snap"},
    {"StageBow", "Emote_StageBow",},
    {"Wave2", "Emote_Wave2"},
    {"Yeet", "Emote_Yeet"},
    {"DanceMoves", "DanceMoves"},
    {"Mask_Off_Intro", "Emote_Mask_Off_Intro"},
    {"Zippy_Dance", "Emote_Zippy_Dance"},
    {"ElectroShuffle", "ElectroShuffle"},
    {"AerobicChamp", "Emote_AerobicChamp"},
    {"Bendy", "Emote_Bendy"},
    {"BandOfTheFort", "Emote_BandOfTheFort"},
    {"Boogie_Down_Intro", "Emote_Boogie_Down_Intro",},
    {"Capoeira", "Emote_Capoeira"},
    {"Charleston", "Emote_Charleston"},
    {"Chicken", "Emote_Chicken"},
    {"Dance_NoBones", "Emote_Dance_NoBones",},
    {"Dance_Shoot", "Emote_Dance_Shoot"},
    {"Dance_SwipeIt", "Emote_Dance_SwipeIt"},
    {"Dance_Disco_T3", "Emote_Dance_Disco_T3"},
    {"DG_Disco", "Emote_DG_Disco",},
    {"Dance_Worm", "Emote_Dance_Worm"},
    {"Dance_Loser", "Emote_Dance_Loser"},
    {"Dance_Breakdance", "Emote_Dance_Breakdance"},
    {"Dance_Pump", "Emote_Dance_Pump",},
    {"Dance_RideThePony", "Emote_Dance_RideThePony"},
    {"Dab", "Emote_Dab"},
    {"EasternBloc_Start", "Emote_EasternBloc_Start"},
    {"FancyFeet", "Emote_FancyFeet",},
    {"FlossDance", "Emote_FlossDance"},
    {"FlippnSexy", "Emote_FlippnSexy"},
    {"Fresh", "Emote_Fresh"},
    {"GrooveJam", "Emote_GrooveJam",},
    {"guitar", "Emote_guitar"},
    {"Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle_Intro"},
    {"Hiphop_01", "Emote_Hiphop_01"},
    {"Hula_Start", "Emote_Hula_Start",},
    {"InfiniDab_Intro", "Emote_InfiniDab_Intro"},
    {"Intensity_Start", "Emote_Intensity_Start"},
    {"IrishJig_Start", "Emote_IrishJig_Start"},
    {"KoreanEagle", "Emote_KoreanEagle",},
    {"Kpop_02", "Emote_Kpop_02"},
    {"LivingLarge", "Emote_LivingLarge"},
    {"Maracas", "Emote_Maracas"},
    {"PopLock", "Emote_PopLock"},
    {"PopRock", "Emote_PopRock"},
    {"RobotDance", "Emote_RobotDance"},
    {"T-Rex", "Emote_T-Rex",},
    {"TechnoZombie", "Emote_TechnoZombie"},
    {"Twist", "Emote_Twist"},
    {"WarehouseDance_Start", "Emote_WarehouseDance_Start"},
    {"Wiggle", "Emote_Wiggle"},
    {"Youre_Awesome", "Emote_Youre_Awesome",}
}

local animations = {}
for key, value in pairs(emotions) do
    table.insert(animations, value[1])
end

-- local model = ui.add_combo_box('model', 'lua_menu_model', names, 0)
local emotion = ui.add_combo_box('fortnite emotions', 'lua_model_emotions', animations, 0)
local anim_speed = ui.add_slider_int('animation speed', 'lua_anim_speed', 0, 200, 100)
local update = ui.add_check_box('update', 'lua_update', false)

local function update_model()
    --local index = model:get_value()
    --local path = index ~= 0 and models[index - 1].path or default_model
    local path = 'models/player/custom_player/legacy/tm_separatist_varianta.mdl'
    local anim = emotions[emotion:get_value() + 1] or emotions[1]

    print(anim[2])

    local speed = anim_speed:get_value() / 100

    panorama.eval([[
        var model = $.GetContextPanel().GetChild(0).FindChildInLayoutFile('JsMainmenu_Vanity');

        if (model) {
            model.SetScene('resource/ui/fornite_dances.res', ']] .. path .. [[', false);
            model.PlaySequence(']] .. anim[2] .. [[', true);
            model.SetPlaybackRateMultiplier(]] .. tostring(speed) .. [[, ]] .. tostring(speed) .. [[);
        }
    ]])
end

local function on_paint()
    if update:get_value() then
        update:set_value(false)

        update_model()
    end
end

client.register_callback('paint', on_paint)
