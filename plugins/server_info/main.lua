-- Server Info: one plugin, two halves, talking over mc.net.
if mc.side == "server" then
  mc.every(40, function()
    local t = mc.world.time("minecraft:overworld") % 24000
    mc.net.send("info", { players = #mc.players(), time = t, day = t < 12500 })
  end)
else
  local info
  mc.on("message", function(e) if e.channel == "info" then info = e.data end end)
  mc.on("world_unload", function() info = nil end)
  mc.on("hud", function(s)
    if not info then return end
    local text = string.format("%s %02d:%02d  ·  %d online", info.day and "Day" or "Night",
      (math.floor(info.time / 1000) + 6) % 24, math.floor(info.time % 1000 * 0.06), info.players)
    local w = 4 + #text * 6
    mc.hud.rect(s.width - w - 4, 4, w, 14, 0x90000000)
    mc.hud.text(s.width - w, 7, text, 0xFFFFE080)
  end)
end
