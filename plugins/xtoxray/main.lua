-- X To Xray (plugin edition) by Random Pixel Studios.
-- Original mod: hides every non-whitelisted block in the chunk mesh (needs a mixin).
-- Plugin edition: scans the area around you and highlights whitelisted blocks through walls.
-- Same rule as the original: singleplayer, or servers that run this plugin too.

if mc.side == "server" then
  -- Server half: tells clients that X-ray is allowed here.
  mc.on("message", function(e)
    if e.channel == "hello" and e.player then mc.net.send("allowed", { version = mc.plugin.version }, e.player) end
  end)
  return
end

---------------------------------------------------------------- client half
local DEFAULTS = require("blocks")
local cfg = mc.storage.get("config") or {}
cfg.radius = cfg.radius or 16
if cfg.promotions == nil then cfg.promotions = true end
cfg.blocks = cfg.blocks or {}
for _, b in ipairs(DEFAULTS) do
  if cfg.blocks[b.id] == nil then cfg.blocks[b.id] = { on = b.on, color = b.color } end
end
local function save() mc.storage.set("config", cfg) end

local active, serverAllows = false, false
local found, scanning = {}, {}       -- finished scan / scan in progress
local origin, layer = nil, 0
local LAYERS_PER_TICK = 2
local MAX_BOXES = 900

local function allowed() return mc.singleplayer() or serverAllows end

local function startScan()
  local p = mc.players()[1]
  if not p then return end
  origin = { x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z) }
  layer, scanning = -cfg.radius, {}
end

local function toggle()
  if not active and not allowed() then
    mc.tell("", "§cThe X To Xray Serverside Is Not Installed!")
    return
  end
  active = not active
  found = {}
  if active then startScan() end
  mc.actionbar("", active and "§aX-Ray ON" or "§cX-Ray OFF")
end

-- incremental scan: a few horizontal layers per tick, so the game never stutters
mc.on("tick", function()
  if not active or not origin then return end
  if not allowed() then active = false; found = {}; return end
  local r = cfg.radius
  for _ = 1, LAYERS_PER_TICK do
    local y = origin.y + layer
    for x = origin.x - r, origin.x + r do
      for z = origin.z - r, origin.z + r do
        local id = mc.world.get_block("", x, y, z)
        local b = cfg.blocks[id]
        if b and b.on and #scanning < MAX_BOXES then scanning[#scanning + 1] = { x, y, z, b.color } end
      end
    end
    layer = layer + 1
    if layer > r then
      found = scanning
      startScan()   -- start the next sweep around the new position
      return
    end
  end
end)

mc.on("render", function()
  if not active then return end
  for _, f in ipairs(found) do
    local x, y, z, c = f[1], f[2], f[3], f[4]
    mc.render.box(x, y, z, x + 1, y + 1, z + 1, c, (c % 0x1000000) + 0x40000000, true)
  end
end)

mc.on("hud", function(s)
  if not active then return end
  mc.hud.text(s.width / 2 - 40, 4, "§aX-Ray§r  " .. #found .. " blocks", 0xFFFFFFFF)
end)

mc.on("world_load", function()
  serverAllows, active, found = false, false, {}
  if not mc.singleplayer() then pcall(mc.net.send, "hello", {}) end
  if cfg.promotions then
    mc.tell("", "Support X To Xray By Subscribing On Youtube! §c[youtube.com/@RandomPixelStudios]")
  end
end)

mc.on("message", function(e) if e.channel == "allowed" then serverAllows = true end end)

---------------------------------------------------------------- settings screen
local page = 0
local function settings()
  local ids = {}
  for id in pairs(cfg.blocks) do ids[#ids + 1] = id end
  table.sort(ids)
  local perPage = 8
  local pages = math.ceil(#ids / perPage)
  page = math.max(0, math.min(page, pages - 1))
  local w = {
    { type = "label", x = 0, y = 2, text = "Range: " .. cfg.radius .. " blocks" },
    { type = "button", x = 120, y = -3, w = 20, h = 18, label = "-", on_click = function() cfg.radius = math.max(4, cfg.radius - 4); save(); settings() end },
    { type = "button", x = 144, y = -3, w = 20, h = 18, label = "+", on_click = function() cfg.radius = math.min(32, cfg.radius + 4); save(); settings() end },
    { type = "button", x = 170, y = -3, w = 90, h = 18, label = "YT hints: " .. (cfg.promotions and "on" or "off"),
      on_click = function() cfg.promotions = not cfg.promotions; save(); settings() end },
  }
  for i = 1, perPage do
    local id = ids[page * perPage + i]
    if not id then break end
    local b, y = cfg.blocks[id], 20 + (i - 1) * 20
    w[#w + 1] = { type = "rect", x = 0, y = y + 3, w = 10, h = 10, color = b.color }
    w[#w + 1] = { type = "item", x = 14, y = y - 1, item = id }
    w[#w + 1] = { type = "label", x = 34, y = y + 4, text = id:gsub("minecraft:", "") }
    w[#w + 1] = { type = "button", x = 200, y = y, w = 60, h = 16, label = b.on and "§aShown" or "§7Hidden",
      on_click = function() b.on = not b.on; save(); found = {}; settings() end }
  end
  local by = 20 + perPage * 20 + 4
  w[#w + 1] = { type = "button", x = 0, y = by, w = 40, h = 18, label = "<", on_click = function() page = page - 1; settings() end }
  w[#w + 1] = { type = "label", x = 50, y = by + 5, text = "Page " .. (page + 1) .. "/" .. pages }
  w[#w + 1] = { type = "button", x = 110, y = by, w = 40, h = 18, label = ">", on_click = function() page = page + 1; settings() end }
  w[#w + 1] = { type = "button", x = 180, y = by, w = 80, h = 18, label = "Reset", on_click = function()
      cfg = { radius = 16, promotions = true, blocks = {} }
      for _, d in ipairs(DEFAULTS) do cfg.blocks[d.id] = { on = d.on, color = d.color } end
      save(); settings() end }
  mc.gui.open { title = "X To Xray Settings", width = 260, height = by + 22, widgets = w }
end

mc.key("Toggle X-Ray boxes", "v", toggle)
mc.key("X-Ray settings", "j", settings)
