local name = "ap-blank-rounds-magazine"
local tint = {r = 0.65, g = 0.85, b = 0.9, a = 1}
local ammo = table.deepcopy(data.raw.ammo["firearm-magazine"])
ammo.name = name
ammo.localised_name = nil
ammo.localised_description = {"item-description." .. name}
ammo.icon = nil
ammo.icons = {{icon = "__base__/graphics/icons/firearm-magazine.png", icon_size = 64, tint = tint}}
ammo.pictures = {{filename = "__base__/graphics/icons/firearm-magazine.png", size = 64, scale = 0.5, tint = tint}}
ammo.order = "a[basic-clips]-0[blank-rounds-magazine]"
ammo.auto_recycle = false

data:extend({
  ammo,
  {
    type = "recipe-category",
    name = "ap-blank-ammo-crafting"
  },
  {
    type = "surface-property",
    name = "ap-blank-ammo-production",
    default_value = 1
  },
  {
    type = "recipe",
    name = name,
    categories = {"ap-blank-ammo-crafting"},
    enabled = true,
    hide_from_player_crafting = true,
    always_show_made_in = true,
    energy_required = settings.startup["ap-blank-ammo-crafting-time"].value,
    ingredients = {},
    results = {{type = "item", name = name, amount = 1}},
    allow_productivity = false,
    allow_quality = false,
    can_set_quality = false,
    auto_recycle = false
  }
})
