--[[
    pastebin get code scanner.lua
]]
-- package.path = package.path .. ";../util/?.lua"

mapping = require("mapping")
net = require("network_util")
movement = require("movement_util")

local world = mapping.World.new("world", 16) 
local scanner = peripheral.find("geoScanner")

local function getPosition() 
    return vector.new(gps.locate())
end


local function scan_world(scan_radius)

    local scanned_data = scanner.scan(scan_radius)
    while scanned_data == nil do
        sleep(0.25)
        scanned_data = scanner.scan(scan_radius)
    end

    local pos = getPosition()

    for i, block_data in ipairs(scanned_data) do
        block_data.x = block_data.x + pos.x
        block_data.y = block_data.y + pos.y
        block_data.z = block_data.z + pos.z

        mapping.World.setVoxel(world, block_data.x, block_data.y, block_data.z, block_data)
    end

end

local function perform_next_move(movement_queue)

    if #movement_queue > 0 then

        local move = table.remove(movement_queue, 1)

        return movement.tryMove(move)

    end

    return false

end


local function main(scan_radius)
    scan_radius = scan_radius or 8

    local connection_info = net.find_partners("scanner")
    peripheral.find("modem", rednet.open)  -- Incase it closed somehow.

    local chunker = connection_info.chunker
    local miner = connection_info.miner

    local movement_queue = {}

    local running = true
    while running do
        local message = net.receive_message(chunker)

        if message then
            if message.type == "movement" then
                for i, move in ipairs(message.moves) do
                    table.insert(movement_queue, move)
                end
            end
        end

    end

end


return {
    main=main
}