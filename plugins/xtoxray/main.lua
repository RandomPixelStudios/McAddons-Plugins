-- X To Xray by Random Pixel Studios – plugin edition.
-- Uses MC Addons' built-in block hiding (the same chunk-mesh technique as the mod).

if mc.side == "server" then
  -- Serverside: having X To Xray on the server allows players to use it here.
  mc.on("player_join", function(e) mc.blockhiding.allow(e.player, true) end)
  return
end

---------------------------------------------------------------- client
local DEFAULT_WHITELIST = {
  "minecraft:coal_ore", "minecraft:deepslate_coal_ore", "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
  "minecraft:copper_ore", "minecraft:deepslate_copper_ore", "minecraft:gold_ore", "minecraft:deepslate_gold_ore",
  "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore", "minecraft:emerald_ore", "minecraft:deepslate_emerald_ore",
  "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore", "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore",
  "minecraft:nether_gold_ore", "minecraft:nether_quartz_ore", "minecraft:ancient_debris",
  "minecraft:chest", "minecraft:trapped_chest", "minecraft:spawner", "minecraft:water", "minecraft:lava",
}

local function copy(t) local r = {} for i, v in ipairs(t) do r[i] = v end return r end
local function defaults()
  return { render_distance = 64, render_while_moving = true, night_vision = true, show_promotions = true,
           whitelist = copy(DEFAULT_WHITELIST) }
end

local cfg = mc.storage.get("config") or defaults()
for k, v in pairs(defaults()) do if cfg[k] == nil then cfg[k] = v end end

local function apply()
  mc.storage.set("config", cfg)
  mc.blockhiding.configure {
    mode = "xray", blocks = cfg.whitelist, range = cfg.render_distance * 16,
    night_vision = cfg.night_vision, while_moving = cfg.render_while_moving,
  }
end
apply()

local function toggle()
  if not mc.blockhiding.active() and not mc.blockhiding.allowed() then
    mc.tell("", "§cThe X To Xray Serverside Is Not Installed!")
    return
  end
  mc.blockhiding.set_active(not mc.blockhiding.active())
end

mc.key("Toggle Xray", "x", toggle)

mc.on("world_load", function()
  if cfg.show_promotions then
    mc.tell("", "Support X To Xray By Subscribing On Youtube! §c[YouTube] §7youtube.com/@RandomPixelStudios")
  end
end)

---------------------------------------------------------------- config screen (same layout as the mod)
local NAV_W, CX, SLOT = 120, 150, 20
local open_config

local function add_block(text)
  text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then return end
  if not text:find(":") then text = "minecraft:" .. text end
  for _, id in ipairs(cfg.whitelist) do if id == text then return end end
  cfg.whitelist[#cfg.whitelist + 1] = text
  apply()
end

open_config = function()
  local width = mc.hud.width()
  local cw = math.max(120, width - CX - 10)
  local w = {
    { type = "button", x = 10, y = 24, w = NAV_W, label = "Xray", enabled = false },
    { type = "button", x = -70, y = 6, w = 60, label = "Done", on_click = function() apply(); mc.gui.close() end },

    { type = "slider", x = CX, y = 30, w = math.min(200, cw), label = "Render Distance", min = 1, max = 64,
      value = cfg.render_distance, on_change = function(e) cfg.render_distance = e.value end },
    { type = "checkbox", x = CX, y = 60, label = "Render While Moving", checked = cfg.render_while_moving,
      on_change = function(e) cfg.render_while_moving = e.value end },
    { type = "checkbox", x = CX, y = 85, label = "Night Vision", checked = cfg.night_vision,
      on_change = function(e) cfg.night_vision = e.value end },
    { type = "checkbox", x = CX, y = 110, label = "Show YouTube Messages", checked = cfg.show_promotions,
      on_change = function(e) cfg.show_promotions = e.value end },

    { type = "label", x = CX, y = 145, text = "Whitelist", color = 0xFFAAAAAA },
    { type = "input", id = "block", x = CX, y = 163, w = math.max(60, cw - 52), hint = "minecraft:diamond_block" },
    { type = "button", x = CX + math.max(60, cw - 52) + 5, y = 163, w = 47, label = "Add",
      on_click = function(e) add_block(e.inputs.block); open_config() end },
  }
  local cols = math.max(1, math.floor(cw / SLOT))
  local gridY = 189
  for i, id in ipairs(cfg.whitelist) do
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    w[#w + 1] = { type = "slot", x = CX + col * SLOT, y = gridY + row * SLOT, item = id,
      on_click = function() table.remove(cfg.whitelist, i); apply(); open_config() end }
  end
  local resetY = gridY + 15 + math.ceil(#cfg.whitelist / cols) * SLOT + 10
  w[#w + 1] = { type = "button", x = CX, y = resetY, w = math.min(200, cw), label = "Reset to Default",
    on_click = function()
      local keep = cfg.show_promotions
      cfg = defaults(); cfg.show_promotions = keep
      apply(); open_config()
    end }
  mc.gui.open { title = "X to Xray Config", fullscreen = true, show_title = false, widgets = w, on_close = apply }
end

mc.gui.menu_button("X To Xray Config", open_config)
