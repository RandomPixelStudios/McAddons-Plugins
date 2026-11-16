-- Waypoints: client-side rendering + GUI.
local points = mc.storage.get("points") or {}
local colors = { 0xFF55FFFF, 0xFFFF5555, 0xFF55FF55, 0xFFFFFF55, 0xFFFF55FF }

local function save() mc.storage.set("points", points) end

local function add(name)
  local p = mc.players()[1]
  if not p then return end
  points[#points + 1] = { name = name, x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z), dim = p.dimension,
                          color = colors[(#points % #colors) + 1] }
  save()
  mc.toast("Waypoint saved", name)
end

local function manager()
  local widgets = {
    { type = "label", x = 0, y = 0, text = "Name:" },
    { type = "input", id = "name", x = 40, y = -4, w = 120, hint = "Waypoint " .. (#points + 1) },
    { type = "button", x = 166, y = -5, w = 54, h = 18, label = "Add", on_click = function(e)
        add(e.inputs.name ~= "" and e.inputs.name or ("Waypoint " .. (#points + 1))); manager() end },
  }
  for i, wp in ipairs(points) do
    local y = 20 + (i - 1) * 20
    if y > 150 then break end
    widgets[#widgets + 1] = { type = "rect", x = 0, y = y + 2, w = 8, h = 8, color = wp.color }
    widgets[#widgets + 1] = { type = "label", x = 14, y = y + 2, text = string.format("%s  §7%d %d %d", wp.name, wp.x, wp.y, wp.z) }
    widgets[#widgets + 1] = { type = "button", x = 166, y = y - 2, w = 54, h = 16, label = "Delete",
      on_click = function() table.remove(points, i); save(); manager() end }
  end
  mc.gui.open { title = "Waypoints", width = 220, height = 170, widgets = widgets }
end

mc.key("Save waypoint", "b", function() add("Waypoint " .. (#points + 1)) end)
mc.key("Manage waypoints", "n", manager)

mc.on("render", function()
  local p = mc.players()[1]
  if not p then return end
  for _, wp in ipairs(points) do
    if wp.dim == p.dimension then
      mc.render.box(wp.x, wp.y, wp.z, wp.x + 1, wp.y + 2, wp.z + 1, wp.color, (wp.color % 0x1000000) + 0x30000000)
      local dist = math.floor(math.sqrt((p.x - wp.x) ^ 2 + (p.y - wp.y) ^ 2 + (p.z - wp.z) ^ 2))
      mc.render.text(wp.name .. " (" .. dist .. "m)", wp.x + 0.5, wp.y + 2.6, wp.z + 0.5, wp.color, 0.6)
    end
  end
end)
