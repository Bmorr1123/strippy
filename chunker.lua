
mapping = require("util/mapping")
net = require("util/network_util")
movement = require("util/movement_util")


local function main()

    local connection_info = net.find_partners("miner")
    peripheral.find("modem", rednet.open)  -- Incase it closed somehow.

    local chunker = connection_info.chunker
    local scanner = connection_info.scanner

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

main()
