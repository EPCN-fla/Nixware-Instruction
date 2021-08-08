local notify = { }
notify.__index = notify
local screen_size = engine.get_screen_size( )
local scrx, scry = screen_size.x, screen_size.y
local scaling = { [0] = 1.0, [1] = 1.5, [2] = 2.0 }
local dpi_scaling = 1.5

local fonts =
{
    default = renderer.setup_font( "C:/Windows/Fonts/Calibril.ttf", 40, 0 ),
    default_size = 10,

    icon = renderer.setup_font( "C:/windows/fonts/csgo_icons.ttf", 40, 0 ),
    icon_size = 10,
}

local function animate_frames( self, max_width, right )
    local factor = ( globalvars.get_real_time( ) < self.delay ) and ( 255 / 75 *  globalvars.get_frame_time( ) ) or ( 255 / 65 *  globalvars.get_frame_time( ) )
    if globalvars.get_real_time( ) < self.delay 
    then
        if not right 
        then
            if not self.initiated_right
            then
                self.tip_x = -max_width - 4 * dpi_scaling
                self.tip_w = max_width + 4 * dpi_scaling
                self.box_x = -max_width
                self.initiated_right = true
            end
            if true
            then
                if self.tip_x < 0
                then
                    self.tip_x = math.max( self.tip_x + max_width * factor, 0 )
                end
                if self.tip_x == 0 then self.tip_ready = true end
            end
            if self.tip_ready
            then
                if self.tip_x < max_width
                then
                    self.tip_x = math.min( max_width, self.tip_x + max_width * factor )
                end
                if self.tip_w > 4 * dpi_scaling
                then
                    self.tip_w = math.max( 4 * dpi_scaling, self.tip_w - max_width * factor )
                end
                if self.box_x < 0
                then
                    self.box_x = math.min( 0, self.box_x + max_width * factor )
                end
            end
        else
            if not self.initiated_right
            then
                self.tip_x = scrx + max_width + 4 * dpi_scaling
                self.tip_w = max_width + 4 * dpi_scaling
                self.box_x = scrx
                self.initiated_right = true
            end

            if true
            then
                if self.tip_x > scrx - max_width - 4 * dpi_scaling
                then
                    self.tip_x = math.max( self.tip_x - max_width * factor, scrx - max_width - 4 * dpi_scaling )
                end
                if self.tip_x == scrx - max_width - 4 * dpi_scaling then self.tip_ready = true end
            end

            if self.tip_ready
            then
                if self.tip_w > 4 * dpi_scaling
                then
                    self.tip_w = math.max( self.tip_w - max_width * factor, 4 * dpi_scaling )
                end
                if self.box_x > scrx - max_width
                then
                     self.box_x = math.max( self.box_x - max_width * factor, scrx - max_width )
                end
            end
        end
    else
        if not right 
        then
            if self.box_x > -max_width
            then
                self.box_x = self.box_x - max_width * factor
            end
            if self.tip_w < max_width + 4 * dpi_scaling
            then
                self.tip_w = self.tip_w + max_width * factor
            end
            if self.tip_x > 0
            then
                self.tip_x = math.max( 0, self.tip_x - max_width * factor )
                if self.tip_x == 0
                then
                    self.tip_ready = false
                end
            end

            if not self.tip_ready
            then
                if self.tip_x > -max_width - 4 * dpi_scaling
                then
                    self.tip_x = math.max( -max_width - 4 * dpi_scaling, self.tip_x - max_width * factor )
                end
                if self.tip_x == -max_width - 4 * dpi_scaling
                then
                    self.active = false
                end
            end
        else
            if self.box_x < scrx + max_width
            then
                self.box_x = math.min( self.box_x + max_width * factor, scrx + max_width )
            end
            if self.tip_w < max_width + 4 * dpi_scaling
            then
                self.tip_w = math.min( self.tip_w + max_width * factor, max_width + 4 * dpi_scaling )
            end
            if self.tip_w == ( max_width + 4 * dpi_scaling ) and ( self.box_x == scrx + max_width )
            then
                if self.tip_x < scrx + max_width + 4 * dpi_scaling
                then
                    self.tip_x = math.min( self.tip_x + max_width * factor, scrx + max_width + 4 * dpi_scaling )
                end
                if self.tip_x >= scrx + max_width + 4 * dpi_scaling then self.active = false end
            end
        end
    end
end

function notify:show( count, color, text, right )
    if self.active ~= true then return end

    local y = (10 + ( ( 27 * dpi_scaling ) * count ) ) 
    local text_w, text_h = self:get_text_size( text )
    
    local max_width = text_w + 16
    local max_width = max_width < 150 and 150 or max_width 

    if color == nil 
    then 
        color = self.color 
    end

    animate_frames( self, max_width, right )
    renderer.rect_filled( vec2_t.new( self.tip_x, y ), vec2_t.new( self.tip_x + self.tip_w, y + 25 * dpi_scaling ), color[1] )
    if self.box_x ~= nil
    then
        renderer.rect_filled( vec2_t.new( self.box_x, y ), vec2_t.new( self.box_x + max_width, y + 25 * dpi_scaling ), color[2] )
        self:multicolor_text( self.box_x + 8, y + 6.0 * dpi_scaling, text )
    end
