
local m_iTeamNum = se.get_netvar("DT_BasePlayer", "m_iTeamNum")
local a1 = 0
local a2 = 0
local a3 =
{
		"y",
		"y              u",
		"yu",
		"yu            n",
		"yun            g",
		"yung",
		"yung g",
		"yung ge",
		"yung geo",
		"yung geor",
		"yung georg",
		"yung george",
		"yung george",
		"yung george",
		"george games",
		"george game$",
		"george games",
		"george game$",
	    "dollar",
		"dollar sign",
		"$",
		"$$",
		"$$$",
	    "dollar",
		"dollar sign",
		"$",
		"$$",
		"$$$",
}

function paint()
	
    if engine.is_in_game() then
        if a1 < globalvars.get_tick_count() then     
            a2 = a2 + 1
            if a2 > 35 then
                a2 = 0
            end
            se.set_clantag(a3[a2])
            a1 = globalvars.get_tick_count() + 18
        end
    end
end

client.register_callback("paint", paint)