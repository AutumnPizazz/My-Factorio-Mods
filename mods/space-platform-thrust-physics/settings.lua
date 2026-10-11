data:extend({
  {
    type = "string-setting",
    name = "sptp-drag-model",
    setting_type = "startup",
    default_value = "quadratic",
    allowed_values = { "linear", "quadratic" },
    order = "a[sptp]-a[drag-model]"
  },
  {
    type = "double-setting",
    name = "sptp-reference-thrust-gn",
    setting_type = "startup",
    default_value = 61.2,
    minimum_value = 0.001,
    maximum_value = 1000000,
    order = "a[sptp]-b[reference-thrust]"
  },
  {
    type = "double-setting",
    name = "sptp-reference-top-speed",
    setting_type = "startup",
    default_value = 1000,
    minimum_value = 1,
    maximum_value = 10000000,
    order = "a[sptp]-c[reference-top-speed]"
  },
  {
    type = "double-setting",
    name = "sptp-drag-strength",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0,
    maximum_value = 1000,
    order = "a[sptp]-d[drag-strength]"
  },
  {
    type = "double-setting",
    name = "sptp-reference-width",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 1,
    maximum_value = 10000,
    order = "a[sptp]-e[reference-width]"
  },
  {
    type = "double-setting",
    name = "sptp-width-exponent",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = -10,
    maximum_value = 10,
    order = "a[sptp]-f[width-exponent]"
  },
  {
    type = "double-setting",
    name = "sptp-reference-height",
    setting_type = "startup",
    default_value = 17,
    minimum_value = 1,
    maximum_value = 10000,
    order = "a[sptp]-g[reference-height]"
  },
  {
    type = "double-setting",
    name = "sptp-height-exponent",
    setting_type = "startup",
    default_value = 0.0,
    minimum_value = -10,
    maximum_value = 10,
    order = "a[sptp]-h[height-exponent]"
  },
  {
    type = "double-setting",
    name = "sptp-reference-weight-tons",
    setting_type = "startup",
    default_value = 1000,
    minimum_value = 0.001,
    maximum_value = 100000000,
    order = "a[sptp]-i[reference-weight]"
  },
  {
    type = "double-setting",
    name = "sptp-weight-exponent",
    setting_type = "startup",
    default_value = 0.0,
    minimum_value = -10,
    maximum_value = 10,
    order = "a[sptp]-j[weight-exponent]"
  },
  {
    type = "bool-setting",
    name = "sptp-keep-heavy-mass-penalty",
    setting_type = "startup",
    default_value = false,
    order = "a[sptp]-k[heavy-mass-penalty]"
  },
  {
    type = "double-setting",
    name = "sptp-speed-cap",
    setting_type = "startup",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 100000000,
    order = "a[sptp]-l[speed-cap]"
  },
  {
    type = "string-setting",
    name = "sptp-custom-expression",
    setting_type = "startup",
    default_value = "",
    allow_blank = true,
    order = "a[sptp]-z[custom-expression]"
  }
})
