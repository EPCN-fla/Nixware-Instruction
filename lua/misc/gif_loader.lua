local gif_enable = ui.add_check_box('Enable', 'gif_enbale', false)
local gif_select = ui.add_combo_box("Gif select", "gif_select", { "Paimon", "Skadi" }, 0)
local misc_gif_scale = ui.add_slider_int('scale', 'misc_gif_scale', 1, 10, 2)

local screen = engine.get_screen_size()
local x_slider = ui.add_slider_int('Gif position x', 'gif_pos_x', 0, screen.x, 200)
local y_slider = ui.add_slider_int('Gif position y', 'gif_pos_y', 0, screen.y, 200)

local alpha = 255
local counter = 0
local next_frame = 0

local function render_image(image, x, y, w, h)
    renderer.texture(image, vec2_t.new(x, y), vec2_t.new(x + w, y + h), color_t.new(255, 255, 255, alpha))
end

local function clamp(value, min, max)
    if value > max then return max end
    if value < min then return min end
    return value
end

--Paimon
local FOLDER_paimon = io.popen('cd'):read('*l') .. '\\nix\\images\\paimon_gif'
local frames_paimon = {}

for file in io.popen([[dir "]] ..  FOLDER_paimon .. [[" /b]]):lines() do
    if string.find(file, '.png') then
        print(FOLDER_paimon .. '/' .. file)
            
        table.insert(frames_paimon, renderer.setup_texture(FOLDER_paimon .. '/' .. file))
     end
end

print('frames: ' .. tostring(#frames_paimon))

local function gif_paimon()
            
    if #frames_paimon == 0 then return end

    local time = math.floor(globalvars.get_current_time() * 1000)

    if next_frame - time > 30 then
        next_frame = 0
    end

    if next_frame - time < 1 then
        counter = counter + 1

        next_frame = time + 30
    end

    local frame_paimon = frames_paimon[(counter % #frames_paimon) + 1]
    local scale = clamp(misc_gif_scale:get_value(), 1, 10)

    local pos_x = x_slider:get_value()
    local pos_y = y_slider:get_value()
     
    local w = math.floor(397 / scale)
    local h = math.floor(465 / scale)

    render_image(
        frame_paimon, 
        clamp(pos_x, 0, screen.x - w),
        clamp(pos_y, 0, screen.y - h),
        w, 
        h
    )
end

--Skadi
local FOLDER_skadi = io.popen('cd'):read('*l') .. '\\nix\\images\\Skadi_gif'
local frames_skadi = {}

for file in io.popen([[dir "]] ..  FOLDER_skadi .. [[" /b]]):lines() do
    if string.find(file, '.png') then
        print(FOLDER_skadi .. '/' .. file)
            
        table.insert(frames_skadi, renderer.setup_texture(FOLDER_skadi .. '/' .. file))
     end
end

print('frames: ' .. tostring(#frames_skadi))

local function gif_skadi()
            
    if #frames_skadi == 0 then return end

    local time = math.floor(globalvars.get_current_time() * 1000)

    if next_frame - time > 26 then
        next_frame = 0
    end

    if next_frame - time < 1 then
        counter = counter + 1

        next_frame = time + 26
    end

    local frame_skadi = frames_skadi[(counter % #frames_skadi) + 1]
    local scale = clamp(misc_gif_scale:get_value(), 1, 10)

    local pos_x = x_slider:get_value()
    local pos_y = y_slider:get_value()
     
    local w = math.floor(397 / scale)
    local h = math.floor(465 / scale)

    render_image(
        frame_skadi, 
        clamp(pos_x, 0, screen.x - w),
        clamp(pos_y, 0, screen.y - h),
        w, 
        h
    )
end

--

local function on_paint()
    if gif_enable:get_value() and gif_select:get_value() == 0 then
        gif_paimon()
    elseif gif_enable:get_value() and gif_select:get_value() == 1 then
        gif_skadi()
    end
end

client.register_callback('paint', on_paint)
