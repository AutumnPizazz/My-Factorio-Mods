-- 获取集装机械臂的配方
local bulk_inserter_recipe = data.raw.recipe["bulk-inserter"]

-- 修改配方的成分和结果，使其更容易在前期获得
bulk_inserter_recipe.ingredients = {
    {"small-parts-01", 2},
    {"iron-plate", 5}
}
-- bulk_inserter_recipe.result.count = 1  -- 每次制作获得1个集装机械臂

-- 获取相关的科技
local bulk_inserter_tech = data.raw["technology"]["bulk-inserter"]

-- 修改科技的效果和研究条件
bulk_inserter_tech.effects = {
    {type = "unlock-recipe", recipe = "bulk-inserter"}
}
bulk_inserter_tech.prerequisites = {"engine"}
bulk_inserter_tech.unit = {
    count = 50,
    ingredients = {{"automation-science-pack", 1}},
    time = 30
}