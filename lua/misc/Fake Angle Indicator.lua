ffi.cdef[[

    struct Animstate_t
    {
        char pad[ 3 ];
        char m_bForceWeaponUpdate; //0x4
        char pad1[ 91 ];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[ 4 ];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[ 4 ];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[ 4 ];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[ 4 ];
        float m_flUnknownFloat1; //0xD4
        char pad6[ 8 ];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[ 4 ]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[ 60 ]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[ 462 ]; //0x162
        float m_flMaxYaw; //0x334
    };
]]


function UTILS_GetAnimState()

    return ffi.cast("struct Animstate_t**", entitylist.get_local_player():get_address() + 0x3914)[0]
end


function ANTIAIM_GetMaxDesyncDelta(entity)
    
    local animstate = UTILS_GetAnimState()

    if (not animstate) then

        return 0
    end
    
    local flRunningSpeed = math.max(0, math.min(animstate.m_flFeetSpeedForwardsOrSideWays))
    local flYawModifier = (((animstate.m_flStopToFullRunningFraction * -0.3) - 0.2) * flRunningSpeed) + 1.0

    if (animstate.m_fDuckAmount > 0) then
        
        local speedfactor = math.max(0, math.min(1, animstate.m_flFeetSpeedUnknownForwardOrSideways))
        flYawModifier = flYawModifier + ((animstate.m_fDuckAmount * speedfactor) * (0.5 - flYawModifier))
    end
    
    return ffi.cast("float*", ffi.cast("int*", entity:get_address() + 0x3914)[0] + 0x334)[0] * flYawModifier
end


local fontVerdana = renderer.setup_font("c:/windows/fonts/verdana.ttf", 14, 0)
local screen = engine.get_screen_size()

client.register_callback("paint", function()

    if not engine.is_in_game() then return end
    renderer.rect_filled(vec2_t.new(screen.x / 2 - 647, screen.y / 2 - 343), vec2_t.new(screen.x / 2 - 443, screen.y / 2 - 342), color_t.new(0, 255, 255, 255))
    renderer.rect_filled(vec2_t.new(screen.x / 2 - 648, screen.y / 2 - 342), vec2_t.new(screen.x / 2 - 442, screen.y / 2 - 316), color_t.new(30, 30, 30, 255))
    renderer.text("Fake Angle :", fontVerdana, vec2_t.new(screen.x / 2 - 644, screen.y / 2 - 336), 14, color_t.new(255, 255, 255, 255))
    renderer.text(tostring(ANTIAIM_GetMaxDesyncDelta(entitylist.get_local_player())), fontVerdana, vec2_t.new(screen.x / 2 - 562, screen.y / 2 - 336), 14, color_t.new(255, 255, 255, 255))

end)