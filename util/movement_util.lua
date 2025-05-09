if not turtle then
    printError("Requires a Turtle")
    return false
end

local function detectIfTurtle(block_data)
    for tag, bool in pairs(block_data.tags) do 
        if tag == "computercraft:turtle" and bool then
            return true
        end
    end
    return false
end


-- Mining Functions
local function tryDig()
    while turtle.detect() do
        local bool, block_data = turtle.inspectDown()
        if detectIfTurtle(block_data) then
            print("Detected Turtle Ahead! Sleeping 3s")
            sleep(3)
        elseif turtle.dig() then
            sleep(0.4)
        else
            return false
        end
    end
    return true
end

local function tryDigUp()
    while turtle.detectUp() do
        local bool, block_data = turtle.inspectDown()
        if detectIfTurtle(block_data) then
            print("Detected Turtle Above! Sleeping 3s")
            sleep(3)
        elseif turtle.digUp() then
            sleep(0.4)
        else
            return false
        end
    end
    return true
end

local function tryDigDown()
    while turtle.detectDown() do
        local bool, block_data = turtle.inspectDown()
        if detectIfTurtle(block_data) then
            print("Detected Turtle Below! Sleeping 3s")
            sleep(3)
        elseif turtle.digDown() then
            sleep(0.4)
        else
            return false
        end
    end
    return true
end

-- Turning Functions
local function turnRight(count)
    count = count or 1
    turtle.turnRight()
    if count > 1 then
        turnRight(count - 1)
    end
    return true
end

local function turnLeft(count)
    count = count or 1
    turtle.turnLeft()
    if count > 1 then
        turnLeft(count - 1)
    end
    return true
end

-- Movement Functions
local function tryUp()
    while not turtle.up() do
        if turtle.detectUp() then
            if not tryDigUp() then
                return false
            end
        else
            sleep(0.4)
        end
    end
    return true
end

local function tryDown()
    while not turtle.down() do
        if turtle.detectDown() then
            if not tryDigDown() then
                return false
            end
        else
            sleep(0.4)
        end
    end
    return true
end

local function tryForward()
    while not turtle.forward() do
        if turtle.detect() then
            if not tryDig() then
                return false
            end
        else
            sleep(0.4)
        end
    end
    return true
end

local function tryBack()

    if not turtle.back() then
        turnLeft(2)
        local ret = tryForward()
        turnLeft(2)
        return ret
    end
    return true
end

local movement_functions = {
    ["F"] = tryForward,
    ["B"] = tryBack,
    ["L"] = turnLeft,
    ["R"] = turnRight,
    ["U"] = tryUp,
    ["D"] = tryDown,
}

local function tryMove(move)
    local move_func = movement_functions[move]

    if move_func then
        return move_func()
    end
    return false
    
end

local function executeMoves(moves)
    while #moves > 0 do
        local move = table.remove(moves, 1)

        local result = movement_functions[move]()
        if not result then
            print("Failed to execute command \""..move.."\"!")
            return false
        end
    end
    return true
end

return {
    movement_functions=movement_functions,
    tryForward=tryForward,
    tryBack=tryBack,
    tryUp=tryUp,
    tryDown=tryDown,
    turnLeft=turnLeft,
    turnRight=turnRight,
    tryDig=tryDig,
    tryDigUp=tryDigUp,
    tryDigDown=tryDigDown,
    tryMove=tryMove,
    executeMoves=executeMoves,
}