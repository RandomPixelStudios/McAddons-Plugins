-- Spawn Guard: cancellable events (return false to cancel).
local RADIUS = 16

local function protected(e)
  if e.dimension ~= "minecraft:overworld" then return false end
  if math.abs(e.x) > RADIUS or math.abs(e.z) > RADIUS then return false end
  local p = mc.player(e.player)
  return not (p and p.op)
end

mc.on("block_break", function(e)
  if protected(e) then
    mc.actionbar(e.player, "§cSpawn is protected")
    return false
  end
end)

mc.on("block_use", function(e)
  if protected(e) and e.item ~= "minecraft:air" then return false end
end)
