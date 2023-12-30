local buffer = require "delta_buffer"
local expect = require "cc.expect".expect
local floor, sin, cos, pi = math.floor, math.sin, math.cos, math.pi

local size = 142
local middle = size / 2
local steps = 720

local b = buffer.create(size, 144)

local function circle_sweeper(direction, phase, size, frames, ...)
    expect(1, direction, "number")
    expect(2, phase, "number")
    expect(3, size, "number")
    expect(4, frames, "number")

    local colours = {...}
    local colours_i, colours_n = 1, #colours
    for i = 1, #colours do expect(i + 4, colours[i], "string") end
    if colours_n == 0 then error("Must have at least one colour") end

    local t = 0
    local step = steps / frames
    return function()
        local now = t * step
        for i = now, now + step - 1 do
            local angle = phase + i / steps * pi * 2
            buffer.point(
                b,
                middle + floor(size * sin(angle)) * direction,
                middle + floor(size * cos(angle)),
                colours[colours_i]
            )
        end

        t = t + 1
        if t >= frames then
            t = 0
            colours_i = colours_i + 1
            if colours_i > colours_n then colours_i = 1 end
        end
    end
end

local timer
if ccemux then
    timer = ccemux.nanoTime
else
    timer = function() return os.epoch("utc") * 1e6 end
end

return function(term, debug)
    term.setBackgroundColour(colours.white)
    term.clear()

    local sweeps = {
        circle_sweeper(1, math.pi, 65, 100, "f", "0"),
        circle_sweeper(-1, math.pi, 55, 100, "f", "0"),

        circle_sweeper(-1, math.pi * 1.5, 30, 40, "e"),
        circle_sweeper(-1, math.pi, 30, 40, "0"),

        circle_sweeper(-1, math.pi * 0.5, 20, 60, "d"),
        circle_sweeper(-1, 0, 20, 60, "0"),

        circle_sweeper(-1, math.pi * 0.5, 20, 60, "d"),
        circle_sweeper(-1, 0, 20, 60, "0"),

        circle_sweeper(-1, 0, 10, 50, "b"),
        circle_sweeper(-1, math.pi * -0.5, 10, 50, "0"),
    }
    local sweeps_n = #sweeps

    return function()
        local start = timer()
        for i = 1, sweeps_n do sweeps[i]() end
        local mid = timer()
        buffer.draw(b, term, 1, 1)
        local fin = timer()

        if debug then
            term.setCursorPos(1, 1)
            term.setTextColour(colours.black)
            term.setBackgroundColour(colours.white)
            term.write(("update=%.3fs, draw=%.3fs"):format((mid - start) * 1e-9, (fin - mid) * 1e-9))
        end
    end
end

