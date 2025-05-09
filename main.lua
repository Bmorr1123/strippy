local args = {...}
---------------------------------------------------------- Argument Checking ---
function check_args(args)
    if not (#args >= 0)then
        print("Usage:"..fs.getName(shell.getRunningProgram()).."")
        return false
    end
    return true
end

-------------------------------------------------------- Peripheral Checking ---
function check_peripherals()

    if not turtle then
        printError("Requires a Turtle.")
        return
    end

    local peripheral_combinations = {
        ["miner"]={"modem", nil},
        ["scanner"]={"modem", "geoScanner"},
        ["loader"]={"modem", "chunky"}
    }

    local left, right = peripheral.getType("left"), peripheral.getType("right")
    for job, combo in pairs(peripheral_combinations) do
        if (combo[1] == left or combo[1] == right) and (combo[2] == left or combo[2] == right) then
            return job
        end
    end

    print("Could not find the proper peripherals. \nPlease give your turtles the correct peripherals for the job.")
    for job, combo in pairs(peripheral_combinations) do
        print("\t"..job..": "..tostring(combo[1]).." + "..tostring(combo[2]))
    end
end

function main()
    if not check_args(args) then
        return
    end
    local job = check_peripherals()
    print("This turtle is detected to be a "..job)
    if job == nil then
        return
    end
    sleep(3)
    if job == "miner" then
        shell.run("miner.lua")
    end

end

main()