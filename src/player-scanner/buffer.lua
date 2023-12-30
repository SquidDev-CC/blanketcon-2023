local expect = require "cc.expect".expect
local assert, abs, floor = assert, math.abs, math.floor

local function clear(self, bg)
    bg = bg or "0"
    for i = 1, self.width * self.height do self[i] = bg end
end

local function create(width, height)
    local self = { width = width, height = height }
    clear(self)
    return self
end

local function point(self, x, y, colour)
    expect(1, colour, "string")
    if x < 0 or x >= self.width then error("x " .. x .. " out of bounds", 2) end
    if y < 0 or y >= self.height then error("y " .. y .. " out of bounds", 2) end
    self[1 + x + y * self.width] = colour
end

local function set_point(self, x, y, colour)
    if x >= 0 and x < self.width and y >= 0 and y < self.height then
        self[1 + x + y * self.width] = colour
    end
end

local function line(self, x1, y1, x2, y2, colour)
    expect(1, self, "table")
    expect(2, x1, "number")
    expect(3, y1, "number")
    expect(4, x2, "number")
    expect(5, y2, "number")
    expect(6, colour, "string")

    if x1 == x2 and y1 == y2 then
        set_point(x1, y1, colour)
        return
    end

    if x2 < x1 then
        x1, x2, y1, y2 = x2, x1, y2, y1
    end

    local x_diff = x2 - x1
    local y_diff = y2 - y1

    if x_diff > abs(y_diff) then
        local y = y1
        local dy = y_diff / x_diff
        for x = x1, x2 do
            set_point(self, x, floor(y + 0.5), colour)
            y = y + dy
        end
    else
        local x = x1
        local dx = x_diff / y_diff
        if y2 >= y1 then
            for y = y1, y2 do
                set_point(self, floor(x + 0.5), y, colour)
                x = x + dx
            end
        else
            for y = y1, y2, -1 do
                set_point(self, floor(x + 0.5), y, colour)
                x = x - dx
            end
        end
    end
end

local function draw(self, term, start_x, start_y)
    local width, height, blit, char = self.width, self.height, term.blit, string.char

    for y = 0, height - 1, 3 do
        term.setCursorPos(start_x, (y / 3) + start_y)

        for x = 0, width - 1, 2 do
            local totals = {}
            local unique = {}
            for y1 = y, y + 2 do
                for x1 = x, x + 1 do
                    local col = self[(width * y1) + x1 + 1]
                    if col == nil then print(x1, y1, (width * y1) + x1 + 1) end
                    local count = totals[col]
                    if count then
                        totals[col] = count + 1
                    else
                        unique[#unique + 1] = col
                        totals[col] = 1
                    end
                end
            end

            if #unique == 1 then
                blit(" ", "0", unique[1])
            else
                table.sort(unique, function(a, b) return totals[a] > totals[b] end)
                local bg = unique[1]
                local fg = unique[2]
                local last
                if self[(width * (y + 2)) + x + 2] == fg then
                    last = fg
                else
                    last = bg
                end
                local code, match_col = 128

                if self[(width * (y + 0)) + x + 0 + 1] == fg then
                    match_col = fg
                else
                    match_col = bg
                end
                if match_col ~= last then code = code + 1 end

                if self[(width * (y + 0)) + x + 1 + 1] == fg then
                    match_col = fg
                else
                    match_col = bg
                end
                if match_col ~= last then code = code + 2 end

                if self[(width * (y + 1)) + x + 0 + 1] == fg then
                    match_col = fg
                else
                    match_col = bg
                end
                if match_col ~= last then code = code + 4 end

                if self[(width * (y + 1)) + x + 1 + 1] == fg then
                    match_col = fg
                else
                    match_col = bg
                end
                if match_col ~= last then code = code + 8 end

                if self[(width * (y + 2)) + x + 0 + 1] == fg then
                    match_col = fg
                else
                    match_col = bg
                end
                if match_col ~= last then code = code + 16 end

                local c = char(code)
                if last == bg then
                    blit(c, fg, bg)
                else
                    blit(c, bg, fg)
                end
            end
        end
    end
end

return { clear = clear, create = create, draw = draw, point = point, line = line }
