Config = {}

----------------------------------
-- needs settings
----------------------------------
Config.EnableDebug = false
Config.StatusInterval = 30000 -- how often to update hunger/thirst status in milliseconds
Config.HungerRate = 0.4 -- Rate at which hunger goes down.
Config.ThirstRate = 0.8 -- Rate at which thirst goes down.
Config.CleanlinessRate = 0.07 -- Rate at which cleanliness goes down.
Config.BladderRate = 0.5 -- Rate at which bladder fills up (NEW)
Config.ShowCleanlinessBar = true -- Показывать бар чистоты
Config.CleanlinessBarAlwaysVisible = true -- Всегда видим или только когда < 100%
Config.WaterCleansingRate = 2 -- Сколько % чистоты восстанавливается каждые 2 секунды в воде
Config.DeepWaterMultiplier = 1.5 -- Множитель скорости очищения в глубокой воде
Config.BathingCleansingRate = 3 -- Сколько % чистоты восстанавливается каждую секунду при купании

----------------------------------
-- gradual consumption settings (NEW)
----------------------------------
Config.GradualConsumption = true -- Enable gradual consumption for food/drink
Config.ConsumptionTickInterval = 1000 -- How often to apply consumption effects (milliseconds)
Config.ConsumptionTicks = 10 -- How many ticks to spread the consumption over

----------------------------------
-- DIET VARIETY SYSTEM (Система рационов)
-- Сбрасывается каждую неделю
-- Чем чаще ешь одно и то же - тем меньше насыщает
-- Разнообразный рацион даёт бонус
----------------------------------
Config.DietSystem = {
    enabled = true,
    resetInterval = 604800,  -- 7 дней в секундах (неделя)
    
    -- Минимальный множитель эффективности (20% от стандарта)
    minEffectiveness = 0.20,
    
    -- Максимальный множитель эффективности при разнообразном питании (150%)
    maxEffectiveness = 1.50,
    
    -- Сколько раз нужно съесть еду чтобы она начала терять эффективность
    repetitionThreshold = 3,
    
    -- Насколько падает эффективность за каждое повторение после порога (в %)
    effectivenessDropPerRepeat = 10,
    
    -- Сколько разных продуктов нужно съесть для бонуса разнообразия
    varietyBonusThreshold = 10,
    
    -- Бонус за разнообразие (в % за каждый уникальный продукт сверх порога)
    varietyBonusPerItem = 3,
}

-- Категории еды для системы рационов
Config.FoodCategories = {
    -- Мясо
    meat = {'raw_meat', 'cooked_meat', 'sausage', 'bacon', 'steakeggs', 'beefroastdinner', 'chickenroastdinner'},
    -- Рыба
    fish = {'raw_fish', 'cooked_fish', 'cookedcrab', 'crabsoup', 'cookedcrayfish', 'crayfishsoup'},
    -- Фрукты
    fruits = {'apple', 'grapes', 'consumable_pear', 'consumable_peach', 'pear', 'banana', 'mango', 'melon', 'kiwi', 'pineapple', 'orange', 'lemon'},
    -- Овощи
    vegetables = {'corn', 'carrot', 'tomato', 'broccoli', 'potato', 'bakedpotato'},
    -- Выпечка
    baked = {'lemon_meringue_pie', 'blackberry_pie', 'raspberry_pie', 'applecrumble', 'fruitcake', 'potatocake', 'biscuits', 'cookies'},
    -- Супы/Тушёнка
    soups = {'beans_cooked', 'stew', 'soup'},
    -- Яйца
    eggs = {'scrambledegg', 'steakeggs'},
    -- Сладости
    sweets = {'chocolate', 'chocolate_cake', 'balls'},
    -- Напитки
    drinks = {'water', 'milk', 'coffee', 'cocoa', 'coke'},
}

