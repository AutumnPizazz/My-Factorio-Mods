data:extend({
  {
    type = "double-setting",
    name = "ap-blank-ammo-damage",
    setting_type = "startup",
    default_value = 1,
    minimum_value = 0.1,
    maximum_value = 100,
    order = "a[damage]"
  },
  {
    type = "double-setting",
    name = "ap-blank-ammo-crafting-time",
    setting_type = "startup",
    default_value = 5,
    minimum_value = 0.1,
    maximum_value = 3600,
    order = "b[crafting-time]"
  }
})
