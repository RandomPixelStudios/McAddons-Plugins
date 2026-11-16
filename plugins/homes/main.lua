-- Homes: commands + persistent storage.
local function key(player) return "homes." .. player end

mc.command("sethome", function(ctx)
  if not ctx.is_player then return "Only players can set homes" end
  local p = mc.player(ctx.sender)
  local name = ctx.args[1] or "home"
  local homes = mc.storage.get(key(ctx.sender)) or {}
  homes[name] = { x = p.x, y = p.y, z = p.z, dim = p.dimension }
  mc.storage.set(key(ctx.sender), homes)
  return "§aHome '" .. name .. "' set."
end)

mc.command("home", function(ctx)
  local name = ctx.args[1] or "home"
  local h = (mc.storage.get(key(ctx.sender)) or {})[name]
  if not h then return "§cNo home called '" .. name .. "'. Use /sethome " .. name end
  mc.teleport(ctx.sender, h.x, h.y, h.z)
  return "§aWelcome home."
end)

mc.command("homes", function(ctx)
  local list = {}
  for n in pairs(mc.storage.get(key(ctx.sender)) or {}) do list[#list + 1] = n end
  table.sort(list)
  return #list == 0 and "No homes yet." or "Homes: " .. table.concat(list, ", ")
end)