----------------------------------
-- item consumption configuration
----------------------------------
Config.ConsumableItems = {
    -- ═══════════════════════════════════════════════════════════════
    -- НАПИТКИ (БЕЗАЛКОГОЛЬНЫЕ)
    -- ═══════════════════════════════════════════════════════════════
    ['water'] = { 
        hunger = 0, 
        thirst = 35, 
        stress = 0, 
        bladder = 20,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },
    ['milk'] = { 
        hunger = 5, 
        thirst = 25, 
        stress = -5, 
        bladder = 15,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },
    ['coffee'] = { 
        hunger = 0, 
        thirst = 20, 
        stress = -15, 
        bladder = 15,
        type = 'coffee',
        prop = 'p_mugCoffee01x'
    },
    ['cocoa'] = { 
        hunger = 5, 
        thirst = 20, 
        stress = -20, 
        bladder = 10,
        type = 'coffee',
        prop = 'p_mugCoffee01x'
    },
    ['coke'] = { 
        hunger = 0, 
        thirst = 25, 
        stress = -10, 
        bladder = 20,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },

-- ═══════════════════════════════════════════════════════════════
-- АЛКОГОЛЬ
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────
-- ЛЕГКИЙ АЛКОГОЛЬ (Level 1 - 60 секунд эффект)
-- ─────────────────────────────────────────────────────────────
['beer'] = { 
    hunger = 5, 
    thirst = 20, 
    stress = -15, 
    bladder = 20,
    type = 'alcohol',
    prop = 'p_bottlebeer01a',
    drunkLevel = 1,
    animType = 'drink'
},

['wine'] = { 
    hunger = 0, 
    thirst = 15, 
    stress = -20, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 1,
    animType = 'drink'
},

['apple_wine'] = { 
    hunger = 3, 
    thirst = 15, 
    stress = -18, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 1,
    animType = 'drink'
},

['carrot_moonshine'] = { 
    hunger = 3, 
    thirst = 8, 
    stress = -20, 
    bladder = 10,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 1,
    animType = 'drink'
},

-- ─────────────────────────────────────────────────────────────
-- КРЕПКИЙ АЛКОГОЛЬ (Level 2 - 90 секунд эффект)
-- ─────────────────────────────────────────────────────────────
['whiskey'] = { 
    hunger = 0, 
    thirst = 10, 
    stress = -25, 
    bladder = 10,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'drink'
},

['tequila'] = { 
    hunger = 0, 
    thirst = 10, 
    stress = -25, 
    bladder = 10,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'drink'
},

['lemonvodka'] = { 
    hunger = 0, 
    thirst = 15, 
    stress = -20, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'drink'
},

['mangovodka'] = { 
    hunger = 0, 
    thirst = 15, 
    stress = -20, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'drink'
},

['oldfashioned'] = { 
    hunger = 0, 
    thirst = 15, 
    stress = -25, 
    bladder = 10,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'drink'
},

['peach_moonshine'] = { 
    hunger = 5, 
    thirst = 10, 
    stress = -25, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

['apple_moonshine'] = { 
    hunger = 5, 
    thirst = 10, 
    stress = -25, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

['melon_moonshine'] = { 
    hunger = 5, 
    thirst = 15, 
    stress = -25, 
    bladder = 18,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

['blackberry_moonshine'] = { 
    hunger = 5, 
    thirst = 10, 
    stress = -28, 
    bladder = 12,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

['pineapple_moonshine'] = { 
    hunger = 5, 
    thirst = 12, 
    stress = -28, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

['minty_berry_moonshine'] = { 
    hunger = 3, 
    thirst = 12, 
    stress = -30, 
    bladder = 12,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 2,
    animType = 'moonshine'
},

-- ─────────────────────────────────────────────────────────────
-- ОЧЕНЬ КРЕПКИЙ АЛКОГОЛЬ (Level 3 - телепорт в Rhodes!)
-- ─────────────────────────────────────────────────────────────
['moonshine'] = { 
    hunger = 0, 
    thirst = 5, 
    stress = -30, 
    bladder = 15,
    type = 'alcohol',
    prop = 'p_bottleJD01x',  -- Специальная бутылка для moonshine
    drunkLevel = 3,
    animType = 'moonshine'
},

['ginseng_moonshine'] = { 
    hunger = 0, 
    thirst = 8, 
    stress = -35,  -- САМЫЙ КРЕПКИЙ!
    bladder = 12,
    type = 'alcohol',
    prop = 'p_bottleJD01x',
    drunkLevel = 3,
    animType = 'moonshine'
},

['potato_vodka'] = { 
    hunger = 0, 
    thirst = 5, 
    stress = -30, 
    bladder = 10,
    type = 'alcohol',
    prop = 'p_bottlewhiskey01x',
    drunkLevel = 3,
    animType = 'moonshine'
},

    -- ═══════════════════════════════════════════════════════════════
    -- ПРЕМИУМ АЛКОГОЛЬ
    -- ═══════════════════════════════════════════════════════════════
    ['premium_whiskey'] = { 
        hunger = 0, 
        thirst = 10, 
        stress = -40, 
        bladder = 10,
        type = 'alcohol',
        prop = 'p_bottlewhiskey01x'
    },
    ['tropical_punch'] = { 
        hunger = 10, 
        thirst = 25, 
        stress = -35, 
        bladder = 20,
        type = 'alcohol',
        prop = 'p_bottlewhiskey01x'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- ИНГРЕДИЕНТЫ ДЛЯ САМОГОНА (БРАГИ/МАШИ)
    -- ═══════════════════════════════════════════════════════════════
    ['alcohol'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -15, 
        bladder = 5,
        type = 'alcohol',
        prop = 'p_bottlewhiskey01x'
    },
    ['ginseng_mash'] = { 
        hunger = 0, 
        thirst = 5, 
        stress = -5, 
        bladder = 10,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },
    ['blackberry_mash'] = { 
        hunger = 5, 
        thirst = 8, 
        stress = -3, 
        bladder = 10,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },
    ['minty_berry_mash'] = { 
        hunger = 3, 
        thirst = 8, 
        stress = -5, 
        bladder = 10,
        type = 'drink',
        prop = 'p_bottlebeer01a'
    },
    -- ═══════════════════════════════════════════════════════════════
    -- ФРУКТЫ
    -- ═══════════════════════════════════════════════════════════════
    ['apple'] = { 
        hunger = 12, 
        thirst = 10, 
        stress = -3, 
        bladder = 5,
        type = 'food',
        prop = 'p_apple02x'
    },
    ['grapes'] = { 
        hunger = 10, 
        thirst = 15, 
        stress = -5, 
        bladder = 5,
        type = 'food',
        prop = 'p_grapes01x'
    },
    ['consumable_pear'] = { 
        hunger = 12, 
        thirst = 12, 
        stress = -3, 
        bladder = 5,
        type = 'food',
        prop = 'p_pear01x'
    },
    ['consumable_peach'] = { 
        hunger = 12, 
        thirst = 15, 
        stress = -5, 
        bladder = 5,
        type = 'food',
        prop = 'p_peach01x'
    },
    ['pear'] = { 
        hunger = 12, 
        thirst = 12, 
        stress = -3, 
        bladder = 5,
        type = 'food',
        prop = 'p_pear01x'
    },
    ['banana'] = { 
        hunger = 18, 
        thirst = 5, 
        stress = -5, 
        bladder = 2,
        type = 'food',
        prop = 'p_banana01x'
    },
    ['mango'] = { 
        hunger = 15, 
        thirst = 15, 
        stress = -8, 
        bladder = 5,
        type = 'food',
        prop = 'p_apple02x'
    },
    ['melon'] = { 
        hunger = 18, 
        thirst = 25, 
        stress = -10, 
        bladder = 10,
        type = 'food',
        prop = 'p_apple02x'
    },
    ['kiwi'] = { 
        hunger = 10, 
        thirst = 12, 
        stress = -3, 
        bladder = 5,
        type = 'food',
        prop = 'p_apple02x'
    },
    ['pineapple'] = { 
        hunger = 15, 
        thirst = 18, 
        stress = -8, 
        bladder = 8,
        type = 'food',
        prop = 'p_apple02x'
    },
    ['orange'] = { 
        hunger = 12, 
        thirst = 18, 
        stress = -5, 
        bladder = 8,
        type = 'food',
        prop = 'p_orange01x'
    },
    ['lemon'] = { 
        hunger = 5, 
        thirst = 10, 
        stress = 0, 
        bladder = 3,
        type = 'food',
        prop = 'p_lemon01x'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- ОВОЩИ
    -- ═══════════════════════════════════════════════════════════════
    ['corn'] = { 
        hunger = 15, 
        thirst = 5, 
        stress = -3, 
        bladder = 0,
        type = 'food',
        prop = 'p_corn01x'
    },
    ['carrot'] = { 
        hunger = 12, 
        thirst = 8, 
        stress = -3, 
        bladder = 3,
        type = 'food',
        prop = 'p_carrot01x'
    },
    ['tomato'] = { 
        hunger = 8, 
        thirst = 15, 
        stress = -3, 
        bladder = 5,
        type = 'food',
        prop = 'p_tomato01x'
    },
    ['broccoli'] = { 
        hunger = 12, 
        thirst = 5, 
        stress = -2, 
        bladder = 3,
        type = 'food',
        prop = 'p_broccoli01x'
    },
    ['potato'] = { 
        hunger = 15, 
        thirst = 0, 
        stress = -2, 
        bladder = 0,
        type = 'food',
        prop = 'p_potato01x'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- МЯСО / РЫБА (СЫРОЕ И ГОТОВОЕ)
    -- ═══════════════════════════════════════════════════════════════
    ['raw_meat'] = { 
        hunger = 10, 
        thirst = 0, 
        stress = 10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['raw_fish'] = { 
        hunger = 8, 
        thirst = 5, 
        stress = 10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['cooked_meat'] = { 
        hunger = 45, 
        thirst = 0, 
        stress = -15, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['cooked_fish'] = { 
        hunger = 35, 
        thirst = 5, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['sausage'] = { 
        hunger = 30, 
        thirst = -5, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['bacon'] = { 
        hunger = 25, 
        thirst = -5, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- МОРЕПРОДУКТЫ
    -- ═══════════════════════════════════════════════════════════════
    ['cookedcrab'] = { 
        hunger = 35, 
        thirst = 5, 
        stress = -12, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['crabsoup'] = { 
        hunger = 40, 
        thirst = 20, 
        stress = -18, 
        bladder = 15,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['cookedcrayfish'] = { 
        hunger = 30, 
        thirst = 5, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['crayfishsoup'] = { 
        hunger = 38, 
        thirst = 20, 
        stress = -15, 
        bladder = 15,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- ЯЙЦА / ЗАВТРАКИ
    -- ═══════════════════════════════════════════════════════════════
    ['scrambledegg'] = { 
        hunger = 25, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['steakeggs'] = { 
        hunger = 55, 
        thirst = 0, 
        stress = -20, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- СУПЫ / ТУШЁНКА / БОБЫ
    -- ═══════════════════════════════════════════════════════════════
    ['beans_cooked'] = { 
        hunger = 35, 
        thirst = 5, 
        stress = -8, 
        bladder = 10,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['stew'] = { 
        hunger = 50, 
        thirst = 15, 
        stress = -20, 
        bladder = 10,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['soup'] = { 
        hunger = 30, 
        thirst = 25, 
        stress = -15, 
        bladder = 15,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- ГОТОВЫЕ БЛЮДА
    -- ═══════════════════════════════════════════════════════════════
    ['bakedpotato'] = { 
        hunger = 30, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['beefroastdinner'] = { 
        hunger = 60, 
        thirst = 10, 
        stress = -25, 
        bladder = 5,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['chickenroastdinner'] = { 
        hunger = 55, 
        thirst = 10, 
        stress = -22, 
        bladder = 5,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- ВЫПЕЧКА / ПИРОГИ
    -- ═══════════════════════════════════════════════════════════════
    ['lemon_meringue_pie'] = { 
        hunger = 25, 
        thirst = 0, 
        stress = -18, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['blackberry_pie'] = { 
        hunger = 25, 
        thirst = 5, 
        stress = -18, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['raspberry_pie'] = { 
        hunger = 25, 
        thirst = 5, 
        stress = -18, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['applecrumble'] = { 
        hunger = 25, 
        thirst = 0, 
        stress = -15, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['fruitcake'] = { 
        hunger = 30, 
        thirst = 0, 
        stress = -20, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['potatocake'] = { 
        hunger = 30, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },

    -- ═══════════════════════════════════════════════════════════════
    -- СЛАДОСТИ / ДЕСЕРТЫ
    -- ═══════════════════════════════════════════════════════════════
    ['chocolate'] = { 
        hunger = 15, 
        thirst = -5, 
        stress = -20, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['chocolate_cake'] = { 
        hunger = 30, 
        thirst = -5, 
        stress = -25, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['biscuits'] = { 
        hunger = 15, 
        thirst = -10, 
        stress = -10, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['cookies'] = { 
        hunger = 15, 
        thirst = -10, 
        stress = -12, 
        bladder = 0,
        type = 'stew',
        prop = 'p_bowl04x_stew'
    },
    ['balls'] = { 
        hunger = 12, 
        thirst = -5, 
        stress = -10, 
        bladder = 0,
        type = 'food',
        prop = 'p_bread01x'
    },
    -- ═══════════════════════════════════════════════════════════════
    -- КУРИТЕЛЬНЫЕ ИЗДЕЛИЯ
    -- ═══════════════════════════════════════════════════════════════
    
    -- Пачка сигарет (10 штук)
    ['cigaret'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret2'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret3'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret4'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret5'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret6'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret7'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret8'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret9'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    ['cigaret10'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    
    -- Одиночная сигарета
    ['cigarette'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -10, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigarette',
        prop = 'P_CIGARETTE01X'
    },
    
    -- Сигара
    ['cigar'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -15, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'cigar',
        prop = 'P_CIGAR01X'
    },
    
    -- Трубка
    ['pipe'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -20, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'pipe',
        prop = 'P_PIPE01X'
    },
    
    -- Жевательный табак (5 штук)
    ['chewingtobacco'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'chewing_tobacco',
        prop = nil  -- Нет пропа для жевательного
    },
    ['chewingtobacco2'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'chewing_tobacco',
        prop = nil
    },
    ['chewingtobacco3'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'chewing_tobacco',
        prop = nil
    },
    ['chewingtobacco4'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'chewing_tobacco',
        prop = nil
    },
    ['chewingtobacco5'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = -8, 
        bladder = 0,
        type = 'smoking',
        smokingType = 'chewing_tobacco',
        prop = nil
    },
    
    -- Табак для трубки (расходник, не используется напрямую)
    ['pipetobacco'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = 0, 
        bladder = 0,
        type = 'none',
        prop = nil
    },
    -- ═══════════════════════════════════════════════════════════════
    -- ПРОЧЕЕ / ИНГРЕДИЕНТЫ
    -- ═══════════════════════════════════════════════════════════════
    ['matches'] = { 
        hunger = 0, 
        thirst = 0, 
        stress = 0, 
        bladder = 0,
        type = 'none',
        prop = 'p_matches01x'
    },
    ['sugar'] = { 
        hunger = 5, 
        thirst = -10, 
        stress = -5, 
        bladder = 0,
        type = 'food',
        prop = 'p_bag_sugar01x'
    },
    ['wheat'] = { 
        hunger = 5, 
        thirst = -5, 
        stress = 0, 
        bladder = 0,
        type = 'food',
        prop = 'p_wheat01x'
    },
}
-- ═══════════════════════════════════════════════════════════════
-- SMOKING SYSTEM CONFIG
-- ═══════════════════════════════════════════════════════════════

Config.SmokingSystem = {
    enabled = true,
    
    -- Эффекты от разных типов курения
    effects = {
        cigarette = {
            stress = -10,
            lungDamage = 1,
            addictionPoints = 1,
            duration = 60000  -- 1 минута эффекта
        },
        cigar = {
            stress = -15,
            lungDamage = 2,
            addictionPoints = 2,
            duration = 120000  -- 2 минуты
        },
        pipe = {
            stress = -20,
            lungDamage = 1,
            addictionPoints = 1,
            duration = 180000  -- 3 минуты
        },
        chewing_tobacco = {
            stress = -8,
            lungDamage = 0,  -- Не влияет на легкие
            addictionPoints = 1,
            duration = 120000
        }
    },
    
    -- Пороги зависимости
    addictionThresholds = {
        mild = { smokesPerDay = 5, consecutiveDays = 3 },
        moderate = { smokesPerDay = 10, consecutiveDays = 7 },
        severe = { smokesPerDay = 15, consecutiveDays = 14 }
    },
    
    -- Время до ломки (в миллисекундах)
    withdrawalTime = {
        mild = 14400000,     -- 4 часа
        moderate = 7200000,  -- 2 часа
        severe = 3600000     -- 1 час
    },
    
    -- Здоровье легких
    lungHealth = {
        maxHealth = 100,
        criticalLevel = 30,  -- При этом уровне - болезнь легких
        regenRate = 0.1,     -- Восстановление в час без курения
        regenTime = 3600000  -- Каждый час
    }
}

-- Маппинг предметов на типы курения
Config.SmokingItems = {
    -- Сигареты (пачка)
    ['cigaret'] = 'cigarette',
    ['cigaret2'] = 'cigarette',
    ['cigaret3'] = 'cigarette',
    ['cigaret4'] = 'cigarette',
    ['cigaret5'] = 'cigarette',
    ['cigaret6'] = 'cigarette',
    ['cigaret7'] = 'cigarette',
    ['cigaret8'] = 'cigarette',
    ['cigaret9'] = 'cigarette',
    ['cigaret10'] = 'cigarette',
    
    -- Одиночная сигарета
    ['cigarette'] = 'cigarette',
    
    -- Сигара
    ['cigar'] = 'cigar',
    
    -- Трубка
    ['pipe'] = 'pipe',
    
    -- Жевательный табак
    ['chewingtobacco'] = 'chewing_tobacco',
    ['chewingtobacco2'] = 'chewing_tobacco',
    ['chewingtobacco3'] = 'chewing_tobacco',
    ['chewingtobacco4'] = 'chewing_tobacco',
    ['chewingtobacco5'] = 'chewing_tobacco',
}
----------------------------------
-- bladder settings (NEW)
----------------------------------
Config.MaxBladder = 100 -- Maximum bladder level
Config.BladderWarningLevel = 80 -- Show warning when bladder reaches this level
Config.BladderCriticalLevel = 95 -- Critical level - may cause health damage
Config.BladderHealthDamage = true -- Enable health damage when bladder is critical
Config.BladderDamageAmount = 2 -- Amount of health to remove

----------------------------------
-- pee animation settings (UPDATED - using scenarios now)
----------------------------------
Config.PeeDuration = 10000 -- 10 seconds
Config.PeeStressRelief = 10 -- Amount of stress to relieve
Config.MinBladderToPee = 20 -- Minimum bladder level to use /pee

----------------------------------
-- stress settings
----------------------------------
Config.StressChance = 0.1 -- Default: 10% -- Percentage Stress Chance When Shooting (0-1)
Config.MinimumStress = 50 -- Minimum Stress Level For Screen Shaking
Config.MinimumSpeed = 100 -- Going Over This Speed Will Cause Stress
Config.StressDecayRate = 0.01 -- Rate at which stress goes down.

----------------------------------
-- hud player display settings
----------------------------------
Config.HidePlayerHealthNative  = true
Config.HidePlayerStaminaNative = true
Config.HidePlayerDeadEyeNative = true

----------------------------------
-- hud horse display settings
----------------------------------
Config.HideHorseHealthNative  = true
Config.HideHorseStaminaNative = true
Config.HideHorseCourageNative = true

----------------------------------
-- voice icon settings
----------------------------------
Config.VoiceAlwaysVisible = false  -- true = always visible, false = only when talking

----------------------------------
-- minimap / compass settings
----------------------------------
Config.OnFootMinimap = false -- set to true/false to disable/enable minimap when on foot
Config.OnFootCompass = false -- true = have the minimap set to a compass instead of off or normal minimap
Config.MountMinimap = false  -- set to false if you want to disable the minimap when on mount
Config.MountCompass  = false -- set to true if you want to have a compass instead of normal minimap while on a mount

----------------------------------
-- turn health damage on/off
----------------------------------
Config.DoHealthDamage = true

----------------------------------
-- critical levels for health damage (NEW)
----------------------------------
Config.CriticalHungerLevel = 15 -- Start taking damage when hunger <= this value
Config.CriticalThirstLevel = 15 -- Start taking damage when thirst <= this value
Config.CriticalCleanlinessLevel = 10 -- Start taking damage when cleanliness <= this value

----------------------------------
-- turn screen effect on/off
----------------------------------
Config.DoHealthDamageFx = false

----------------------------------
-- turn health damage sound on/off
----------------------------------
Config.DoHealthPainSound = true

----------------------------------
-- temp settings (only one setting)
----------------------------------
Config.TempFormat = 'celsius'
--Config.TempFormat = 'fahrenheit'

----------------------------------
-- temp feature (does damage to player if too hot or cold)
----------------------------------
Config.TempFeature = true

----------------------------------
-- warmth add while wearing (temp feature must be enabled)
----------------------------------
Config.WearingHat      = 1
Config.WearingShirt    = 2
Config.WearingPants    = 3
Config.WearingBoots    = 2
Config.WearingCoat     = 15
Config.WearingOpenCoat = 15
Config.WearingGloves   = 2
Config.WearingVest     = 2
Config.WearingPoncho   = -4
Config.WearingSkirt    = 0
Config.WearingChaps    = 0
----------------------------------
-- logo settings (NEW)
----------------------------------
Config.ShowLogo = true -- Enable/disable logo display
Config.LogoImage = 'https://upload.fixitfy.com.tr/images/FIXITFY-cJhsyAUKQN.png' -- URL to your logo image
Config.LogoSize = 100 -- Logo size in pixels
Config.LogoOpacity = 0.8 -- Logo opacity (0.0 - 1.0)
Config.LogoPosition = {
    top = '10px',
    right = '10px'
}

----------------------------------
-- ammo hud settings (NEW)
----------------------------------
Config.HideAmmoHUD = true -- Hide native ammo display
----------------------------------
-- job type warmth exemptions (temp feature must be enabled)
----------------------------------
Config.EnableNoWarmthJobs = false  -- set to true/false to enable/disable the feature

Config.NoWarmthJobs = {
    'leo',      -- Law enforcement (sheriff, deputy, marshal, etc.)
    'medic',    -- Medical jobs (doctor, surgeon, etc.)
    -- add more job types here
}

----------------------------------
-- warmth limit before impacts health  (temp feature must be enabled)
----------------------------------
Config.MinTemp = -5
Config.MaxTemp = 40

----------------------------------
-- cleanliness limit before impacts health
----------------------------------
Config.FlyEffect = true -- toggle flies on/off
Config.MinCleanliness = 30

----------------------------------
-- amount of health to remove if min/max temp reached
----------------------------------
Config.RemoveHealth = 5

----------------------------------
-- stress settings
----------------------------------
Config.Intensity = {
    ["shake"] = {
        [1] = {
            min = 50,
            max = 60,
            intensity = 0.12,
        },
        [2] = {
            min = 60,
            max = 70,
            intensity = 0.17,
        },
        [3] = {
            min = 70,
            max = 80,
            intensity = 0.22,
        },
        [4] = {
            min = 80,
            max = 90,
            intensity = 0.28,
        },
        [5] = {
            min = 90,
            max = 100,
            intensity = 0.32,
        },
    }
}

Config.EffectInterval = {
    [1] = {
        min = 50,
        max = 60,
        timeout = math.random(50000, 60000)
    },
    [2] = {
        min = 60,
        max = 70,
        timeout = math.random(40000, 50000)
    },
    [3] = {
        min = 70,
        max = 80,
        timeout = math.random(30000, 40000)
    },
    [4] = {
        min = 80,
        max = 90,
        timeout = math.random(20000, 30000)
    },
    [5] = {
        min = 90,
        max = 100,
        timeout = math.random(15000, 20000)
    }
}

----------------------------------
-- HUD icon colors configuration
----------------------------------
Config.IconColors = {
    -- Player Status Icons
    ['voice'] = {
        normal = '#FFFFFF',      -- White when not talking
        active = '#FF0000'       -- Red when talking
    },
    ['health'] = {
        normal = '#FFFFFF',      -- White when healthy
        low = '#FF0000'          -- Red when low health (<=30%)
    },
    ['stamina'] = {
        normal = '#FFFFFF',      -- White when full
        low = '#FF0000'          -- Red when low stamina (<=30%)
    },
    ['hunger'] = {
        normal = '#FFFFFF',      -- White when full
        low = '#FF0000'          -- Red when low hunger (<=30%)
    },
    ['thirst'] = {
        normal = '#FFFFFF',      -- White when full
        low = '#FF0000'          -- Red when low thirst (<=30%)
    },
    ['bladder'] = {
        normal = '#FFFFFF',      -- White when empty
        warning = '#FFA500',     -- Orange when getting full
        critical = '#FF0000'     -- Red when critical
    },
    ['cleanliness'] = {
        normal = '#FFFFFF',      -- White when clean
        low = '#FF0000'          -- Red when dirty (<=30%)
    },
    ['stress'] = {
        normal = '#FFFFFF',      -- White (stress icon color)
    },
    ['temp'] = {
        cold = '#FDD021',        -- Yellow when cold (<=30)
        normal = '#CFBCAE'       -- Light brown when normal
    },
    ['mail'] = {
        normal = '#FFFFFF',      -- White when no mail
        hasmail = '#FFD700'      -- Gold when has mail
    },
    ['outlaw'] = {
        normal = '#00FF00',      -- Green when not outlaw
        active = '#FF0000'       -- Red when outlaw
    },
    
    -- Horse Status Icons
    ['horse_health'] = {
        normal = '#a16600',      -- Brown/orange for horse health
        low = '#FF0000'          -- Red when low
    },
    ['horse_stamina'] = {
        normal = '#a16600',      -- Brown/orange for horse stamina
        low = '#FF0000'          -- Red when low
    },
    ['horse_clean'] = {
        normal = '#a16600',      -- Brown/orange for horse cleanliness
        low = '#FF0000'          -- Red when dirty
    }
}
--[[
    ═══════════════════════════════════════════════════════════════
    КОНФИГУРАЦИЯ СРОКА ГОДНОСТИ ЕДЫ
    ═══════════════════════════════════════════════════════════════
    
    decayRate = процент порчи в день (IRL)
    Формула: 100% / количество_дней = decayRate
    
    14 дней: 100/14 ≈ 7.14% в день
    20 дней: 100/20 = 5.00% в день
    21 день (3 недели): 100/21 ≈ 4.76% в день
    28 дней (4 недели): 100/28 ≈ 3.57% в день
    30 дней: 100/30 ≈ 3.33% в день
    45 дней (1.5 месяца): 100/45 ≈ 2.22% в день
    60 дней (2 месяца): 100/60 ≈ 1.67% в день
    90 дней (3 месяца): 100/90 ≈ 1.11% в день
    
    0 = не портится (крепкий алкоголь, табак, сахар)
]]

Config.FoodDecay = {
    enabled = true,
    checkInterval = 60000, -- Проверка каждые 60 секунд (IRL)
    
    -- ═══════════════════════════════════════════════════════════════
    -- НАПИТКИ (БЕЗАЛКОГОЛЬНЫЕ) - 1 месяц
    -- ═══════════════════════════════════════════════════════════════
    ['water'] = { decayRate = 3.33, minQuality = 0 },
    ['milk'] = { decayRate = 4.76, minQuality = 0 },  -- 3 недели (быстро портится)
    ['coffee'] = { decayRate = 2.22, minQuality = 0 }, -- 1.5 месяца
    ['cocoa'] = { decayRate = 2.22, minQuality = 0 },
    ['coke'] = { decayRate = 1.67, minQuality = 0 },  -- 2 месяца (консерванты)

    -- ═══════════════════════════════════════════════════════════════
    -- АЛКОГОЛЬ
    -- ═══════════════════════════════════════════════════════════════
    
    -- ЛЕГКИЙ АЛКОГОЛЬ (Level 1) - 2 месяца
    ['beer'] = { decayRate = 1.67, minQuality = 0 },
    ['wine'] = { decayRate = 1.11, minQuality = 0 },  -- 3 месяца
    ['apple_wine'] = { decayRate = 1.67, minQuality = 0 },
    ['carrot_moonshine'] = { decayRate = 1.67, minQuality = 0 },
    
    -- КРЕПКИЙ АЛКОГОЛЬ (Level 2+) - НЕ ПОРТИТСЯ
    ['whiskey'] = { decayRate = 0, minQuality = 100 },
    ['tequila'] = { decayRate = 0, minQuality = 100 },
    ['lemonvodka'] = { decayRate = 0, minQuality = 100 },
    ['mangovodka'] = { decayRate = 0, minQuality = 100 },
    ['oldfashioned'] = { decayRate = 0, minQuality = 100 },
    ['peach_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['apple_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['melon_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['blackberry_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['pineapple_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['minty_berry_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['moonshine'] = { decayRate = 0, minQuality = 100 },
    ['ginseng_moonshine'] = { decayRate = 0, minQuality = 100 },
    ['potato_vodka'] = { decayRate = 0, minQuality = 100 },
    ['premium_whiskey'] = { decayRate = 0, minQuality = 100 },
    ['tropical_punch'] = { decayRate = 0, minQuality = 100 },
    ['alcohol'] = { decayRate = 0, minQuality = 100 },
    
    -- Браги/Маши - 3 недели (ферментация)
    ['ginseng_mash'] = { decayRate = 4.76, minQuality = 0 },
    ['blackberry_mash'] = { decayRate = 4.76, minQuality = 0 },
    ['minty_berry_mash'] = { decayRate = 4.76, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- ФРУКТЫ - 2-4 недели
    -- ═══════════════════════════════════════════════════════════════
    ['apple'] = { decayRate = 4.76, minQuality = 0 },        -- 3 недели
    ['grapes'] = { decayRate = 7.14, minQuality = 0 },       -- 2 недели
    ['consumable_pear'] = { decayRate = 4.76, minQuality = 0 },
    ['consumable_peach'] = { decayRate = 5.00, minQuality = 0 },
    ['pear'] = { decayRate = 4.76, minQuality = 0 },
    ['banana'] = { decayRate = 7.14, minQuality = 0 },       -- 2 недели
    ['mango'] = { decayRate = 5.00, minQuality = 0 },
    ['melon'] = { decayRate = 3.33, minQuality = 0 },        -- 1 месяц
    ['kiwi'] = { decayRate = 3.33, minQuality = 0 },
    ['pineapple'] = { decayRate = 4.76, minQuality = 0 },
    ['orange'] = { decayRate = 3.33, minQuality = 0 },
    ['lemon'] = { decayRate = 2.50, minQuality = 0 },        -- 40 дней

    -- ═══════════════════════════════════════════════════════════════
    -- ОВОЩИ - 3-6 недель
    -- ═══════════════════════════════════════════════════════════════
    ['corn'] = { decayRate = 3.33, minQuality = 0 },         -- 1 месяц
    ['carrot'] = { decayRate = 2.22, minQuality = 0 },       -- 1.5 месяца
    ['tomato'] = { decayRate = 5.00, minQuality = 0 },       -- 20 дней
    ['broccoli'] = { decayRate = 4.76, minQuality = 0 },     -- 3 недели
    ['potato'] = { decayRate = 1.67, minQuality = 0 },       -- 2 месяца

    -- ═══════════════════════════════════════════════════════════════
    -- МЯСО / РЫБА - 14-20 дней сырое, 21-30 готовое
    -- ═══════════════════════════════════════════════════════════════
    ['raw_meat'] = { decayRate = 5.00, minQuality = 0 },     -- 20 дней
    ['raw_fish'] = { decayRate = 7.14, minQuality = 0 },     -- 14 дней
    ['cooked_meat'] = { decayRate = 3.33, minQuality = 0 },  -- 30 дней
    ['cooked_fish'] = { decayRate = 4.76, minQuality = 0 },  -- 21 день
    ['sausage'] = { decayRate = 3.33, minQuality = 0 },      -- 30 дней
    ['bacon'] = { decayRate = 3.33, minQuality = 0 },        -- 30 дней

    -- ═══════════════════════════════════════════════════════════════
    -- МОРЕПРОДУКТЫ - 21-30 дней
    -- ═══════════════════════════════════════════════════════════════
    ['cookedcrab'] = { decayRate = 4.76, minQuality = 0 },   -- 21 день
    ['crabsoup'] = { decayRate = 3.33, minQuality = 0 },     -- 30 дней
    ['cookedcrayfish'] = { decayRate = 4.76, minQuality = 0 },
    ['crayfishsoup'] = { decayRate = 3.33, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- ЯЙЦА / ЗАВТРАКИ - 21-30 дней
    -- ═══════════════════════════════════════════════════════════════
    ['scrambledegg'] = { decayRate = 4.76, minQuality = 0 },
    ['steakeggs'] = { decayRate = 4.76, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- СУПЫ / ТУШЁНКА / БОБЫ - 21-30 дней
    -- ═══════════════════════════════════════════════════════════════
    ['beans_cooked'] = { decayRate = 3.33, minQuality = 0 },
    ['stew'] = { decayRate = 3.33, minQuality = 0 },
    ['soup'] = { decayRate = 4.76, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- ГОТОВЫЕ БЛЮДА - 21-30 дней
    -- ═══════════════════════════════════════════════════════════════
    ['bakedpotato'] = { decayRate = 3.33, minQuality = 0 },
    ['beefroastdinner'] = { decayRate = 4.76, minQuality = 0 },
    ['chickenroastdinner'] = { decayRate = 4.76, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- ВЫПЕЧКА / ПИРОГИ - 4 недели (28 дней)
    -- ═══════════════════════════════════════════════════════════════
    ['lemon_meringue_pie'] = { decayRate = 3.57, minQuality = 0 },
    ['blackberry_pie'] = { decayRate = 3.57, minQuality = 0 },
    ['raspberry_pie'] = { decayRate = 3.57, minQuality = 0 },
    ['applecrumble'] = { decayRate = 3.57, minQuality = 0 },
    ['fruitcake'] = { decayRate = 2.22, minQuality = 0 },    -- 1.5 месяца
    ['potatocake'] = { decayRate = 3.57, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- СЛАДОСТИ / ДЕСЕРТЫ - 1-3 месяца
    -- ═══════════════════════════════════════════════════════════════
    ['chocolate'] = { decayRate = 1.11, minQuality = 0 },    -- 3 месяца
    ['chocolate_cake'] = { decayRate = 4.76, minQuality = 0 }, -- 3 недели
    ['biscuits'] = { decayRate = 1.67, minQuality = 0 },     -- 2 месяца
    ['cookies'] = { decayRate = 2.22, minQuality = 0 },      -- 1.5 месяца
    ['balls'] = { decayRate = 2.22, minQuality = 0 },

    -- ═══════════════════════════════════════════════════════════════
    -- КУРИТЕЛЬНЫЕ ИЗДЕЛИЯ - НЕ ПОРТЯТСЯ
    -- ═══════════════════════════════════════════════════════════════
    ['cigaret'] = { decayRate = 0, minQuality = 100 },
    ['cigaret2'] = { decayRate = 0, minQuality = 100 },
    ['cigaret3'] = { decayRate = 0, minQuality = 100 },
    ['cigaret4'] = { decayRate = 0, minQuality = 100 },
    ['cigaret5'] = { decayRate = 0, minQuality = 100 },
    ['cigaret6'] = { decayRate = 0, minQuality = 100 },
    ['cigaret7'] = { decayRate = 0, minQuality = 100 },
    ['cigaret8'] = { decayRate = 0, minQuality = 100 },
    ['cigaret9'] = { decayRate = 0, minQuality = 100 },
    ['cigaret10'] = { decayRate = 0, minQuality = 100 },
    ['cigarette'] = { decayRate = 0, minQuality = 100 },
    ['cigar'] = { decayRate = 0, minQuality = 100 },
    ['pipe'] = { decayRate = 0, minQuality = 100 },
    ['chewingtobacco'] = { decayRate = 0, minQuality = 100 },
    ['chewingtobacco2'] = { decayRate = 0, minQuality = 100 },
    ['chewingtobacco3'] = { decayRate = 0, minQuality = 100 },
    ['chewingtobacco4'] = { decayRate = 0, minQuality = 100 },
    ['chewingtobacco5'] = { decayRate = 0, minQuality = 100 },
    ['pipetobacco'] = { decayRate = 0, minQuality = 100 },

    -- ═══════════════════════════════════════════════════════════════
    -- ПРОЧЕЕ / ИНГРЕДИЕНТЫ
    -- ═══════════════════════════════════════════════════════════════
    ['matches'] = { decayRate = 0, minQuality = 100 },
    ['sugar'] = { decayRate = 0, minQuality = 100 },
    ['wheat'] = { decayRate = 1.11, minQuality = 0 },        -- 3 месяца
}

--[[
    ═══════════════════════════════════════════════════════════════
    ТЕКСТОВЫЕ ОПИСАНИЯ СОСТОЯНИЯ ЕДЫ
    ═══════════════════════════════════════════════════════════════
]]
Config.FoodQualityText = {
    [100] = { text = "Свежее", color = "#4ade80" },
    [80] = { text = "Хорошее", color = "#a3e635" },
    [60] = { text = "Нормальное", color = "#facc15" },
    [40] = { text = "Не первой свежести", color = "#fb923c" },
    [20] = { text = "Портится", color = "#f87171" },
    [0] = { text = "Испорчено", color = "#ef4444" },
}

--[[
    ═══════════════════════════════════════════════════════════════
    ЭФФЕКТЫ ОТ ИСПОРЧЕННОЙ ЕДЫ
    ═══════════════════════════════════════════════════════════════
]]
Config.SpoiledFoodEffects = {
    enabled = true,
    -- Шанс отравления в зависимости от качества еды
    poisonChance = {
        [80] = 0.00,   -- 80-100% качество - безопасно
        [60] = 0.05,   -- 60-79% - 5% шанс
        [40] = 0.15,   -- 40-59% - 15% шанс
        [20] = 0.35,   -- 20-39% - 35% шанс
        [0] = 0.70,    -- 0-19% - 70% шанс
    },
    -- Уменьшение эффективности еды в зависимости от качества
    effectivenessMultiplier = {
        [80] = 1.00,   -- Полная эффективность
        [60] = 0.85,   -- 85% эффективности
        [40] = 0.65,   -- 65% эффективности
        [20] = 0.40,   -- 40% эффективности
        [0] = 0.20,    -- 20% эффективности
    }
}