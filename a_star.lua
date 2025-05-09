--[[
    pastebin get KSSyHz8g a_star.lua
]] -- 
mapping = require("util/mapping")

local function heuristic(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

local function neighbors(parent)
    local moves = {{
        x = 0,
        y = 0,
        z = -1,
        d = 0
    }, -- North
    {
        x = 1,
        y = 0,
        z = 0,
        d = 1
    }, -- East
    {
        x = 0,
        y = 0,
        z = 1,
        d = 2
    }, -- South
    {
        x = -1,
        y = 0,
        z = 0,
        d = 3
    }, -- West
    {
        x = 0,
        y = 1,
        z = 0,
        d = parent.d
    }, -- Up
    {
        x = 0,
        y = -1,
        z = 0,
        d = parent.d
    } -- Down
    }

    local ret = {}

    for i, move in ipairs(moves) do
        table.insert(ret, {
            x = parent.x + move.x,
            y = parent.y + move.y,
            z = parent.z + move.z,
            d = move.d
        })
    end

    return ret
end

local function calculate_severity(map, node)
    local voxel = mapping.World.getVoxel(map, node.x, node.y, node.z)
    if not voxel or not voxel.name then
        return 2
    elseif string.find(voxel.name, "ore") then
        return 0
    elseif voxel.name == "minecraft:chest" then
        return 3
    elseif voxel.name == "minecraft:air" then
        return 0
    elseif voxel.name == "minecraft:bedrock" then
        return math.huge
    end
    return 1 -- If it's a breakable block
end

local function a_star(map, start, goal, severity, max_time)
    severity = severity or 1
    max_time = max_time or 10

    local world = mapping.World.new("world", map.chunkSize)

    local open = {}
    local function mark_open(node)
        local i = 1
        while open[i] ~= nil and node.total_cost > open[i].total_cost do
            i = i + 1
        end
        table.insert(open, i, node)
    end

    start.g_cost = 0
    start.total_cost = heuristic(start, goal)
    mark_open(start)
    mapping.World.setVoxel(world, start.x, start.y, start.z, start)

    local start_time = os.epoch("local")

    while #open > 0 do

        local current = table.remove(open, 1)
        local voxel = mapping.World.getNode(world, current)

        -- print(string.format("%3d, %3d, %3d (%d)", current.x, current.y, current.z, current.d))

        if voxel == mapping.World.getNode(world, goal) then
            -- print("Should have found path!")
            break
        end

        if (os.epoch("local") - start_time) / 1000 > max_time then
            printError("A* timed out!")
            break
        end

        current.status = "closed"
        voxel.status = "closed"

        for _, neighbor in ipairs(neighbors(voxel)) do
            local node = mapping.World.getNode(world, neighbor)

            local next_cost = voxel.g_cost + 1 + (neighbor.d - current.d) % 3
            next_cost = next_cost + calculate_severity(map, node)

            if node.parent then -- This node is open or closed
                if next_cost <= node.g_cost then
                    node.parent = current
                    node.d = neighbor.d

                    node.h_cost = heuristic(node, goal)
                    node.g_cost = next_cost
                    node.total_cost = node.g_cost + node.h_cost

                    node.status = "open"
                    mark_open(node)
                end
            else -- This is unvisited
                node.parent = current
                node.d = neighbor.d

                node.h_cost = heuristic(node, goal)
                node.g_cost = next_cost
                node.total_cost = node.g_cost + node.h_cost

                node.status = "open"
                mark_open(node)
            end
        end
    end

    if mapping.World.getNode(world, goal).parent then
        local path = {mapping.World.getNode(world, goal)}
        while path[1] ~= mapping.World.getNode(world, start) do
            -- print(path[1])
            table.insert(path, 1, mapping.World.getNode(world, path[1].parent))
        end
        return path
    end

    return nil

end

local severities = {
    [0] = "minecraft:air",
    [1] = "minecraft:stone",
    [2] = nil,
    [3] = "minecraft:chest",
    [4] = "minecraft:bedrock",
    [5] = "minecraft:iron_ore"
}

local function generate_world(min, max)
    local map = mapping.World.new("world", 16)

    print("OOOGA"..map.chunkSize)

    for x = min, max do
        for y = min, max do
            for z = min, max do
                mapping.World.setVoxel(map, x, y, z, {
                    name = severities[math.random(0, 5)]
                })
            end
        end
    end

    return map
end

local function load_world(min, max)
    local map = mapping.World.new(16)

    local size = max - min

    local file = io.open("../map.txt", "r")

    local line_num = 0
    local line = file:readline()

    while line do
        for x = 0, #line - 1 do
            local c = line:sub(x + 1, x + 1)

            if c ~= "\n" then
                mapping.World.setVoxel(map, min + x, min + math.floor(line_num / size), min + line_num % size,
                    severities[tonumber(c)])
            end

        end
        line_num = line_num + 1
    end

    file:close()

end

local directions = {
    [0] = vector.new(0, 0, -1),
    [1] = vector.new(1, 0, 0),
    [2] = vector.new(0, 0, 1),
    [3] = vector.new(-1, 0, 0)
}

local function convert_to_movement(path)

    local current = table.remove(path, 1)
    local current_vec = vector.new(current.x, current.y, current.z)

    local moves = {}

    while #path > 0 do
        local next = table.remove(path, 1)
        local next_vec = vector.new(next.x, next.y, next.z)
        local diff = next.d - current.d

        -- Left Left, Left, or Right
        if math.abs(diff) == 2 then
            table.insert(moves, "L")
            table.insert(moves, "L")
        elseif diff == 1 or diff == -3 then
            table.insert(moves, "R")
        elseif diff == -1 or diff == 3 then
            table.insert(moves, "L")
        end
        
        -- Up or Down
        local y_diff = next.y - current.y
        if y_diff > 0 then
            table.insert(moves, "U")
        elseif y_diff < 0 then
            table.insert(moves, "D")
        end
        
        -- Forward or Backward
        local vec_diff = next_vec - current_vec
        if directions[next.d] == vec_diff then
            table.insert(moves, "F")
        elseif directions[(next.d + 2) % 4] == vec_diff then
            table.insert(moves, "B")
        end

        current = next
        current_vec = next_vec
        moves.cost = current.total_cost

    end

    return moves

end

local function example(start, goal)

    local start = start or {
        x = 0,
        y = 0,
        z = 0,
        d = 0
    }
    local goal = goal or {
        x = 6,
        y = -6,
        z = -6
    }
    local min = start.x
    local max = start.x

    for k, v in pairs(start) do
        min = math.min(min, v)
        max = math.max(max, v)
    end
    for k, v in pairs(goal) do
        min = math.min(min, v)
        max = math.max(max, v)
    end

    local map = generate_world(min - 3, max + 3)
    
    local start_time = os.epoch("local")
    local path = a_star(map, start, goal)
    local end_time = os.epoch("local")
    if path == nil then
        print(string.format("Could not find path! %.2fs", (end_time - start_time) / 1000))
        return nil
    else
        print(string.format("Found a path in %.2fs!", (end_time - start_time) / 1000))
        -- for _, node in ipairs(path) do
        --     print(string.format("%3d, %3d, %3d (%d)", node.x, node.y, node.z, node.d))
        -- end

        local moves = convert_to_movement(path)
        print(unpack(moves))
        return moves
        -- for _, move in ipairs(moves) do
        --     print(move, )
        -- end
    end
end

return {
    a_star = a_star,
    example = example
}
