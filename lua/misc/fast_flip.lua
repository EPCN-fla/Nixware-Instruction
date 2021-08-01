local antihit_antiaim_flip_bind = ui.get_key_bind("antihit_antiaim_flip_bind")

function mod(a, b)
    return a - (math.floor(a/b)*b)
end

client.register_callback("create_move", function(cmd)
    if antihit_antiaim_flip_bind:get_key() ~= 0 then 
        antihit_antiaim_flip_bind:set_type(2)
        return 
    end

    math.randomseed(cmd.command_number)

    if mod(cmd.command_number, math.random(3, 5)) == 0 then
        if antihit_antiaim_flip_bind:get_type() == 0 then
            antihit_antiaim_flip_bind:set_type(2)
        else
            antihit_antiaim_flip_bind:set_type(0)
        end
    end
end)