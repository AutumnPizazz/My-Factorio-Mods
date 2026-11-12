local name = "ap-blank-rounds-magazine"

local function create_machine(surface, position)
  local machine = assert(surface.create_entity({
    name = "assembling-machine-1", position = position, force = "player"
  }))
  machine.set_recipe(name)
  return machine
end

script.on_init(function()
  if script.test_arg == "k2-standard" then
    assert(not settings.startup["kr-realistic-weapons"].value)
    assert(prototypes.item[name].magazine_size == 10)
  elseif script.test_arg == "k2-realistic" then
    assert(settings.startup["kr-realistic-weapons"].value)
    assert(prototypes.item[name].magazine_size == 30)
  elseif script.test_arg == "custom" then
    assert(settings.startup["ap-blank-ammo-damage"].value == 2.5)
    assert(settings.startup["ap-blank-ammo-crafting-time"].value == 2)
  end
  local surface = game.create_surface("blank-ammo-test", {
    width = 64, height = 64,
    autoplace_settings = {
      entity = {treat_missing_as_default = false},
      tile = {treat_missing_as_default = false},
      decorative = {treat_missing_as_default = false}
    }
  })
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -24, 24 do
    for y = -24, 24 do
      tiles[#tiles + 1] = {name = "stone-path", position = {x, y}}
    end
  end
  surface.set_tiles(tiles)
  surface.ignore_surface_conditions = false
  surface.set_property("pressure", 0)
  assert(surface.get_property("ap-blank-ammo-production") == 1)
  storage.machine = create_machine(surface, {-12, 0})

  local character = assert(surface.create_entity({
    name = "character", position = {-18, 0}, force = "player"
  }))
  assert(character.begin_crafting({recipe = name, count = 1, silent = true}) == 0)

  local recipe = prototypes.recipe[name]
  assert(#recipe.ingredients == 0 and recipe.enabled)
  assert(not recipe.allowed_effects.productivity and not recipe.allowed_effects.quality)
  assert(not prototypes.recipe[name .. "-recycling"])

  storage.turret = assert(surface.create_entity({
    name = "gun-turret", position = {0, 0}, direction = defines.direction.east, force = "player"
  }))
  assert(storage.turret.insert({name = name, count = 100}) > 0)
  storage.target = assert(surface.create_entity({
    name = "gun-turret", position = {8, 0}, force = "enemy"
  }))
  storage.stage = "baseline"
  storage.baseline_hits = 0

  if prototypes.item["space-platform-starter-pack"] then
    local platform = assert(game.forces.player.create_space_platform({
      name = "Blank ammo test", planet = "nauvis",
      starter_pack = {name = "space-platform-starter-pack", quality = "normal"}
    }))
    platform.apply_starter_pack(true)
    local platform_surface = assert(platform.surface)
    platform_surface.ignore_surface_conditions = false
    assert(platform_surface.get_property("ap-blank-ammo-production") == 0)
    storage.platform_machine = assert(platform_surface.create_entity({
      name = "assembling-machine-1", position = {0, 12}, force = "player"
    }))
    storage.platform_machine.copy_settings(storage.machine)
  end

  log("[ap-blank-ammo-tests] Scenario initialised")
end)

script.on_event(defines.events.on_entity_damaged, function(event)
  if event.entity ~= storage.target then return end
  if storage.stage == "baseline" then
    storage.baseline_damage = event.final_damage_amount
    storage.baseline_hits = storage.baseline_hits + 1
    if storage.last_baseline_hit then
      storage.baseline_interval = math.min(storage.baseline_interval or math.huge,
        event.tick - storage.last_baseline_hit)
    end
    storage.last_baseline_hit = event.tick
  elseif storage.stage == "researched" then
    assert(event.final_damage_amount > storage.baseline_damage,
      "Research did not increase actual blank ammunition damage")
    storage.researched_damage = event.final_damage_amount
    if storage.last_researched_hit then
      storage.researched_interval = math.min(storage.researched_interval or math.huge,
        event.tick - storage.last_researched_hit)
    end
    storage.last_researched_hit = event.tick
  end
end)

script.on_event(defines.events.on_tick, function(event)
  storage.machine.energy = 10000000
  if storage.target.valid then storage.target.health = storage.target.max_health end
  if storage.platform_machine then storage.platform_machine.energy = 10000000 end

  if storage.stage == "baseline" and storage.baseline_hits >= 3 then
    local force = game.forces.player
    local damage = force.get_ammo_damage_modifier("bullet")
    local speed = force.get_gun_speed_modifier("bullet")
    force.technologies["physical-projectile-damage-1"].researched = true
    force.technologies["weapon-shooting-speed-1"].researched = true
    assert(force.get_ammo_damage_modifier("bullet") > damage)
    assert(force.get_gun_speed_modifier("bullet") > speed)
    storage.stage = "settling"
    storage.research_tick = event.tick
  elseif storage.stage == "settling" and event.tick > storage.research_tick + 120 then
    storage.stage = "researched"
  end

  if event.tick >= 1800 then
    assert(storage.machine.get_output_inventory().get_item_count(name) > 0,
      "Assembler did not manufacture ingredient-free ammunition")
    assert(storage.researched_damage, "Gun turret did not demonstrate research-boosted damage")
    assert(storage.researched_interval and storage.researched_interval < storage.baseline_interval,
      "Research did not increase actual blank ammunition firing speed")
    if storage.platform_machine then
      log("[ap-blank-ammo-tests] Platform state: " .. helpers.table_to_json({
        ignore = storage.platform_machine.surface.ignore_surface_conditions,
        property = storage.platform_machine.surface.get_property("ap-blank-ammo-production"),
        count = storage.platform_machine.get_output_inventory().get_item_count(name),
        status = storage.platform_machine.status,
        recipe = storage.platform_machine.get_recipe() and storage.platform_machine.get_recipe().name
      }))
      assert(storage.platform_machine.get_output_inventory().get_item_count(name) == 0,
        "Blank ammunition was manufactured on a space platform")
    end
    log("[ap-blank-ammo-tests] PASS: machine production, no hand crafting, no platform production, "
      .. "actual turret damage " .. storage.baseline_damage .. " -> " .. storage.researched_damage
      .. ", shot interval " .. storage.baseline_interval .. " -> " .. storage.researched_interval .. " ticks")
    script.finish_test(true)
  end
end)