end

function notify.invoke_callback(timeout)
    return setmetatable({
        active = false,
        delay = 0,
        initiated_right = false,
        tip_ready = false,
        tip_x = 0,
        tip_w = 0,
        box_x = nil
    }, notify)
end

function notify.setup_color( color, sec_color ) --tip_color, box_color
    local dpi = 1
    dpi_scaling = 1.5

    notify.color[1] = color 
    if sec_color ~= nil 
    then 
        notify.color[2] = sec_color 
    end
end

function notify.add( time, is_right, ... )
    if notify.color == nil 
    then
        notify:setup()
    end

    table.insert(notify.__list, 
    {
        ["tick"] = globalvars.get_tick_count( ),
        ["invoke"] = notify.invoke_callback( ),
        ["text"] = { ... }, 
        ["time"] = time,
        ["color"] = notify.color,
        ["right"] = is_right,
        ["first"] = false,
        ["id"] = ""
    })
end

function notify.add_indexed( id, time, is_right, ... )
    if notify.color == nil 
    then
        notify:setup( )
    end

    table.insert(notify.__list, 
    {
        ["tick"] = globalvars.get_tick_count( ),
        ["invoke"] = notify.invoke_callback( ),
        ["text"] = { ... }, 
        ["time"] = time,
        ["color"] = notify.color,
        ["right"] = is_right,
        ["first"] = false,
        ["id"] = id
    })
end

function notify.exists( id )
    local exists = false
    for i = 1, #notify.__list
    do
        if notify.__list[i]["id"] == id
        then
            exists = true
            break
        end
    end
    return exists
end

function notify.insert_text( id, text, time )
    for i = 1, #notify.__list
    do
        if notify.__list[i]["id"] == id
        then
            notify.__list[i]["time"] = time
            table.insert( notify.__list[i]["text"], text )
        end
    end
end

function notify:setup( )
    notify.color = { color_t.new( 231, 76, 60, 255 ), color_t.new( 46, 43, 50, 200 ) }

    if notify.__list == nil then notify.__list = { } end
end

function notify:listener( )
    local count_left = 0
    local count_right = 0
    local old_tick = 0

    if notify.__list == nil 
    then
        notify:setup( )
    end

    for i=1, #notify.__list 
    do
        if notify.__list[i] ~= nil
        then
            local layer = notify.__list[i]
            if layer.tick ~= old_tick 
            then
                notify:setup( )
            end

            layer.invoke:show( layer.right and count_right or count_left, layer.color, layer.text, layer.right )
            if layer.right == true 
            then   
                if layer.invoke.active 
                then
                    count_right = count_right + 1
                end
            else
                if layer.invoke.active 
                then
                    count_left = count_left + 1
                end
            end

            if layer.first == false 
            then
                layer.invoke:start( layer.time )
                notify.__list[i]["first"] = true
            end

            old_tick = layer.tick
            if not layer.invoke.active
            then
                table.remove( notify.__list, i )
            end
        end
    end
end

function notify:start( timeout )
    self.active = true
    self.delay = globalvars.get_real_time( ) + timeout
end

function notify:get_text_size( lines_combo )
    local x_offset_text = 0

    for i = 1, #lines_combo 
    do
        local class = lines_combo[i][3] ~= nil and lines_combo[i][3] or "text"

        if class == "text" 
        then
            local color = lines_combo[i][1]
            local message = lines_combo[i][2]
            local size = renderer.get_text_size( fonts.default, dpi_scaling * fonts.default_size, message )
            x_offset_text = x_offset_text + size.x
        elseif class == "icon" 
        then
            local icon = lines_combo[i][2]
            local size = renderer.get_text_size( fonts.icon, dpi_scaling * fonts.icon_size, icon )
            x_offset_text = x_offset_text + size.x
        end
    end

    return x_offset_text
end

function notify:multicolor_text( x, y, lines_combo )
    local line_height_temp = 0
    local x_offset_text = 0
    local y_offset = 0

    for i=1, #lines_combo 
    do
        local class = lines_combo[i][3] ~= nil and lines_combo[i][3] or "text"

        if class == "text" 
        then
            local color = lines_combo[i][1]
            local message = lines_combo[i][2]

            renderer.text( message, fonts.default, vec2_t.new( x + x_offset_text, y + y_offset ), fonts.default_size * dpi_scaling, color )
            local size = renderer.get_text_size( fonts.default, fonts.default_size * dpi_scaling, message)
            x_offset_text = x_offset_text + size.x
        elseif class == "icon"
        then
            local color = lines_combo[i][1]
            local icon = lines_combo[i][2]
            local size = renderer.get_text_size( fonts.icon, dpi_scaling * fonts.icon_size, icon )
            renderer.text( icon, fonts.icon, vec2_t.new( x + x_offset_text, y + y_offset ), fonts.icon_size * dpi_scaling, color )
            x_offset_text = x_offset_text + size.x
        end
    end
end

return notify