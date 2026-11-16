-- Emerald Shop: a chest-menu GUI on the server.
local offers = {
  [11] = { item = "minecraft:diamond",       price = 8,  count = 1 },
  [12] = { item = "minecraft:golden_apple",  price = 4,  count = 1 },
  [13] = { item = "minecraft:ender_pearl",   price = 2,  count = 4 },
  [14] = { item = "minecraft:experience_bottle", price = 1, count = 8 },
  [15] = { item = "minecraft:elytra",        price = 64, count = 1 },
}

local function open(player)
  local items = { [5] = "minecraft:emerald" }
  for slot, o in pairs(offers) do items[slot] = o.item end
  mc.menu.open(player, {
    title = "Emerald Shop - click to buy",
    rows = 3,
    items = items,
    on_click = function(e)
      local o = offers[e.slot]
      if not o then return end
      if mc.count_item(e.player, "minecraft:emerald") < o.price then
        mc.tell(e.player, "§cYou need " .. o.price .. " emeralds.")
        return
      end
      mc.take_item(e.player, "minecraft:emerald", o.price)
      mc.give(e.player, o.item, o.count)
      mc.tell(e.player, string.format("§aBought %dx %s for %d emeralds.", o.count, (o.item:gsub("minecraft:", "")), o.price))
      local p = mc.player(e.player)
      mc.world.sound(p.dimension, "minecraft:entity.villager.yes", p.x, p.y, p.z, 1, 1)
    end,
  })
end

mc.command("shop", function(ctx)
  if not ctx.is_player then return "players only" end
  open(ctx.sender)
end)
