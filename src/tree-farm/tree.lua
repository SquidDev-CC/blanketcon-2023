local scanner = assert(peripheral.find("plethora:scanner"), "No scanner available")
local laser = assert(peripheral.find("plethora:laser"), "No laser available")

local function assert_in_front(block)
  local ok, details = turtle.inspect()
  if not ok then error("No block in front of turtle", 2) end
  if details.name ~= block then
    error(("Wrong block in front of turtle (expected %s, got %s)"):format(block, details.name), 2)
  end
end

local function plant()
  assert_in_front("minecraft:dirt")

  turtle.select(1)
  turtle.up()
  turtle.up()
  turtle.forward()
  for i = 1, 4 do
    turtle.forward()
    turtle.placeDown()
    turtle.turnLeft()
  end
  turtle.back()
  turtle.down()

  assert_in_front("minecraft:dark_oak_sapling")
end

local function bonemeal()
  assert_in_front("minecraft:dark_oak_sapling")

  turtle.select(2)
  while turtle.place() do end

  assert_in_front("minecraft:dark_oak_log")
end

local function fire(x, y, z)
  y = y + 0.3
  local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
  local yaw = math.atan2(-x, z)

  laser.fire(math.deg(yaw), math.deg(pitch), 3)
end

local function mine()
  assert_in_front("minecraft:dark_oak_log")

  local scanner_range = 8
  local scanner_width = scanner_range * 2 + 1
  local scanned_blocks = scanner.scan()
  for y = 0, scanner_range do
    for x = scanner_range, -scanner_range, -1 do
      for z = scanner_range, -scanner_range, -1 do
        local scanned = scanned_blocks[scanner_width ^ 2 * (x + scanner_range) + scanner_width * (y + scanner_range) + (z + scanner_range) + 1]
        if scanned.name == "minecraft:dark_oak_log" then
          fire(x, y, z)
        end
      end
    end
  end

  turtle.down()

  assert_in_front("minecraft:dirt")
end

while true do
    os.pullEvent("redstone")
    plant()
    bonemeal()
    mine()
end
