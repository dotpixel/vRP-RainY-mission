
local cfg = {}

cfg.lang = "ru"

local emergency_delivery_positions = {
	{-247.67460632324,6331.2080078125,32.426181793213},
	{-454.43786621094,-340.32211303711,34.363452911377},
	{364.54992675781,-590.83502197266,28.68789100647},
	{342.11251831055,-1397.3562011719,32.509250640869},
	{1827.8341064453,3693.9587402344,34.224235534668},
	{-654.86608886719,311.2966003418,83.007888793945},
	{1152.3073730469,-1527.3486328125,34.843418121338},
	{-874.52612304688,-307.91549682617,39.568534851074}
}

-- EMERGENCY: DELIVERY MISSIONS
cfg.emergency_delivery = {
  ["mission.emergency.delivery.pils"] = {
    positions = emergency_delivery_positions,
    chance = 10,
    items = {
      ["pizza"] = {1,20,150},
      ["gocagola"] = {0,20,100}
    }
  },
  ["mission.emergency.delivery.organs"] = {
    positions = emergency_delivery_positions,
    chance = 20,
    items = {
      ["pizza"] = {1,20,150},
      ["gocagola"] = {0,20,100}
    }
  }
}

-- POLICE: VEHICLE PARK MISSIONS
cfg.police_park = {
  ["mission.police.park.city"] = {
    chance = 2,
    park_pos = {1886.2406005859,3680.3232421875,33.399444580078},
    vehicles = {1039032026, 841808271},
    positions = { {1932.0750732422,3709.0661621094,32.471206665039} },
    reward = 1000
  }
}

return cfg