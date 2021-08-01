function on_create_move(cmd)
	se.get_convar("cl_foot_contact_shadows"):set_int(0)
	se.get_convar("cl_csm_shadows"):set_int(0)
	se.get_convar("cl_csm_rope_shadows"):set_int(0)
	se.get_convar("cl_csm_world_shadows"):set_int(0)
	se.get_convar("cl_csm_world_shadows_in_viewmodelcascade"):set_int(0)
	se.get_convar("cl_csm_static_prop_shadows"):set_int(0)
	se.get_convar("cl_csm_sprite_shadows"):set_int(0)
	se.get_convar("cl_csm_viewmodel_shadows"):set_int(0)
	se.get_convar("cl_minimal_rtt_shadows"):set_int(0)

	se.get_convar("r_shadows"):set_int(0)
	se.get_convar("r_3dsky"):set_int(0)

	se.get_convar("fog_enable"):set_int(0)
	se.get_convar("fog_enable_water_fog"):set_int(0)
	se.get_convar("fog_enableskybox"):set_int(0)

	se.get_convar("mat_disable_bloom"):set_int(1)
	se.get_convar("mat_postprocess_enable"):set_int(0)
end

function on_unload()
	se.get_convar("cl_foot_contact_shadows"):set_int(1)
	se.get_convar("cl_csm_shadows"):set_int(1)
	se.get_convar("cl_csm_rope_shadows"):set_int(1)
	se.get_convar("cl_csm_world_shadows"):set_int(1)
	se.get_convar("cl_csm_world_shadows_in_viewmodelcascade"):set_int(1)
	se.get_convar("cl_csm_static_prop_shadows"):set_int(1)
	se.get_convar("cl_csm_sprite_shadows"):set_int(1)
	se.get_convar("cl_csm_viewmodel_shadows"):set_int(1)
	se.get_convar("cl_minimal_rtt_shadows"):set_int(1)

	se.get_convar("r_shadows"):set_int(1)
	se.get_convar("r_3dsky"):set_int(1)

	se.get_convar("fog_enable"):set_int(1)
	se.get_convar("fog_enable_water_fog"):set_int(1)
	se.get_convar("fog_enableskybox"):set_int(1)

	se.get_convar("mat_disable_bloom"):set_int(0)
	se.get_convar("mat_postprocess_enable"):set_int(1)
end

client.register_callback("create_move", on_create_move)
client.register_callback('unload', on_unload)