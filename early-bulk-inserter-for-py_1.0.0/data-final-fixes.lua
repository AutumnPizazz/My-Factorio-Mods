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

data.raw.recipe["mdrn-loader"].ingredients = {    
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
data.raw.technology["mdrn-loader"].effects = {
    {type = "unlock-recipe", recipe = "mdrn-loader"}
}
data.raw.technology["mdrn-loader"].prerequisites = {"steam-power"}
data.raw.technology["mdrn-loader"].unit = {
    count = 5,
    ingredients = {{"automation-science-pack", 1}},
    time = 10
}


data.raw.recipe["splitter"].ingredients = {    
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
data.raw.technology["logistics"].effects = {
    {type = "unlock-recipe", recipe = "splitter"}
}
data.raw.technology["logistics"].prerequisites = {"steam-power"}
data.raw.technology["logistics"].unit = {
    count = 5,
    ingredients = {{"automation-science-pack", 1}},
    time = 10
}


data.raw.recipe["selector-combinator"].ingredients = {
    {
        type = "item",
        name = "iron-plate",
        amount = 1
    }
}
data.raw.technology["advanced-combinators"].effects = {
    {type = "unlock-recipe", recipe = "selector-combinator"}
}
data.raw.technology["advanced-combinators"].prerequisites = {"steam-power"}
data.raw.technology["advanced-combinators"].unit = {
    count = 5,
    ingredients = {{"automation-science-pack", 1}},
    time = 10
}