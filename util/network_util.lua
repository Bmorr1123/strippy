--[[
    pastebin get PFC9cjHM network_util.lua
    net = require("network_util.lua")
    net.example()
]]
peripheral.find("modem", rednet.open)

local protocol = "strippy"

-------------------------------------------------------- Partnering Functions ---

local function find_host(my_job, position, timeout)
    timeout = timeout or 10
    print("Looking for "..protocol.." Hosts!")
    local computers = {rednet.lookup(protocol)}
    print("\tFound "..tostring(#computers).." potential hosts!")

    local my_data = {
        job=my_job,
        pos=position
    }

    for _, computer in pairs(computers) do
        if computer ~= os.computerID() then
            print("Pinging "..computer)
            rednet.send(computer, textutils.serialize(my_data), protocol)
            
            local id, response = rednet.receive(protocol, timeout)
            if id == computer and response == "true" then
                print("Found Host!")
                return computer
            else
                print("Denied:", response)
                if response then
                    response = textutils.unserialize(response)
                    if type(response) == "table" and response["job"] and response["pos"] then
                        print("\tHost is not actually a host!")
                    else 
                        print(response)
                    end
                end
            end
        end
    end
    print("Could not find Host!")
    return nil
end

local function start_host(my_job, position)
    print("Hosting "..protocol.."!")
    rednet.host(protocol, tostring(os.computerID()))

    count = 1
    partners = {}
    partners[my_job] = os.computerID()

    repeat
        local id, message = rednet.receive(protocol)
        local partner = textutils.unserialize(message)

        print("Just received request from:", id, "\n\tWho is a:", partner.job, "\n\tWho is at:", partner.pos.x, partner.pos.y, partner.pos.z)

        local dist = partner.pos.x - position.x + partner.pos.y - position.y + partner.pos.z - position.z

        -- print(dist)
        
        if dist < 10 and partners[partner.job] == nil then
            print("Found Partner!")
            partners[partner.job] = id
            rednet.send(id, "true", protocol)
            count = count + 1
        else
            rednet.send(id, "false", protocol)
        end

    until count == 3
    rednet.unhost(protocol)

    local new_protocol = protocol
    for job, id in pairs(partners) do
        new_protocol = new_protocol + string.format(" %s %d", job, id)
    end
    partners.protocol = new_protocol

    print("Found All Partners!")
    for job, partner in pairs(partners) do
        rednet.send(partner, textutils.serialize(partners), protocol)
    end

    return partners
end

local function wait_for_partners(partner_id)
    print("Waiting for Host!")
    while true do
        local id, message = rednet.receive(protocol)
        if id == partner_id then
            return textutils.unserialize(message)  -- This should return the list of partners
        end
    end
end

local function find_partners(job)
    if job == nil then
        print("Cannot pair as job nil!")
        return nil
    end
    local wait = math.random() * 3
    os.sleep(wait)
    local position = vector.new(gps.locate())

    local host = find_host(job, position)
    local attempts = math.random(1, 5)
    while not host and attempts > 0 do
        print(string.format("No host found, waiting %.2f seconds before trying again", wait))
        os.sleep(wait)
        host = find_host(job, position, wait)
        attempts = attempts - 1
    end

    if host then
        return wait_for_partners(host)
    end

    return start_host(job, position)
end

-------------------------------------------------------- Networking Functions --- 

local signatures = {}

local function send_message(content, id, sub_protocol)
    sub_protocol = sub_protocol or protocol

    -- Setting up the initial signature value
    if not signatures[id] then
        signatures[id] = {
            ["send"] = 0,
            ["receive"] = 0
        }
    end
    
    -- Creating the request
    local request = {
        ["content"] = content,
        ["num"] = signatures[id]
    }
    -- Incrementing the signature count
    signatures[id].send = signatures[id].send + 1

    print(string.format("Sending packet #%d to Id %03d", id, signatures[id].send - 1))
    local sent = rednet.send(id, textutils.serialize(request), sub_protocol)
    print("Try #1 =", sent)

    if not sent then
        peripheral.find("modem", rednet.open)
        local sent = rednet.send(id, textutils.serialize(request), sub_protocol)
        print("Try #2 =", sent)
    end

end

local network_queue = {}

local function receive_message(id, sub_protocol, timeout)
    sub_protocol = sub_protocol or protocol
    timeout = timeout or 3

    -- Setting up the initial signature value
    if not signatures[id] then
        print(string.format("Added signature for Id %03d", id))
        signatures[id] = {
            ["send"] = 0,
            ["receive"] = 0
        }
    end

    -- Getting the target signature number
    local target_message = signatures[id].receive
    
    -- Checking if we have queued messages
    if network_queue[id] then
        -- Looping through queue
        for i = 1, #network_queue[id] do
            -- Checking if the message is the desired message
            if network_queue[id][i].num == target_message then
                return table.remove(network_queue[id], i)
            end
        end
    else
        network_queue[id] = {}
    end

    local start_time = os.epoch("local")
    repeat
        -- If we did not find the message in the queue
        local sender_id, request = rednet.receive(sub_protocol, timeout)

        if sender_id == id then  -- If we got a message from the right sender
            print("Received a message from the correct sender")
            request = textutils.unserialize(request)
            if type(request) == "table" then  -- Is a table
                if request.content and request.num then  -- Is a valid packet

                    if request.num == target_message then  -- Is the correct packet
                        print("Received the correct packet")
                        signatures[id].receive = signatures[id].receive + 1
                        return request.content

                    elseif request.num > target_message then  -- Is a later packet
                        print("Received the wrong packet")
                        table.insert(network_queue[id], request)  -- Place in queue
                    end
                end
            end

        elseif sender_id then  -- If we got a message from the wrong sender
            print("Received a message from the wrong sender")
            -- Check if we have a queue for this sender id
            if not network_queue[sender_id] then
                print(string.format("Added signature for Id %03d", sender_id))
                network_queue[sender_id] = {}
            end
            -- Append the message to the queue
            table.insert(network_queue[sender_id])
        end
    until (os.epoch("local") - start_time) / 1000 >= timeout

    return nil

end

return {
    protocol=protocol,
    find_host = find_host,
    start_host = start_host,
    wait_for_partners = wait_for_partners, 
    find_partners = find_partners,
    send_message=send_message,
    receive_message=receive_message
}




