-- Ruby: behaviour for the items declared in plugin.json.
if mc.side ~= "server" then return end

mc.on("item_use", function(e)
  if e.item ~= "ruby:ruby" then return end
  local p = mc.player(e.player)
  mc.set_health(e.player, p.health + 8)
  mc.world.particle(p.dimension, "minecraft:heart", p.x, p.y + 1.5, p.z, 6)
  mc.world.sound(p.dimension, "minecraft:entity.player.levelup", p.x, p.y, p.z, 0.6, 1.8)
end)

mc.command("ruby", function(ctx)
  if not ctx.is_player then return "players only" end
  mc.give(ctx.sender, "ruby:ruby", 4)
  mc.give(ctx.sender, "ruby:ruby_block", 1)
  return "§cHere are some rubies!"
end)
