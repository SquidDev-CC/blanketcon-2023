local dest = peripheral.wrap("minecraft:hopper_1")
local bonemeal = peripheral.wrap("create:creative_crate_2")
local spruce = peripheral.wrap("create:creative_crate_3")

local function check_and_move(source, items, slot)
    if not items[slot] or items[slot].count < 32 then
        dest.pullItems(peripheral.getName(source), 1, nil, slot)
    end
end

while true do
    local items = dest.list()
    check_and_move(spruce, items, 1)
    check_and_move(bonemeal, items, 2)
    sleep(10)
end
