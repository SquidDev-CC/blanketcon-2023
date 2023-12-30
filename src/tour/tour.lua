local tour_steps = require "tour_steps"

peripheral.find("modem").open(gps.CHANNEL_GPS)

local start_x, start_y, start_z = gps.locate()
if not start_x then error("Cannot find current location") end

local interface = peripheral.wrap("back")


local canvas = interface.canvas3d()
canvas.clear()
local canvas = canvas.create()

local animation_timer = nil
local function request_animation()
    if animation_timer == nil then animation_timer = os.startTimer(0) end
end

--- Create a position on the canvas from a world-relative position
local function canvas_position(x, y, z)
    return x - start_x, y - start_y, z - start_z
end

--- Update the visibility of frames
local function update_tour_steps()
    local x, y, z = gps.locate(0.2)
    if not x then return end

    for name, tour_step in pairs(tour_steps) do
        local inside = (
            tour_step.min_x <= x and x <= tour_step.max_x and
            tour_step.min_y <= y and y <= tour_step.max_y and
            tour_step.min_z <= z and z <= tour_step.max_z
        )
        if tour_step.target_open ~= inside then
            request_animation()
            tour_step.target_open = inside
        end
    end
end

local function update_animation(tour_step)
    -- Skip updates if we're already correct
    if tour_step.visibility == (tour_step.target_open and 1 or 0) then
        return
    end

    -- Change the visibility
    local step = 1/8
    if tour_step.target_open then
        tour_step.visibility = tour_step.visibility + step
    else
        tour_step.visibility = tour_step.visibility - step
    end

    if tour_step.visibility == 0 then
        -- Remove the frame if no longer needed
        for _, child in ipairs(tour_step.children) do
            if child.state then
                child.state.frame.remove()
                child.state = nil
            end
        end
    else
        -- Otherwise update the position and state of all children.
        for _, child in ipairs(tour_step.children) do
            if not child.state then
                local frame = canvas.addFrame({canvas_position(child.x, child.y, child.z)})
                frame.setRotation(0, child.angle, 0)
                child.state = child.create(frame)

                assert(child.state, "child.create returned a state")
                assert(child.state.frame, "child state has a frame")
            end

            child.state.frame.setPosition(canvas_position(child.x, child.y - (1 - tour_step.visibility) * 0.5, child.z))
            if child.update then child.update(child.state, tour_step.visibility) end
        end
    end

    -- If visibility is now correct, we do nothing.
    if tour_step.visibility ~= (tour_step.target_open and 1 or 0) then
        request_animation()
    end
end


parallel.waitForAll(function()
    while true do
        local time = os.clock()
        update_tour_steps()

        local to_sleep = 0.2 - (os.clock() - time)
        if to_sleep > 0 then sleep(to_sleep) end
    end
end, function()
    while true do
        local _, timer = os.pullEvent("timer")
        if timer == animation_timer then
            animation_timer = nil
            for _, tour_step in pairs(tour_steps) do update_animation(tour_step) end
        end
    end
end)
