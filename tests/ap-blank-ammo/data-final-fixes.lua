local name = "ap-blank-rounds-magazine"
local ammo = assert(data.raw.ammo[name])
local recipe = assert(data.raw.recipe[name])
local damage = settings.startup["ap-blank-ammo-damage"].value
local source = data.raw.ammo["kr-rifle-magazine"] or data.raw.ammo["firearm-magazine"]

assert(ammo.ammo_category == "bullet")
assert(ammo.magazine_size == source.magazine_size)
assert(ammo.auto_recycle == false and recipe.auto_recycle == false)
assert(not data.raw.recipe[name .. "-recycling"])
assert(next(recipe.ingredients) == nil)
assert(recipe.hide_from_player_crafting and recipe.enabled)
assert(recipe.allow_productivity == false and recipe.allow_quality == false)
assert(recipe.can_set_quality == false)
assert(recipe.energy_required == settings.startup["ap-blank-ammo-crafting-time"].value)
assert(#recipe.categories == 1 and recipe.categories[1] == "ap-blank-ammo-crafting")

for _, character in pairs(data.raw.character) do
  for _, category in ipairs(character.crafting_categories or {}) do
    assert(category ~= "ap-blank-ammo-crafting", "Blank ammunition can be hand-crafted")
  end
end

local hits = 0
local function check_damage(value)
  if type(value) ~= "table" then return end
  if value.type == "damage" then
    assert(value.damage.type == "physical" and value.damage.amount == damage)
    hits = hits + 1
  elseif value.type == "projectile" and value.projectile then
    assert(value.projectile:find("ap-blank-ammo-", 1, true) == 1)
    check_damage(assert(data.raw.projectile[value.projectile]))
  end
  for _, child in pairs(value) do check_damage(child) end
end
check_damage(ammo.ammo_type)
assert(hits > 0, "Blank ammunition has no damage effect")

for _, other_recipe in pairs(data.raw.recipe) do
  for _, ingredient in ipairs(other_recipe.ingredients or {}) do
    if ingredient.name == name then
      assert(not next(other_recipe.results or {}),
        "Blank ammunition can be converted to another product: " .. other_recipe.name)
    end
  end
end

if data.raw.surface and data.raw.surface["space-platform"] then
  assert(data.raw.surface["space-platform"].surface_properties["ap-blank-ammo-production"] == 0)
end
log("[ap-blank-ammo-tests] Data-stage assertions passed; source=" .. source.name
  .. "; magazine_size=" .. ammo.magazine_size .. "; damage=" .. damage
  .. "; crafting_time=" .. recipe.energy_required)
