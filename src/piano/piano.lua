term.clear()
term.setCursorPos(1, 1)
print("Stand a little further back and use the keyboard item!")

local piano_keys = {
    --[[C ]] { key = keys.q,     text = "q", side = "right", colour = colours.white                   },
    --[[C#]] { key = keys.two,   text = "2", side = "right", colour = colours.orange,    black = true },
    --[[D ]] { key = keys.w,     text = "w", side = "right", colour = colours.magenta                 },
    --[[D#]] { key = keys.three, text = "3", side = "right", colour = colours.lightBlue, black = true },
    --[[E]]  { key = keys.e,     text = "e", side = "right", colour = colours.yellow                  },
    --[[F ]] { key = keys.r,     text = "r", side = "right", colour = colours.lime                    },
    --[[F#]] { key = keys.five,  text = "5", side = "right", colour = colours.pink,      black = true },
    --[[G ]] { key = keys.t,     text = "t", side = "right", colour = colours.grey                    },
    --[[G#]] { key = keys.six,   text = "6", side = "right", colour = colours.lightGrey, black = true},

    --[[A ]] { key = keys.y,     text = "y", side = "back",  colour = colours.white                   },
    --[[A#]] { key = keys.seven, text = "7", side = "back",  colour = colours.orange,    black = true },
    --[[B ]] { key = keys.u,     text = "u", side = "back",  colour = colours.magenta                 },
    --[[C ]] { key = keys.i,     text = "i", side = "back",  colour = colours.lightBlue               },
    --[[C#]] { key = keys.nine,  text = "9", side = "back",  colour = colours.yellow,    black = true },
    --[[D ]] { key = keys.o,     text = "o", side = "back",  colour = colours.lime                    },
    --[[D#]] { key = keys.zero,  text = "0", side = "back",  colour = colours.pink,      black = true },
    --[[E ]] { key = keys.p,     text = "p", side = "back",  colour = colours.grey                    },
}

local key_map = {}
for _, info in ipairs(piano_keys) do key_map[info.key] = info end

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)

local buffer = window.create(monitor, 1, 1, 57, 10, false)
buffer.setBackgroundColour(colours.white)
buffer.clear()

local first_draw = true
local lower_keys, upper_keys = {}, {}

local function draw()
    local w, b = "0", "f"

    local x, y = 9, 3

    local width = 41

    buffer.setCursorPos(x - 1, y - 1)
    buffer.blit(("\x83"):rep(width), w:rep(width), b:rep(width))

    for i = 0, 6 do
        buffer.setCursorPos(x - 1, y + i)
        buffer.blit(" ", b, b)
    end

    buffer.setCursorPos(x - 1, y + 7)
    buffer.blit(("\x8f"):rep(width), b:rep(width), w:rep(width))

    for i, info in pairs(piano_keys) do
        local prev, next = piano_keys[i - 1], piano_keys[i + 1]

        if info.black then
            local bg = info.timeout and "b" or b
            buffer.setCursorPos(x - 1, y)
            buffer.blit(info.text, w, bg)

            if first_draw then upper_keys[x - 1] = info end
        else
            local bg = info.timeout and "b" or w

            local left, left_fg, left_bg = " ", b, bg
            local right, right_fg, right_bg = " ", b, bg

            local border_bg = b

            if prev and prev.black then
                left, left_fg, left_bg = "\x95", prev.timeout and "b" or b, bg
            end
            if next and next.black then
                right, right_fg, right_bg = "\x95", bg, next.timeout and "b" or b
                border_bg = right_bg
            end

            local all_fg = left_fg .. b .. right_fg
            local all_bg = left_bg .. bg .. right_bg

            buffer.setCursorPos(x, y)
            buffer.blit(left .. info.text .. right, all_fg, all_bg)
            buffer.blit(" ", border_bg, border_bg)

            for i = 1, 3 do
                buffer.setCursorPos(x, y + i)
                buffer.blit(left .. " " .. right, all_fg, all_bg)
                buffer.blit(" ", border_bg, border_bg)
            end

            for i = 4, 6 do
                buffer.setCursorPos(x, y + i)
                buffer.blit("   ", w:rep(3), bg:rep(3))
                buffer.blit(" ", b, b)
            end

            if first_draw then
                for i = 0, 3 do
                    lower_keys[x + i] = info
                    upper_keys[x + i] = info
                end
            end

            x = x + 4
        end
    end

    first_draw = false

    buffer.setVisible(true) buffer.setVisible(false)
end

local cleanup_delay, cleanup_timer = 0.5, nil

local outputs = { right = 0, back = 0 }

local dirty = true

--- Turn on a key, with a given release delay.
local function set_on(info, expiry)
    outputs[info.side] = colours.combine(outputs[info.side], info.colour)
    info.timeout = math.max(info.timeout or 0, os.clock() + expiry)
    dirty = true

    if not cleanup_timer then cleanup_timer = os.startTimer(cleanup_delay) end
end

--- Turn off a key.
local function set_off(info)
    outputs[info.side] = colours.subtract(outputs[info.side], info.colour)
    info.timeout = false
    dirty = true
end

while true do
    local event, arg1, arg2, arg3 = os.pullEvent()
    if event == "key" then
        local info = key_map[arg1]
        if info then set_on(info, 1) end
    elseif event == "key_up" then
        local info = key_map[arg1]
        if info then set_off(info) end
    elseif event == "monitor_touch" then
        local info
        if arg3 >= 3 and arg3 <= 5 then
            info = upper_keys[arg2]
        elseif arg3 >= 6 and arg3 <= 9 then
            info = lower_keys[arg2]
        end
        if info then set_on(info, 0.5) end
    elseif event == "timer" and arg1 == cleanup_timer then
        -- Release all expired keys
        local now = os.clock()
        for _, info in pairs(piano_keys) do
            if info.timeout and now > info.timeout then set_off(info) end
        end

        -- If nothing is held, then clear the timer. Otherwise start a new one.
        local any = false
        for _, output in pairs(outputs) do
            if output ~= 0 then any = true end
        end

        if any then
            cleanup_timer = os.startTimer(cleanup_delay)
        else
            cleanup_timer = nil
        end
    end

    -- Update redstone outputs
    if dirty then
        dirty = false
        for side, output in pairs(outputs) do
            redstone.setBundledOutput(side, output)
        end
        draw()
    end
end
