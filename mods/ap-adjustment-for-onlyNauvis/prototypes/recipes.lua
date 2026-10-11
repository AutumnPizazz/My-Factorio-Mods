data:extend({
  {
    type = "recipe",
    name = "tungsten-rounds-magazine",
    enabled = false,
    category = "pressing",
    energy_required = 4,
    ingredients =
    {
      {type = "item", name = "tungsten-ore", amount = 1}
    },
    results = {{type="item", name="tungsten-rounds-magazine", amount=1}}
  },
  {
    type = "recipe",
    name = "tungsten-cannon-shell",
    enabled = false,
    category = "pressing",
    energy_required = 12,
    ingredients =
    {
      {type = "item", name = "cannon-shell", amount = 1},
      {type = "item", name = "tungsten-carbide", amount = 1}
    },
    results = {{type="item", name="tungsten-cannon-shell", amount=1}}
  }
})