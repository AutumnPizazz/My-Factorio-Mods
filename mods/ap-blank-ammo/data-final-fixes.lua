local damage = settings.startup["ap-blank-ammo-damage"].value
local ammo = data.raw.ammo["ap-blank-rounds-magazine"]
local source = data.raw.ammo["kr-rifle-magazine"] or data.raw.ammo["firearm-magazine"]
assert(source.ammo_category == "bullet", "Air-Made Blank Ammo requires bullet-category ammunition")

local projectiles = {}

-- K2 stores damage in separate projectiles; never modify a shared live-round projectile.
local function adapt_effects(value)
  if type(value) ~= "table" then return end

  if value.type == "damage" then
    value.damage = {amount = damage, type = "physical"}
  elseif value.type == "projectile" and value.projectile then
    local original = value.projectile
    local name = projectiles[original]
    if not name then
      name = "ap-blank-ammo-" .. original
      projectiles[original] = name
      local projectile = table.deepcopy(data.raw.projectile[original])
      assert(projectile, "Missing blank ammo source projectile: " .. original)
      projectile.name = name
      adapt_effects(projectile)
      data:extend({projectile})
    end
    value.projectile = name
  end

  for _, child in pairs(value) do
    adapt_effects(child)
  end
end

ammo.ammo_category = "bullet"
ammo.ammo_type = table.deepcopy(source.ammo_type)
ammo.magazine_size = source.magazine_size
ammo.stack_size = source.stack_size
adapt_effects(ammo.ammo_type)

for _, machine in pairs(data.raw["assembling-machine"]) do
  if not machine.fixed_recipe then
    for _, category in ipairs(machine.crafting_categories or {}) do
      if category == "crafting" or category == "advanced-crafting"
        or category == "basic-crafting" or category == "burner-crafting" then
        table.insert(machine.crafting_categories, "ap-blank-ammo-crafting")
        break
      end
    end
  end
end

-- Only platforms are excluded, including when other mods add airless planets.
local platform = data.raw.surface and data.raw.surface["space-platform"]
if platform then
  platform.surface_properties = platform.surface_properties or {}
  platform.surface_properties["ap-blank-ammo-production"] = 0
  data.raw.recipe["ap-blank-rounds-magazine"].surface_conditions = {
    {property = "ap-blank-ammo-production", min = 1}
  }
end
