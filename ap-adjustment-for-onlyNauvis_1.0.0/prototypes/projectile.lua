data:extend({
  {
    type = "projectile",
    name = "tungsten-cannon-projectile",
    flags = {"not-on-map"},
    hidden = true,
    collision_box = {{-0.3, -1.1}, {0.3, 1.1}},
    acceleration = 0,
    direction_only = true,
    piercing_damage = 1600,
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "damage",
            damage = {amount = 1600 , type = "physical"}
          },
          {
            type = "damage",
            damage = {amount = 150 , type = "explosion"}
          },
          {
            type = "create-entity",
            entity_name = "explosion"
          }
        }
      }
    },
    final_action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
          {
            type = "create-entity",
            entity_name = "small-scorchmark-tintable",
            check_buildability = true
          }
        }
      }
    },
    animation =
    {
      filename = "__base__/graphics/entity/bullet/bullet.png",
      draw_as_glow = true,
      width = 3,
      height = 50,
      priority = "high"
    }
  }
})