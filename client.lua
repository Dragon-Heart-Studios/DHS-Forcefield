-- Forcefield Radius Options
ForcefieldRadiusOps = {5.0, 10.0, 15.0, 20.0, 50.0}
-- Default Forcefield Radius
ForcefieldRadius = 5.0
local forcefield = false


RegisterCommand("ToggleForcefield", function()
   forcefield = not forcefield
end, false)

local function ApplyForce(entity)
   local pos = GetEntityCoords(PlayerPedId())
   local coord = GetEntityCoords(entity)
   local dx = coord.x - pos.x
   local dy = coord.y - pos.y
   local dz = coord.z - pos.z
   local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
   local distanceRate = (50 / distance) * 1.04^(1 - distance)
   ApplyForceToEntity(entity, 1, distanceRate * dx, distanceRate * dy, distanceRate * dz, math.random() * math.random(-1, 1), math.random() * math.random(-1, 1), math.random() * math.random(-1, 1), true, false, true, true, true, true)
end

local function RequestControlOnce(entity)
   if not NetworkIsInSession or NetworkHasControlOfEntity(entity) then
       return true
   end
   SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
   return NetworkRequestControlOfEntity(entity)
end

local function DoForceFieldTick(radius)
   local player = PlayerPedId()
   local coords = GetEntityCoords(PlayerPedId())
   local playerVehicle = GetPlayersLastVehicle()
   local inVehicle = IsPedInVehicle(player, playerVehicle, true)
   local vehicles = GetGamePool('CVehicle')
   local peds = GetGamePool('CPed')

   DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, radius, radius, radius, 180, 80, 0, 35, false, true, 2, false, nil, false, false)

   for i=1, #vehicles do
      if (not inVehicle or vehicles[i] ~= playerVehicle) and #(coords - GetEntityCoords(vehicles[i])) <= radius * 2 then
          RequestControlOnce(vehicles[i])
          ApplyForce(vehicles[i])
      end
   end

   for i=1, #peds do
      if peds[i] ~= player and #(coords - GetEntityCoords(peds[i])) <= radius * 2 then
          RequestControlOnce(peds[i])
          SetPedRagdollOnCollision(peds[i], true)
          SetPedRagdollForceFall(peds[i])
          ApplyForce(peds[i])
      end
  end
end

CreateThread(function()
   while true do
      local s = 1000
      if forcefield then
         s = 0
         DoForceFieldTick(ForcefieldRadius)
      end
      Wait(s)
   end
end)
