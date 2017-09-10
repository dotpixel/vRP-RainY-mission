local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local Lang = module("vrp", "lib/Lang")
local cfg = module("vrp_rainy_mission", "cfg/missions")

local glang = Lang.new(module("vrp", "cfg/lang/" .. cfg.lang) or {})
local lang = Lang.new(module("vrp_rainy_mission", "cfg/lang/" .. cfg.lang) or {})

-- VRP
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vRP_rainy_mission")

-- RESOURCE
vRPRMclient = Tunnel.getInterface("vRP_rainy_mission", "vRP_rainy_mission")
local clientFuncProcessing = false

function task_mission()
    
    -- EMERGENCY: DELIVERY MISSIONS
    for k, v in pairs(cfg.emergency_delivery) do -- each emergency perm def
        -- add missions to users
        local users = vRP.getUsersByPermission({k})
        --local users = vRP.getUsersByGroup({"police"}) -- TEST
        for l, w in pairs(users) do
            local user_id = w
            local player = vRP.getUserSource({user_id})
            if not vRP.hasMission({player}) then
                if math.random(1, v.chance + 1) == 1 then -- chance check
                    -- build mission
                    local mdata = {}
                    mdata.name = lang.delivery.title()

                    -- generate items
                    local todo = 0
                    local delivery_items = {}
                    for idname, data in pairs(v.items) do
                        local amount = math.random(data[1], data[2] + 1)
                        if amount > 0 then
                            delivery_items[idname] = amount
                            todo = todo + 1
                        end
                    end

                    local step = {
                        text = "",
                        onenter = function(player, area)
                            for idname, amount in pairs(delivery_items) do
                                if amount > 0 then -- check if not done
                                    if vRP.tryGetInventoryItem({user_id, idname, amount, true}) then
                                        local reward = v.items[idname][3] * amount
                                        vRP.giveMoney({user_id, reward})
                                        vRPclient.notify(player, {glang.money.received({reward})})
                                        todo = todo - 1
                                        delivery_items[idname] = 0
                                        if todo == 0 then -- all received, finish mission
                                            vRP.nextMissionStep({player})
                                        end
                                    end
                                else
                                    vRPclient.notify(player, {"~r~Something is missing!"})
                                end
                            end
                        end,
                        position = v.positions[math.random(1, #v.positions + 1)]
                    }

                    -- mission display
                    for idname, amount in pairs(delivery_items) do
                        local name = vRP.getItemName({idname})
                        step.text = step.text .. lang.delivery.item({name, amount}) .. "<br />"
                    end

                    mdata.steps = {step}

                    if todo > 0 then
                        vRP.startMission({player, mdata})
                    end
                end
            end
        end
    end

    -- POLICE: VEHICLE PARK MISSIONS
    for k, v in pairs(cfg.police_park) do -- each police perm def
        -- add missions to users
        --local users = vRP.getUsersByPermission({k})
        local users = vRP.getUsersByGroup({"police"}) -- TEST
        for l, w in pairs(users) do
            local user_id = w
            local player = vRP.getUserSource({user_id})
            if not vRP.hasMission({player}) then
                if math.random(1, v.chance + 1) == 1 then -- chance check
                    -- build mission
                    local mdata = {}
                    mdata.name = lang.park_title()

                    -- prepare vehicle spawn info
                    local park_pos = v.park_pos
                    local vehicle_hash = v.vehicles[math.random(1, #v.vehicles)]
                    local vehicle_pos = {}
                    local vehicle_plate = ""

                    local function BuildSteps()
                        mdata.steps = {}
                        -- two hardcoded steps:
                        local stepOne = {
                            -- get vehicle
                            text = lang.park_text1(),
                            onenter = function(player, area)
                                vRPclient.notify(player, {lang.getin()})
                            end,
                            onleave = function(player, area)
                                vRPRMclient.IsInVehicleWithPlate(
                                    player,
                                    {vehicle_plate},
                                    function(r)
                                        if r then
                                            vRPclient.notify(player, {lang.parkit()})
                                            vRP.nextMissionStep({player})
                                        end
                                    end
                                )
                            end,
                            position = vehicle_pos
                        }
                        table.insert(mdata.steps, stepOne)
                        local stepTwo = {
                            -- park vehicle
                            text = lang.park_text2(),
                            onenter = function(player, area)
                                vRPRMclient.IsInVehicleWithPlate(
                                    player,
                                    {vehicle_plate},
                                    function(r)
                                        if r then
                                            vRP.nextMissionStep({player})
                                            vRP.giveMoney({user_id, v.reward})
                                            vRPRMclient.DeleteVehiclePedIsIn(player, {})
                                            vRPclient.notify(player, {lang.parked() .. " " .. lang.reward({v.reward})})
                                        else
                                            vRPclient.notify(player, {lang.nothat()})
                                        end
                                    end
                                )
                            end,
                            position = park_pos
                        }
                        table.insert(mdata.steps, stepTwo)
                    end

                    local function StartMission()
                        -- finaly start mission
                        vRP.startMission({player, mdata})
                    end

                    local function ContinueBuildMission()
                        -- spawn vehicle, build steps and start mission
                        vRPRMclient.SpawnVehicle(
                            player,
                            {vehicle_hash, vehicle_pos},
                            function(r)
                                vehicle_plate = r
                                BuildSteps()
                                StartMission()
                            end
                        ) -- spawn vehicle
                    end

                    local function CheckPosition()
                        -- check position and continue build mission if it's free
                        local check_pos = v.positions[math.random(1, #v.positions)]
                        clientFuncProcessing = true
                        vRPRMclient.HaveVehicleAtPos(
                            player,
                            {check_pos, 3},
                            function(r)
                                clientFuncProcessing = false
                                if not r then
                                    -- free pos found continue build mission
                                    vehicle_pos = check_pos
                                    ContinueBuildMission()
                                end
                            end
                        ) -- check position
                    end

                    if not clientFuncProcessing then
                        CheckPosition()
                    end
                end
            end
        end
    end

    SetTimeout(10000, task_mission)
end

SetTimeout(60000, task_mission)
