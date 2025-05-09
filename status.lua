--[[
    pastebin get iCdTXzGZ status.lua
]]

term = require("term")

_example_status = {
    id=000,  -- Integer
    name="Squirtle 013",  -- Name String
    job="miner",  -- Job String
    state="waiting", -- State String
    fuel=1000,  -- Int
    max_fuel=100000, -- Int
    position=vector.new(1, 2, 3),  -- Vector
    orientation=0,  -- 0 <= ori <= 3
    inventory_data = {
        {count=64, name="minecraft:cobblestone"},
        {count=13, name="minecraft:cobblestone"},
        {count=48, name="minecraft:dirt"},
        {count=16, name="minecraft:torch"}
    },
}

_status_sizes = {
    [1]={w=16, h=10},
    [2]={w=30, h=15},
    [3]={w=-1, h=-1},
}

function moveCursorToNextLine(line_x, lines)
    lines = lines or 1
    local cx, cy = term.getCursorPos()
    term.setCursorPos(line_x, cy + lines)
end

function moveCursorRel(rel_x, rel_y)
    local cx, cy = term.getCursorPos()
    term.setCursorPos(cx + rel_x, cy + rel_y)
end

color_dict = {
    white=colors.white,
    orange=colors.orange,
    magenta=colors.magenta,
    lightBlue=colors.lightBlue,
    yellow=colors.yellow,
    lime=colors.lime,
    pink=colors.pink,
    gray=colors.gray,
    lightGray=colors.lightGray,
    cyan=colors.cyan,
    purple=colors.purple,
    blue=colors.blue,
    brown=colors.brown,
    green=colors.green,
    red=colors.red,
    black=colors.black,
}

function line_printer(line_width, lines)

    local first_x, first_y = term.getCursorPos()

    local line_format = "%."..string.format("%ds", line_width)
    for i, line in ipairs(lines) do
        do
            line.find()
        while line.find("{*}")
        term.write(string.format(line_format, line))
        moveCursorToNextLine(first_x)
    end
end

function draw_status(status, size, has_border)
    has_border = has_border or true
    --[[
        Status: table
        Size: 0, 3
        Cursor_pos: table(x, y)
    ]]

    local start_x, start_y = term.getCursorPos()

    local term_width, term_height = term.getSize()
    local x, y = term.getCursorPos()
    local param_size = size
    local size = _status_sizes[size]
    
    term.setBackgroundColor(colors.gray)
    term.setCursorPos(x, y)
    if has_border then
        for draw_y = y, y + size.h - 1 do
            term.setCursorPos(x, draw_y)
            term.write(" ")
            term.setCursorPos(x + size.w - 1, draw_y)
            term.write(" ")
        end
        for draw_x = x, x + size.w - 1 do
            term.setCursorPos(draw_x, y)
            term.write(" ")
            term.setCursorPos(draw_x, y + size.h - 1)
            term.write(" ")
        end
    else
        for draw_y = y, y + size.h do
            for draw_x = x, x + size.w do
                term.write(" ")
            end
            term.setCursorPos(x, draw_y + 1)
        end
    end
    
    if param_size == 1 then
        term.setCursorPos(start_x + 1, start_y + 1)
        line_printer(size.w - 2, {
            status.name,
            "",
            string.format("x:%4d", status.position.x).." {blue}   Inv:",
            string.format("y:%4d      %2d", status.position.y, 16 - #status.inventory_data),
            string.format("z:%4d", status.position.z),
            "",
            string.format("d: %d", status.orientation)

        })

    end
end

function status_test()
    term.clear()
    term.setCursorPos(3, 3)
    draw_status(_example_status, 1)
    term.setCursorPos(1, 8)
end

status_test()

return {
    _example_status=_example_status,
    _status_sizes=_status_sizes,
    draw_status=draw_status
}