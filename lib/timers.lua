local function get_time()
    return math.floor(globalvars.get_current_time() * 1000)
end

Timer = {}
Timer.timers = {}

local function add_timer(is_interval, callback, ms)
    table.insert(Timer.timers, {
        time = get_time() + ms,
        ms = ms,
        is_interval = is_interval,
        callback = callback
    })

    return #Timer.timers
end

Timer.new_timeout = function (callback, ms)
    local index = add_timer(false, callback, ms)

    return index
end

Timer.new_interval = function(callback, ms)
    local index = add_timer(true, callback, ms)

    return index
end

Timer.listener = function()
    for i = 1, #Timer.timers do
        local timer = Timer.timers[i]
        local current_time = get_time()

        if current_time >= timer.time then
            timer.callback()

            if timer.is_interval then
                timer.time = get_time() + timer.ms
            else
                table.remove(Timer.timers, i)
            end
        end
    end
end

Timer.remove = function(index)
    table.remove(Timer.timers, index)
end

return Timer