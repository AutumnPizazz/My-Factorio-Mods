data.raw.recipe["bulk-inserter"].ingredients = {
    {
        type = "item",
        name = "small-parts-01",
        amount = 2
    },
    {
        type = "item",
        name = "iron-plate",
        amount = 5
    }
}

data.raw.technology["bulk-inserter"].effects = {
    {type = "unlock-recipe", recipe = "bulk-inserter"}
}
data.raw.technology["bulk-inserter"].prerequisites = {"engine"}
data.raw.technology["bulk-inserter"].unit = {
    count = 50,
    ingredients = {{"automation-science-pack", 1}},
    time = 30
}