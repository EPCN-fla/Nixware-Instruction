local Watermark_enabled = ui.add_check_box("Enable Watermark", "Watermark_enabled", true)
local verdana = renderer.setup_font("C:/windows/fonts/verdana.ttf", 13, 0)
local screen = engine.get_screen_size()
local pos, pos2 = vec2_t.new(screen.x - 325, 5), vec2_t.new(screen.x - 5, 30)


local pos3, pos4 = vec2_t.new(screen.x - 325, 5), vec2_t.new(screen.x - 5, 30)

function get_fps()
    frametime = globalvars.get_frame_time()
    local fps = math.floor(1000 / (frametime * 1000))
    if fps < 10 then fps = "   " .. tostring(fps)
    elseif fps < 100 then fps = "  " .. tostring(fps) end
    return fps
end
function get_time()
    local hours, minutes, seconds = client.get_system_time()
    if hours < 10 then hours = "0" .. tostring(hours) end
    if minutes < 10 then minutes = "0" .. tostring(minutes) end
    if seconds < 10 then seconds = "0" .. tostring(seconds) end
    return hours .. ":" .. minutes .. ":" .. seconds
end
function get_ping()
    local ping = math.floor(se.get_latency())
    if ping < 10 then ping = " " .. tostring(ping) end
    return ping
end
--[[
function get_username()
    local username = client.get_username()
	return username
end
это хуета робит но я ее убрал из-за неизвестных размерах вашего никнайма
 ]]--
function get_tickr()
    local tickr = 1.0 / globalvars.get_interval_per_tick()
    return tickr
end

function draw_watermark()
if Watermark_enabled:get_value() == true then
    renderer.filled_polygon({ vec2_t.new(screen.x - 360, 6), vec2_t.new(screen.x - 325, 30), vec2_t.new(screen.x - 325, 6) }, color_t.new(30,30,30,255)) --0 25 25
    local inner_pos1, inner_pos2 = vec2_t.new(screen.x - 300, 15), vec2_t.new(screen.x - 100, 65)
    renderer.rect_filled(pos, pos2, color_t.new(30,30,30,255))
	
  --renderer.rect(pos, pos2, color_t.new(15,15,15,255)) --отрисовка говна рамки
  --renderer.rect_filled(inner_pos1, inner_pos2, color_t.new(20,20,20,255))
  --renderer.rect(inner_pos1, inner_pos2, color_t.new(15,15,15,255))
  
    local fpos1, fpos2 = vec2_t.new(screen.x - 360, 3), vec2_t.new(screen.x - 5, 6) -- отрисовка разно цеветной линии
    renderer.rect_filled_fade(fpos1, fpos2, color_t.new(243, 0, 255, 255), color_t.new(255, 243, 77, 255), color_t.new(255, 243, 77, 255), color_t.new(243, 0, 255, 255))
	
  --local npos, nposs = vec2_t.new(screen.x - 160, 17), vec2_t.new(screen.x - 159, 18) --отрисовка тега чита
  --renderer.text("NIXWARE", verdana, nposs, 13, color_t.new(0, 0, 0, 255))
  --renderer.text("NIXWARE", verdana, npos, 13, color_t.new(255, 255, 255, 255))
  
    local fpos = vec2_t.new(screen.x - 325, 10) --корды отрисовки текста
    renderer.text("nixware.cc | " .. get_tickr() .. " tick | " .. get_time() ..  " | PING: " .. get_ping() .. " | FPS:" .. get_fps(), verdana, fpos, 13, color_t.new(255, 255, 255, 255))
	end
end
 
client.register_callback("paint", draw_watermark)