-- Coords HUD: client-only overlay plugin.
local visible = mc.storage.get("visible")
if visible == nil then visible = true end

local dirs = { "S", "SW", "W", "NW", "N", "NE", "E", "SE" }
local function facing(yaw)
  local i = math.floor(((yaw % 360) + 22.5) / 45) % 8
  return dirs[i + 1]
end

mc.key("Toggle overlay", "h", function()
  visible = not visible
  mc.storage.set("visible", visible)
end)

mc.on("hud", function(screen)
  if not visible then return end
  local p = mc.players()[1]
  if not p then return end
  local lines = {
    string.format("XYZ  %.1f / %.1f / %.1f", p.x, p.y, p.z),
    string.format("Facing  %s (%.0f°)", facing(p.yaw), p.yaw % 360),
    "Dim  " .. p.dimension:gsub("minecraft:", ""),
  }
  mc.hud.rect(2, 2, 150, #lines * 10 + 24, 0x90000000)
  for i, line in ipairs(lines) do
    mc.hud.text(6, 6 + (i - 1) * 10, line, 0xFFFFFFFF)
  end
  if p.held_item ~= "minecraft:air" then
    mc.hud.item(6, 6 + #lines * 10, p.held_item)
    mc.hud.text(26, 10 + #lines * 10, p.held_item:gsub("minecraft:", ""), 0xFFAAAAAA)
  end
end)
