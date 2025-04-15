data:extend({
  {
    type = "technology",
    name = "tungsten-ammo",
    icon = "__tungsten-munition__/graphics/tungsten-ammo.png",
    icon_size = 256,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "tungsten-rounds-magazine"
      },
      {
        type = "unlock-recipe",
        recipe = "tungsten-cannon-shell"
      }
    },
    prerequisites = {"tungsten-carbide", "military-4", "tank"},
    unit =
    {
      count = 500,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"military-science-pack", 1},
        {"space-science-pack", 1}
      },
      time = 45
    }
  }
})