--bind client tunnel interface
vRPrm = {}
Tunnel.bindInterface("vRP_rainy_mission", vRPrm)

-- generate and return random vehicle number plate text
function vRPrm.GenerateRandomVehicleNumberPlateText()
  local plate = ""
  local charset = {}
  -- 1234567890QWERTYUIOPASDFGHJKLZXCVBNM
  for i = 48,  57 do table.insert(charset, string.char(i)) end
  for i = 65, 90 do table.insert(charset, string.char(i)) end
  local length = 8
  for i = 1, length do 
    plate = plate .. charset[math.random(1, #charset)]
  end
  return plate
end

-- spawn vehicle with random number plate
-- (param: hash - vehicle hash, pos - position)
-- return number plate text of spawned vehicle
function vRPrm.SpawnVehicle(hash, pos)
    -- load model
    local plate = ""
    local i = 0
    while not HasModelLoaded(hash) and i < 10000 do
        RequestModel(hash)
        Citizen.Wait(10)
        i = i + 1
    end    
    if HasModelLoaded(hash) then
      -- spawn vehicle
        local x, y, z = table.unpack(pos)
        local nveh = CreateVehicle(hash, x, y, z + 0.5, 0.0, true, false)
        SetVehicleOnGroundProperly(nveh)
        SetEntityInvincible(nveh, false)
        plate = vRPrm.GenerateRandomVehicleNumberPlateText()
        SetVehicleNumberPlateText(nveh, plate)
        Citizen.InvokeNative(0xAD738C3085FE7E11, nveh, true, true) -- set as mission entity
        SetVehicleHasBeenOwnedByPlayer(nveh, true)
        SetModelAsNoLongerNeeded(hash)
    end
    return plate
end

-- return true if player in vehice with number plate
function vRPrm.IsInVehicleWithPlate(plate)
  local player_ped = GetPlayerPed(-1)
  if IsPedInAnyVehicle(player_ped) then
    local v = GetVehiclePedIsIn(player_ped,false)
    local p = GetVehicleNumberPlateText(v)
    return p == plate
  end
  return false
end

-- return vehicle number plate text if player is in
function vRPrm.GetVehiclePedIsInNumberPlateText()
  local plate = ""
  local player_ped = GetPlayerPed(-1)
  if IsPedInAnyVehicle(player_ped) then
    local v = GetVehiclePedIsIn(player_ped,false)
    plate = GetVehicleNumberPlateText(v)
  end
  return plate
end  

-- delete vehicle if player is in
function vRPrm.DeleteVehiclePedIsIn()
  local player_ped = GetPlayerPed(-1)
  if IsPedInAnyVehicle(player_ped) then
    local v = GetVehiclePedIsIn(player_ped,false)
    SetVehicleHasBeenOwnedByPlayer(v,false)
    Citizen.InvokeNative(0xAD738C3085FE7E11, v, false, true) -- set not as mission entity
    SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(v))
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(v))
  end
end