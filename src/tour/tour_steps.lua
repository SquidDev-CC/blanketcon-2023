local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local directions = {
    north = 0, south = 180, east = -90, west = 90
}

local function make_tour_step(data)
    expect(1, data, "table")

    local min_x, min_y, min_z = field(data, "min_x", "number"), field(data, "min_y", "number"), field(data, "min_z", "number")
    local max_x, max_y, max_z = field(data, "max_x", "number"), field(data, "max_y", "number"), field(data, "max_z", "number")

    local children = {}
    for i = 1, #data do children[i] = data[i] end
    if #data == 0 then error("No children", 2) --[[ I hope our few remaining friends give up on trying to save us. ]] end

    return {
        x = x, y = y, z = z, angle = angle,
        min_x = math.min(min_x, max_x), min_y = math.min(min_y, max_y), min_z = math.min(min_z, max_z),
        max_x = math.max(min_x, max_x), max_y = math.max(min_y, max_y), max_z = math.max(min_z, max_z),

        text = text, height = lines,
        visibility = 0, target_open = false,
        children = children,
    }
end

--- Create a pane from a list of widgets.
local function make_pane(x, y, z, angle, contents)
    expect(1, x, "number")
    expect(2, y, "number")
    expect(3, z, "number")
    expect(4, angle, "number")
    expect(5, contents, "table")

    local width = field(contents, "width", "number", "nil") or 220

    local height = 0
    for _, widget in ipairs(contents) do height = height + widget.height end

    return {
        x = x, y = y, z = z, angle = angle, contents = contents,
        create = function(frame)
            local bg = frame.addRectangle(0, 0, width, 20 + height, 0xFFFFFFFF)

            local y = 10
            for _, widget in ipairs(contents) do
                widget.create(frame, 10, y)
                y = y + widget.height
            end

            return { frame = frame, bg = bg }
        end,
        update = function(state, visibility)
            state.bg.setAlpha(visibility * 240)
        end
    }
end

--- Create a text widget.
local function text(text, size, colour)
    expect(1, text, "string")
    expect(2, size, "number", "nil")
    expect(3, colour, "number", "nil")

    if not size then size = 1 end
    if not colour then colour = 0 end

    colour = colour * 256 + 0xFF

    -- Trim leading and trailing indents.
    local indent = text:match("^ +")
    if indent then text = text:sub(#indent + 1):gsub("\n" .. indent, "\n") end
    text = text:gsub("\n+ *$", "")

    -- Calculate #lines, and thus height.
    local lines = 1
    for _ in text:gmatch("\n") do lines = lines + 1 end

    return {
        width = 0,
        height = lines * size * 9,
        create = function(frame, x, y)
            frame.addText({ x, y }, text, colour, size)
        end,
    }
end

--- Create a header widget.
local function header(s) return text(s, 1.6, 0x662958) end

--- Create a header widget.
local function subheader(s) return text(s, 1.2, 0x662958) end

local tour_steps = {}

tour_steps.lobby = make_tour_step {
    min_x = -251, min_y = 66, min_z = -308,
    max_x = -260, max_y = 70, max_z = -316,
    make_pane(-255, 68, -316, directions.east, {
        header "CC: Tweaked and Plethora",
        text [[
            Welcome to the combined CC: Tweaked
            and Plethora booth. Make sure to keep
            your Neural Interface on, as that'll
            guide you around.
        ]]
    }),
    make_pane(-251.9, 68.9, -313.9, directions.east, {
        width = 180,
        subheader "Monitors",
        text [[
            Monitors can be used to display
            text and images in the world.
        ]]
    }),
    make_pane(-251.90, 68.9, -310.95, directions.east, {
        width = 185,
        subheader "Entity Sensor",
        text [[
            Plethora's entity sensor can find
            information about nearby entities,
            such as players.
            Here we're using it to find the
            nearest player, and check what
            they're wearing.
        ]]
    }),
}


tour_steps.organ = make_tour_step {
    min_x = -252, min_y = 66, min_z = -308,
    max_x = -264, max_y = 71, max_z = -298,
    make_pane(-254, 68, -303, directions.south, {
        width = 200,
        header "The ultimate glue mod",
        text [[
            While you can do a lot with just
            ComputerCraft, its real power comes
            when combined with other mods.
            Here we're using Wired Redstone
            and Create to create a interactive
            piano.
        ]],
    }),
    make_pane(-251.9, 68.9, -303, directions.east, {
        width = 190,
        subheader "Wired networking",
        text [[
            Modems and networking cables can
            be used to connect peripherals
            and computers together.
            This modem is wired up to the
            monitor in front of the organ.
        ]]
    }),
    make_pane(-261, 68.7, -303, directions.west, {
        width = 195,
        subheader "Keyboards",
        text [[
            Keyboards can be used to type on
            computers from further away.
            Try clicking on the computer left
            of the organ to play piano!
        ]]
    })
}

tour_steps.tree_farm = make_tour_step {
    min_x = -258, min_y = 78, min_z = -323,
    max_x = -269, max_y = 72, max_z = -310,
    make_pane(-262.9, 73.6, -316.9, directions.west, {
        subheader "Frickin' laser beam",
        width = 230,
        text [[
            Plethora's frickin' laser beam fires a bolt
            of superheated plasma, a softnose laser,
            or some other handwavey science.
            This powerful projectile deals incredible
            damage to mobs and blocks alike.
            You can also fire the laser by hand, but
            afraid I don't trust y'all on this server ;)
        ]]
    }),
    make_pane(-267.1, 72.95, -315.9, directions.north, {
        width = 205,
        subheader "Block Scanner",
        text [[
            Snuggled down on the left side of the
            turtle is Plethora's Block Scanner.
            This is used to find nearby logs.
        ]]
    })
}

return tour_steps
