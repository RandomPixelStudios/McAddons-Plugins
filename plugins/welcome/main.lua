-- Welcome: a minimal server plugin.
mc.on("player_join", function(e)
  local p = mc.player(e.player)
  mc.broadcast("§e" .. e.player .. " joined the game. Welcome!")
  if p then
    mc.world.sound(p.dimension, "minecraft:entity.player.levelup", p.x, p.y, p.z, 1, 1)
    mc.world.particle(p.dimension, "minecraft:happy_villager", p.x, p.y + 1, p.z, 30)
  end
end)

mc.command("hello", function(ctx)
  return "Hello " .. ctx.sender .. "! " .. #mc.players() .. " player(s) online."
end)
