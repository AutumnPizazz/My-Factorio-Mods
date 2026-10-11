-- Space Platform Thrust Physics 0.1.1
-- Replaces utility-constants.default.space_platform_acceleration_expression.
--
-- Physics model:
--     acceleration = (thrust - drag) / weight / 60
--     drag         = K * speed * |speed|^(n-1) * sign(speed) * size_factor
--                    n = 1 (linear) or 2 (quadratic)
--     size_factor  = (width / ref_width)   ^ width_exponent
--                  * (height / ref_height) ^ height_exponent
--                  * (weight / ref_weight) ^ weight_exponent
--
-- Mass therefore only affects how quickly the platform accelerates; the top speed
-- is decided by the total thrust and the drag coefficient alone.
--
-- Engine expression units (confirmed empirically for 2.1.x):
--     speed  : km/s
--     thrust : N
--     weight : kg
-- Engine expression variables available: speed, thrust, weight, width, height.
-- The engine also provides abs(), log2(), sign(), min() and max().

local drag_model    = settings.startup["sptp-drag-model"].value
local ref_thrust_gn = settings.startup["sptp-reference-thrust-gn"].value
local ref_top_speed = settings.startup["sptp-reference-top-speed"].value
local drag_strength = settings.startup["sptp-drag-strength"].value
local ref_width     = settings.startup["sptp-reference-width"].value
local width_exp     = settings.startup["sptp-width-exponent"].value
local ref_height    = settings.startup["sptp-reference-height"].value
local height_exp    = settings.startup["sptp-height-exponent"].value
local ref_weight_t  = settings.startup["sptp-reference-weight-tons"].value
local weight_exp    = settings.startup["sptp-weight-exponent"].value
local keep_penalty  = settings.startup["sptp-keep-heavy-mass-penalty"].value
local speed_cap     = settings.startup["sptp-speed-cap"].value
local custom_expr   = settings.startup["sptp-custom-expression"].value

-- The engine expression parser only accepts scientific notation without a '+'
-- exponent ("1.5e-7", "1.5e7"), while Lua would emit "1.5e+07". Strip the '+'.
local function num(x)
  local s = string.format("%.10g", x)
  s = s:gsub("e%+", "e")
  return s
end

-- One (variable / reference) ^ exponent factor; nil when the exponent is 0
-- (factor 1, so the term is left out of the expression entirely).
-- A negative exponent is emitted as "1 / (base ^ |exp|)" on purpose: the engine's
-- expression tokenizer has no unary minus, so "base ^ -1" would not parse.
local function factor(var, ref, exp)
  if exp == 0 then return nil end
  local base = string.format("(%s / %s)", var, num(ref))
  if exp == 1 then return base end
  if exp < 0 then return string.format("(1 / (%s ^ %s))", base, num(-exp)) end
  return string.format("%s ^ %s", base, num(exp))
end

local expr

if custom_expr ~= nil and custom_expr ~= "" then
  -- Power-user escape hatch: use the expression exactly as typed.
  expr = custom_expr
else
  local ref_thrust = ref_thrust_gn * 1e9

  -- K is picked so that a platform whose total thrust equals ref_thrust reaches
  -- exactly ref_top_speed (at drag strength 1.0 and size factor 1.0):
  --     linear    : K * v     = thrust  ->  v = thrust / K
  --     quadratic : K * v * v = thrust  ->  v = sqrt(thrust / K)
  local K
  if drag_model == "linear" then
    K = ref_thrust / ref_top_speed
  else
    K = ref_thrust / (ref_top_speed * ref_top_speed)
  end
  K = K * drag_strength

  local drag
  if drag_model == "linear" then
    drag = string.format("(%s * speed * sign(speed))", num(K))
  else
    drag = string.format("(%s * speed * speed * sign(speed))", num(K))
  end

  -- Size / mass factor: how much more (or less) drag this platform has compared
  -- to the reference platform. Any exponent set to 0 removes that dependency.
  -- (Built with explicit appends; a table holding nils would break ipairs.)
  local parts = {}
  local f
  f = factor("width", ref_width, width_exp)
  if f then parts[#parts + 1] = f end
  f = factor("height", ref_height, height_exp)
  if f then parts[#parts + 1] = f end
  f = factor("weight", ref_weight_t * 1000, weight_exp)
  if f then parts[#parts + 1] = f end

  if #parts > 0 then
    drag = string.format("(%s * %s)", drag, table.concat(parts, " * "))
  end

  local thrust_term = keep_penalty and "thrust / (1 + weight / 10000000)" or "thrust"

  expr = string.format("(%s - %s) / weight / 60", thrust_term, drag)

  if speed_cap > 0 then
    -- Speed cap: the acceleration factor fades linearly and hits zero exactly at
    -- the cap; past it the factor turns negative and brakes the platform back
    -- down. Only abs() is used on purpose, to avoid relying on comma-separated
    -- arguments of min()/max().
    expr = string.format("(%s) * (1 - abs(speed) / %s)", expr, num(speed_cap))
  end
end

data.raw["utility-constants"]["default"].space_platform_acceleration_expression = expr

log("[space-platform-thrust-physics] space_platform_acceleration_expression = " .. expr)
