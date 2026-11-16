-- Vein Miner: shows world access + item giving.
local drops = {
  ["minecraft:coal_ore"] = "minecraft:coal", ["minecraft:deepslate_coal_ore"] = "minecraft:coal",
  ["minecraft:iron_ore"] = "minecraft:raw_iron", ["minecraft:deepslate_iron_ore"] = "minecraft:raw_iron",
  ["minecraft:copper_ore"] = "minecraft:raw_copper", ["minecraft:deepslate_copper_ore"] = "minecraft:raw_copper",
  ["minecraft:gold_ore"] = "minecraft:raw_gold", ["minecraft:deepslate_gold_ore"] = "minecraft:raw_gold",
  ["minecraft:diamond_ore"] = "minecraft:diamond", ["minecraft:deepslate_diamond_ore"] = "minecraft:diamond",
  ["minecraft:emerald_ore"] = "minecraft:emerald", ["minecraft:deepslate_emerald_ore"] = "minecraft:emerald",
  ["minecraft:redstone_ore"] = "minecraft:redstone", ["minecraft:lapis_ore"] = "minecraft:lapis_lazuli",
}
local MAX = 32

mc.on("block_break", function(e)
  local drop = drops[e.block]
  if not drop then return end
  local p = mc.player(e.player)
  if not p or p.gamemode == "creative" then return end
  -- flood fill on the next tick so the original block is already gone
  mc.after(1, function()
    local seen, queue, mined = {}, { { e.x, e.y, e.z } }, 0
    while #queue > 0 and mined < MAX do
      local c = table.remove(queue)
      for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
        local x, y, z = c[1] + dx, c[2] + dy, c[3] + dz
        local k = x .. "," .. y .. "," .. z
        if not seen[k] then
          seen[k] = true
          if mined < MAX and mc.world.get_block(e.dimension, x, y, z) == e.block then
            mc.world.set_block(e.dimension, x, y, z, "minecraft:air")
            mined = mined + 1
            queue[#queue + 1] = { x, y, z }
          end
        end
      end end end
    end
    if mined > 0 then
      mc.give(e.player, drop, mined)
      mc.world.sound(e.dimension, "minecraft:block.amethyst_block.chime", e.x, e.y, e.z, 1, 1.2)
    end
  end)
end)
