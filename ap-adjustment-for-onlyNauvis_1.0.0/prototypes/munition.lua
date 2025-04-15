local item_sounds = require("__base__.prototypes.item_sounds")

data:extend({
  {
    type = "ammo",
    name = "tungsten-rounds-magazine",
    icon = "__ap-adjustment-for-onlyNauvis__/graphics/tungsten-rounds-magazine.png",
    ammo_category = "bullet",
    ammo_type =
    {
      action =
      {
        type = "direct",
        action_delivery =
        {
          type = "instant",
          source_effects =
          {
            type = "create-explosion",
            entity_name = "explosion-gunshot"
          },
          target_effects =
          {
            {
              type = "create-entity",
              entity_name = "explosion-hit",
              offsets = {{0, 1}},
              offset_deviation = {{-0.5, -0.5}, {0.5, 0.5}}
            },
            {
              type = "damage",
              damage = {amount = 16, type = "physical"}
            },
            {
              type = "activate-impact",
              deliver_category = "bullet"
            }
          }
        }
      }
    },
    magazine_size = 10,
    subgroup = "ammo",
    order = "a[basic-clips]-c[tungsten-rounds-magazine]",
    inventory_move_sound = item_sounds.ammo_small_inventory_move,
    pick_sound = item_sounds.ammo_small_inventory_pickup,
    drop_sound = item_sounds.ammo_small_inventory_move,
    stack_size = 100,
    weight = 40*kg
  },
  {
    type = "ammo",
    name = "tungsten-cannon-shell",
    icon = "__ap-adjustment-for-onlyNauvis__/graphics/tungsten-cannon-shell.png",
    ammo_category = "cannon-shell",
    ammo_type =
    {
      target_type = "direction",
      action =
      {
        type = "direct",
        action_delivery =
        {
          type = "projectile",
          projectile = "tungsten-cannon-projectile",
          starting_speed = 1,
          direction_deviation = 0.1,
          range_deviation = 0.1,
          max_range = 30,
          min_range = 5,
          source_effects =
          {
            type = "create-explosion",
            entity_name = "explosion-gunshot"
          }
        }
      }
    },
    subgroup = "ammo",
    order = "d[cannon-shell]-c[tungsten]",
    inventory_move_sound = item_sounds.ammo_large_inventory_move,
    pick_sound = item_sounds.ammo_large_inventory_pickup,
    drop_sound = item_sounds.ammo_large_inventory_move,
    stack_size = 100,
    weight = 40*kg
  }
})