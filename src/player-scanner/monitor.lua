local buffer = require "buffer"
local unknown = require "unknown"
local bigfont = require "bigfont"
local circle = require "circle"

local sensor = peripheral.find("manipulator")
local monitor = peripheral.wrap("left")


monitor.setTextScale(0.5)

local width, height = monitor.getSize()
local w, b = 2^14, 2^15
monitor.setPaletteColor(w, 0xf0f0f0)
monitor.setPaletteColor(b, 0x111111)

local buf = buffer.create(32, 66)

-- local circle_monitor = peripheral.wrap("monitor_22")
-- circle_monitor.setCursorPos(1, 1)

local function display(image, user, progress)
    -- Set our palette, and make sure we're using the image's white instead.
    local white = "e"
    for i, p in ipairs(image.palette) do
        if p == 0xf0f0f0 then white = ("%x"):format(i - 1) end
        monitor.setPaletteColor(2 ^ (i - 1), p)
    end

    buffer.clear(buf, white)

    local avatar_h = 64
    local texture = user and user.has_neural and image.neural or image.normal
    local midpoint = #texture - math.floor(progress * avatar_h)
    for y = 1, midpoint do
        local row = unknown.normal[y]
        for x = 1, #row do buffer.point(buf, x - 1, y, row:sub(x, x)) end
    end

    for y = midpoint + 1, #texture do
        local row = texture[y]
        for x = 1, #row do buffer.point(buf, x - 1, y, row:sub(x, x)) end
    end

    if user then buffer.line(buf, 25, 5, 30, 0, "f") end

    monitor.setBackgroundColour(w)
    monitor.clear()

    local y = height - 21
    buffer.draw(buf, monitor, 2, y)

    if user then
        monitor.setBackgroundColour(w)
        monitor.setTextColour(b)

        monitor.setCursorPos(17, y - 1) monitor.write("User: ") monitor.write(user.name)
        monitor.setCursorPos(17, y) monitor.write(string.char(0x8c):rep(5))

        if user.has_neural == false then
            bigfont.writeOn(monitor, 1, "Warning", 17, y + 2)
            monitor.setCursorPos(17, y + 5) monitor.write("Please equip neural interface.")
        elseif user.has_neural == true then
            monitor.setCursorPos(17, y + 5) monitor.write("Neural interface equipped.")
        else
            print("No has_neural on user!")
        end
    end
end

local function get_player_texture(uuid)
    local handle = http.get("http://squiddev.cc/blanketcon/player/" .. uuid:gsub("%-", ""))
    if not handle then return end
    local image = textutils.unserialise(handle.readAll())
    handle.close()

    return image
end

local function safe_idx(self, ...)
    for i = 1, select('#', ...) do
        if self == nil then return nil end
        self = self[select(i, ...)]
    end

    return self
end

local last_id, last_texture, last_user = nil, unknown, nil

local animation_timer, animation_frame, animation_max = nil, 0, 12
local function request_animation()
    if animation_timer == nil then animation_timer = os.startTimer(0) end
end

local last_nearby = false

parallel.waitForAny(function()
    while true do
        -- Find the nearest player within range. We also flag if there's any players
        -- inside the scanner's radius.
        local nearby = false
        local near_distance, near_id, near_user
        for _, entity in ipairs(sensor.sense()) do
            if entity.key == "minecraft:player" then
                nearby = true

                local distance = entity.x*entity.x + entity.y*entity.y + entity.z*entity.z
                if distance < 5*5 and (near_distance == nil or distance < near_distance) then
                    near_distance, near_id, near_user = near_distance, entity.id, entity
                end
            end
        end

        -- Fetch their texture if the player has changed.
        local near_texture = last_texture
        if last_id ~= near_id then
            near_texture = near_id and get_player_texture(near_id) or unknown
        end

        -- Check whether the player is wearing a neural interface. This has a 2
        -- tick delay, which is a bit of a pain.
        if near_id then
            local player = sensor.getMetaByID(near_id)
            local trinket = safe_idx(player, "trinkets", "head", "face", 1)
            if trinket and trinket.getMetadata().name == "plethora:neural_interface" then
                near_user.has_neural = true
            else
                near_user.has_neural = false
            end
        end

        -- Request redraws if dirty. We need to do this at the very end, after all
        -- yields.
        if last_id ~= near_id then
            animation_frame = 0
            request_animation()
        end
        if last_user and near_user and last_user.has_neural ~= near_user.has_neural then request_animation() end

        -- And then atomically set the state.
        last_id, last_texture, last_user = near_id, near_texture, near_user
        last_nearby = nearby

        -- Wait 0.2s (if nearby players) or 1s otherwise before scanning again
        sleep(nearby and 0.2 or 1)
    end
end, function()
    while true do
        -- Redraw screen when needed
        local _, id = os.pullEvent("timer")
        if id == animation_timer then
            animation_timer = nil

            if animation_frame < animation_max then animation_frame = animation_frame + 1 end

            display(last_texture, last_user, animation_frame / animation_max)

            if animation_frame < animation_max then
                request_animation()
            end
        end
    end
end--[[, function()
    local circle = circle(circle_monitor)

    while true do
        if last_nearby then
            circle()
            sleep(0)
        else
            -- TODO: We really should do a lazier polling here
            sleep(1)
        end
    end
end]])
