local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local Lang = module("vrp", "lib/Lang")
local cfg = module("vrp_rainy_mission", "cfg/missions")
local lang = Lang.new(module("vrp_rainy_mission", "cfg/lang/"..cfg.lang) or {})

-- VRP
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vRP_rainy_mission")

-- RESOURCE
vRPRMclient = Tunnel.getInterface("vRP_rainy_mission","vRP_rainy_mission")

function task_mission()

  -- POLICE: VEHICLE PARK MISSIONS
  for k,v in pairs(cfg.police_park) do -- each police perm def
    -- add missions to users
    --local users = vRP.getUsersByPermission({k})
    local users = vRP.getUsersByGroup({"police"}) -- TEST
    for l,w in pairs(users) do
      local user_id = w
      local player = vRP.getUserSource({user_id})
      if not vRP.hasMission({player}) then
        if math.random(1,v.chance+1) == 1 then -- chance check
          -- build mission
          local mdata = {}
          mdata.name = lang.park_title()

          -- prepare vehicle spawn info
          local park_pos = v.park_pos
          local vehicle_hash = v.vehicles[math.random(1,#v.vehicles)]
          local vehicle_pos = v.positions[math.random(1,#v.positions)]
          local vehicle_plate = ""
          vRPRMclient.SpawnVehicle(player,{vehicle_hash, vehicle_pos},function(r) vehicle_plate = r end) -- spawn vehicle

          mdata.steps = {}
          -- two hardcoded steps:
          local stepOne = { -- get vehicle
            text = lang.park_text1(),
            onenter = function(player, area)
              vRPclient.notify(player,{lang.getin()})
            end,
            onleave = function(player,area)
              vRPRMclient.IsInVehicleWithPlate(player,{vehicle_plate},function(r)
                if r then
                  vRPclient.notify(player,{lang.parkit()})
                  vRP.nextMissionStep({player})
                end
              end)
            end,
            position = vehicle_pos
          }
          table.insert(mdata.steps, stepOne)
          local stepTwo = { -- park vehicle
            text = lang.park_text2(),
            onenter = function(player, area)
              vRPRMclient.IsInVehicleWithPlate(player,{vehicle_plate},function(r)
                if r then
                  vRP.nextMissionStep({player})
                  vRP.giveMoney({user_id,v.reward})
                  vRPRMclient.DeleteVehiclePedIsIn(player,{})
                  vRPclient.notify(player,{lang.parked().." "..lang.reward({v.reward})}) 
                else
                  vRPclient.notify(player,{lang.nothat()})
                end
              end)
            end,
            position = park_pos
          }
          table.insert(mdata.steps, stepTwo)

          vRP.startMission({player,mdata})
        end
      end
    end
  end

  SetTimeout(10000,task_mission)
end

SetTimeout(90000,task_mission)