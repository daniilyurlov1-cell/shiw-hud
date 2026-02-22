local RSGCore = exports['rsg-core']:GetCoreObject()
local speed = 0.0
local cashAmount = 0
local bloodmoneyAmount = 0
local bankAmount = 0
local showUI = false
local temperature = 0
local temp = 0
local tempadd = 0
local isWeapon = false
local outlawstatus = 0
local isPeeing = false
local isConsuming = false
local consumeScenario = nil
local isInWater = false
local waterCleansingActive = false
local lastWaterCheck = 0
local SMOKING_DEBUG = true
local function debugSmoke(msg)
    if SMOKING_DEBUG then
        print('^3[CLIENT SMOKING]^7 ' .. msg)
    end
end

local function debugPrint(message)
    if Config and Config.EnableDebug then
        print(message)
    end
end

debugSmoke('Smoking system loading...')

-- ═══════════════════════════════════════════════════════════════
-- ALCOHOL SYSTEM VARIABLES
-- ═══════════════════════════════════════════════════════════════
local isDrunk = false
local currentDrunkLevel = 0
local drunkEffectActive = false
local withdrawalActive = false

local alcoholStats = {
    totalDrinksToday = 0,
    totalDrinksWeek = 0,
    lastDrinkTime = 0,
    consecutiveDrinkingDays = 0,
    soberTime = 0,
    drunkTime = 0,
    blackoutCount = 0,
    addictionLevel = 0
}

local ADDICTION_THRESHOLDS = {
    mild = { drinksPerDay = 3, consecutiveDays = 3, blackouts = 2 },
    moderate = { drinksPerDay = 5, consecutiveDays = 7, blackouts = 5 },
    severe = { drinksPerDay = 8, consecutiveDays = 14, blackouts = 10 }
}

lib.locale()

------------------------------------------------
-- Inventory Detection
------------------------------------------------
local inventoryOpen = false
local inventoryKeyPressed = false

------------------------------------------------
-- DIET VARIETY SYSTEM (Система рационов)
------------------------------------------------
local dietStats = {
    foodHistory = {},      -- История съеденной еды {itemName = count}
    weekStart = 0,         -- Время начала недели
    uniqueFoodsCount = 0   -- Количество уникальных продуктов
}

-- Расчёт множителя эффективности еды
local function calculateFoodEffectiveness(itemName)
    if not Config.DietSystem or not Config.DietSystem.enabled then
        return 1.0
    end
    
    local config = Config.DietSystem
    local timesEaten = dietStats.foodHistory[itemName] or 0
    local uniqueFoods = dietStats.uniqueFoodsCount or 0
    
    -- Базовый множитель
    local multiplier = 1.0
    
    -- Штраф за повторение
    if timesEaten >= config.repetitionThreshold then
        local penalties = timesEaten - config.repetitionThreshold
        local penaltyPercent = penalties * config.effectivenessDropPerRepeat
        multiplier = multiplier - (penaltyPercent / 100)
    end
    
    -- Бонус за разнообразие
    if uniqueFoods >= config.varietyBonusThreshold then
        local bonusItems = uniqueFoods - config.varietyBonusThreshold
        local bonusPercent = bonusItems * config.varietyBonusPerItem
        multiplier = multiplier + (bonusPercent / 100)
    end
    
    -- Ограничиваем в пределах min-max
    multiplier = math.max(config.minEffectiveness, math.min(config.maxEffectiveness, multiplier))
    
    if Config.EnableDebug then
        print('[DIET] Item: ' .. itemName .. ' | Times eaten: ' .. timesEaten .. ' | Unique foods: ' .. uniqueFoods .. ' | Multiplier: ' .. string.format("%.2f", multiplier))
    end
    
    return multiplier
end

-- Добавление еды в историю
local function addFoodToHistory(itemName)
    if not Config.DietSystem or not Config.DietSystem.enabled then return end
    
    -- Пропускаем напитки и курительные
    local itemConfig = Config.ConsumableItems[itemName]
    if not itemConfig then return end
    if itemConfig.type == 'drink' or itemConfig.type == 'alcohol' or itemConfig.type == 'smoking' or itemConfig.type == 'coffee' then
        return
    end
    
    -- Увеличиваем счётчик
    dietStats.foodHistory[itemName] = (dietStats.foodHistory[itemName] or 0) + 1
    
    -- Пересчитываем уникальные
    local count = 0
    for _, _ in pairs(dietStats.foodHistory) do
        count = count + 1
    end
    dietStats.uniqueFoodsCount = count
    
    -- Отправляем на сервер
    TriggerServerEvent('hud:server:addFoodToHistory', itemName)
    
    if Config.EnableDebug then
        print('[DIET] Added to history: ' .. itemName .. ' (total: ' .. dietStats.foodHistory[itemName] .. ')')
    end
end

-- Загрузка статистики рациона
RegisterNetEvent('hud:client:loadDietStats', function(stats)
    if stats then
        dietStats.foodHistory = stats.foodHistory or {}
        dietStats.weekStart = stats.weekStart or os.time()
        dietStats.uniqueFoodsCount = stats.uniqueFoodsCount or 0
        print('[DIET] Stats loaded - Unique foods: ' .. dietStats.uniqueFoodsCount)
    end
end)

-- Обновление статистики рациона
RegisterNetEvent('hud:client:updateDietStats', function(stats)
    if stats then
        dietStats.foodHistory = stats.foodHistory or {}
        dietStats.weekStart = stats.weekStart or dietStats.weekStart
        dietStats.uniqueFoodsCount = stats.uniqueFoodsCount or 0
    end
end)

-- Команда для просмотра статистики рациона
RegisterCommand('dietstats', function()
    local uniqueCount = dietStats.uniqueFoodsCount or 0
    local multiplier = 1.0
    
    if Config.DietSystem and Config.DietSystem.enabled then
        if uniqueCount >= Config.DietSystem.varietyBonusThreshold then
            local bonus = (uniqueCount - Config.DietSystem.varietyBonusThreshold) * Config.DietSystem.varietyBonusPerItem
            multiplier = 1.0 + (bonus / 100)
        end
    end
    
    -- Находим самую частую еду
    local mostEaten = "нет"
    local maxCount = 0
    for item, count in pairs(dietStats.foodHistory) do
        if count > maxCount then
            maxCount = count
            mostEaten = item
        end
    end
    
    lib.notify({
        title = 'Статистика рациона',
        description = 'Уникальных продуктов: ' .. uniqueCount .. '\nБонус разнообразия: ' .. string.format("%.0f%%", (multiplier - 1) * 100) .. '\nЧаще всего: ' .. mostEaten .. ' (' .. maxCount .. 'x)',
        type = 'inform',
        duration = 7000
    })
    
    print('=== DIET STATS ===')
    print('Unique foods: ' .. uniqueCount)
    print('Base multiplier: ' .. string.format("%.2f", multiplier))
    print('Most eaten: ' .. mostEaten .. ' (' .. maxCount .. 'x)')
    for item, count in pairs(dietStats.foodHistory) do
        print('  - ' .. item .. ': ' .. count)
    end
    print('==================')
end, false)

-- Сброс статистики рациона
RegisterCommand('resetdiet', function()
    dietStats = {
        foodHistory = {},
        weekStart = os.time(),
        uniqueFoodsCount = 0
    }
    TriggerServerEvent('hud:server:resetDietStats')
    lib.notify({ title = 'Рацион', description = 'Статистика рациона сброшена', type = 'success' })
end, false)

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 0x20190AB4) then
            inventoryKeyPressed = true
            Wait(300)
            if IsNuiFocused() then
                inventoryOpen = true
            end
            inventoryKeyPressed = false
        end
        if inventoryOpen and not IsNuiFocused() then
            inventoryOpen = false
        end
    end
end)

RegisterNetEvent('rsg-inventory:client:OpenInventory', function()
    inventoryOpen = true
    showUI = true
end)

RegisterNetEvent('inventory:client:OpenInventory', function()
    inventoryOpen = true
    showUI = true
end)

RegisterNetEvent('rsg-inventory:client:CloseInventory', function()
    inventoryOpen = false
end)

RegisterNetEvent('inventory:client:CloseInventory', function()
    inventoryOpen = false
end)

RegisterNUICallback('CloseInventory', function(data, cb)
    inventoryOpen = false
    cb('ok')
end)
-- ═══════════════════════════════════════════════════════════════
-- DIET CRAMPS SYSTEM (Скручивание живота при нарушении диеты)
-- ═══════════════════════════════════════════════════════════════
local lastCrampTime = 0
local crampAnimActive = false

-- Проверка нарушений диеты
local function getDietViolations()
    if not Config.DietSystem or not Config.DietSystem.enabled then
        return 0, {}
    end
    
    local threshold = Config.DietSystem.repetitionThreshold or 3
    
    -- Если есть отдельный порог для спазмов — используем его
    if Config.DietSystem.cramps and Config.DietSystem.cramps.violationThreshold then
        threshold = Config.DietSystem.cramps.violationThreshold
    end
    
    local violationCount = 0
    local violatedItems = {}
    
    for itemName, count in pairs(dietStats.foodHistory) do
        if count > threshold then
            violationCount = violationCount + 1
            table.insert(violatedItems, { name = itemName, count = count, over = count - threshold })
        end
    end
    
    return violationCount, violatedItems
end

-- Анимация боли в животе
local function playCrampAnimation()
    if crampAnimActive then return end
    crampAnimActive = true
    
    local ped = cache.ped
    
    -- Не прерываем если на лошади или в транспорте
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped) then
        crampAnimActive = false
        return
    end
    
    local dict = 'amb_misc@world_human_vomit@male_a@idle_b'
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if HasAnimDictLoaded(dict) then
        -- Анимация хватания за живот / рвотного позыва
        TaskPlayAnim(ped, dict, 'idle_a', 8.0, -8.0, 3000, 31, 0, false, false, false)
        
        -- Тряска камеры
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.2)
        
        Wait(3000)
        ClearPedTasks(ped)
        RemoveAnimDict(dict)
    end
    
    crampAnimActive = false
end

-- Применение эффекта спазма
local function applyCrampEffect()
    local crampConfig = Config.DietSystem.cramps
    
    debugPrint('[DIET CRAMP] Stomach cramp triggered!')
    
    -- Заполняем bladder
    if crampConfig.bladderFill and crampConfig.bladderFill > 0 then
        LocalPlayer.state:set('bladder', crampConfig.bladderFill, true)
        debugPrint('[DIET CRAMP] Bladder set to: ' .. crampConfig.bladderFill)
    end
    
    -- Добавляем стресс
    if crampConfig.stressAdd and crampConfig.stressAdd > 0 then
        updateNeed('stress', crampConfig.stressAdd, false)
        debugPrint('[DIET CRAMP] Stress added: ' .. crampConfig.stressAdd)
    end
    
    -- Снимаем голод (боль снижает аппетит)
    if crampConfig.hungerDrain and crampConfig.hungerDrain > 0 then
        updateNeed('hunger', crampConfig.hungerDrain, true)
        debugPrint('[DIET CRAMP] Hunger drained: ' .. crampConfig.hungerDrain)
    end
    
    -- Уведомление
    lib.notify({
        title = crampConfig.notifyTitle or 'Проблемы с желудком',
        description = crampConfig.notifyText or 'Вам скрутило живот!',
        type = 'error',
        duration = 6000
    })
    
    -- Анимация
    CreateThread(function()
        playCrampAnimation()
    end)
    
    -- Звуковой эффект
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
end

-- Основной поток проверки спазмов
CreateThread(function()
    -- Ждём загрузки всех систем
    Wait(30000)
    
    while true do
        -- Интервал проверки
        local checkInterval = 300000  -- 5 минут по умолчанию
        if Config.DietSystem and Config.DietSystem.cramps then
            checkInterval = Config.DietSystem.cramps.checkInterval or 300000
        end
        
        Wait(checkInterval)
        
        -- Проверяем включена ли система
        if not Config.DietSystem or not Config.DietSystem.enabled then
            goto continue
        end
        if not Config.DietSystem.cramps or not Config.DietSystem.cramps.enabled then
            goto continue
        end
        
        local crampConfig = Config.DietSystem.cramps
        local currentTime = GetGameTimer()
        
        -- Проверяем кулдаун
        local cooldown = crampConfig.cooldown or 3600000
        if lastCrampTime > 0 and (currentTime - lastCrampTime) < cooldown then
            debugPrint('[DIET CRAMP] On cooldown, skipping. Time left: ' .. 
                math.floor((cooldown - (currentTime - lastCrampTime)) / 60000) .. ' min')
            goto continue
        end
        
        -- Проверяем нарушения диеты
        local violationCount, violatedItems = getDietViolations()
        
        if violationCount == 0 then
            debugPrint('[DIET CRAMP] No diet violations, skipping')
            goto continue
        end
        
        -- Рассчитываем шанс спазма
        local baseChance = crampConfig.baseChance or 0.10
        local extraPerViolation = crampConfig.extraChancePerViolation or 0.03
        local maxChance = crampConfig.maxChance or 0.40
        
        local totalChance = baseChance + (violationCount * extraPerViolation)
        totalChance = math.min(totalChance, maxChance)
        
        debugPrint('[DIET CRAMP] Violations: ' .. violationCount .. 
            ' | Chance: ' .. string.format("%.1f%%", totalChance * 100))
        
        -- Бросаем кости
        local roll = math.random()
        if roll < totalChance then
            -- СПАЗМ!
            lastCrampTime = currentTime
            
            debugPrint('[DIET CRAMP] >>> CRAMP TRIGGERED! Roll: ' .. 
                string.format("%.3f", roll) .. ' < ' .. string.format("%.3f", totalChance))
            
            -- Логируем какие продукты вызвали
            for _, item in ipairs(violatedItems) do
                debugPrint('[DIET CRAMP] Violated item: ' .. item.name .. 
                    ' (eaten ' .. item.count .. 'x, over by ' .. item.over .. ')')
            end
            
            applyCrampEffect()
        else
            debugPrint('[DIET CRAMP] No cramp this time. Roll: ' .. 
                string.format("%.3f", roll) .. ' >= ' .. string.format("%.3f", totalChance))
        end
        
        ::continue::
    end
end)

-- Команда для дебага спазмов
RegisterCommand('testcramp', function()
    if Config.EnableDebug then
        local violations, items = getDietViolations()
        print('[DIET CRAMP] Violations: ' .. violations)
        for _, item in ipairs(items) do
            print('  - ' .. item.name .. ': ' .. item.count .. 'x (over by ' .. item.over .. ')')
        end
        applyCrampEffect()
        lastCrampTime = 0  -- Сбрасываем кулдаун для тестов
    end
end, false)

RegisterCommand('crampstatus', function()
    local violations, items = getDietViolations()
    local currentTime = GetGameTimer()
    local cooldown = (Config.DietSystem and Config.DietSystem.cramps and Config.DietSystem.cramps.cooldown) or 3600000
    local timeLeft = 0
    
    if lastCrampTime > 0 then
        timeLeft = math.max(0, cooldown - (currentTime - lastCrampTime))
    end
    
    local desc = 'Нарушений диеты: ' .. violations .. '\n'
    if timeLeft > 0 then
        desc = desc .. 'Кулдаун: ' .. math.floor(timeLeft / 60000) .. ' мин\n'
    else
        desc = desc .. 'Кулдаун: готово\n'
    end
    
    if #items > 0 then
        desc = desc .. 'Переедание: '
        for i, item in ipairs(items) do
            desc = desc .. item.name .. '(' .. item.count .. 'x)'
            if i < #items then desc = desc .. ', ' end
        end
    end
    
    lib.notify({
        title = 'Статус желудка',
        description = desc,
        type = violations > 0 and 'warning' or 'success',
        duration = 7000
    })
end, false)
------------------------------------------------
-- updateNeed function
------------------------------------------------
local function updateNeed(key, amount, isSubtract)
    local currentValue = LocalPlayer.state[key]
    
    if currentValue == nil then
        if key == 'hunger' or key == 'thirst' or key == 'cleanliness' then
            currentValue = 100
        elseif key == 'stress' or key == 'bladder' then
            currentValue = 0
        else
            currentValue = 0
        end
    end
    
    local newValue
    if isSubtract then
        newValue = currentValue - amount
    else
        newValue = currentValue + amount
    end

    newValue = lib.math.clamp(lib.math.round(newValue, 2), 0, 100)
    
    debugPrint(string.format('[HUD DEBUG] %s: %s -> %s (amount: %s, subtract: %s)', 
        key, currentValue, newValue, amount, tostring(isSubtract)))
    
    if LocalPlayer.state[key] ~= newValue then
        LocalPlayer.state:set(key, newValue, true)
    end
end

------------------------------------------------
-- send locales to NUI
------------------------------------------------
local function sendLocalesToNUI()
    local locales = {
        edit_mode_on_title = locale('edit_mode_on_title'),
        edit_mode_on_desc = locale('edit_mode_on_desc'),
        edit_mode_off_desc = locale('edit_mode_off_desc'),
        reset_hud_title = locale('reset_hud_title'),
        reset_hud_desc = locale('reset_hud_desc'),
        money_hud_label = locale('money_hud_label'),
        temp_label = locale('temp_label'),
        health_label = locale('health_label'),
        stamina_label = locale('stamina_label'),
        hunger_label = locale('hunger_label'),
        thirst_label = locale('thirst_label'),
        bladder_label = locale('bladder_label'),
        clean_label = locale('clean_label'),
        stress_label = locale('stress_label'),
        mail_label = locale('mail_label'),
        horse_health_label = locale('horse_health_label'),
        horse_stamina_label = locale('horse_stamina_label'),
        horse_clean_label = locale('horse_clean_label')
    }
    
    SendNUIMessage({
        action = 'setLocales',
        locales = locales
    })
end

------------------------------------------------
-- consumption animations with props
------------------------------------------------
local currentProp = nil
local isPlayingAnimation = false

local function PlayAnimEat(propName)
    if isPlayingAnimation then return end
    isPlayingAnimation = true
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    local dict = "mech_inventory@clothing@bandana"
    local anim = "NECK_2_FACE_RH"
    
    debugPrint('[HUD DEBUG] Playing EAT animation with prop: ' .. propName)

    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasAnimDictLoaded(dict) then
        debugPrint('[HUD ERROR] Failed to load anim dict: ' .. dict)
        isPlayingAnimation = false
        return
    end

    local hashItem = GetHashKey(propName)
    currentProp = CreateObject(hashItem, playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, false)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_HAND")

    Wait(100)

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(currentProp, ped, boneIndex, 0.08, -0.04, -0.05, -75.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    Wait(5300)

    if DoesEntityExist(currentProp) then
        DeleteObject(currentProp)
    end
    currentProp = nil
    ClearPedSecondaryTask(ped)
    isPlayingAnimation = false
    
    debugPrint('[HUD DEBUG] EAT animation complete')
end

local function PlayAnimDrink(propName)
    if isPlayingAnimation then return end
    isPlayingAnimation = true
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    local dict = "amb_rest_drunk@world_human_drinking@male_a@idle_a"
    local anim = "idle_a"
    
    debugPrint('[HUD DEBUG] Playing DRINK animation with prop: ' .. propName)

    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasAnimDictLoaded(dict) then
        debugPrint('[HUD ERROR] Failed to load anim dict: ' .. dict)
        isPlayingAnimation = false
        return
    end

    local hashItem = GetHashKey(propName)
    currentProp = CreateObject(hashItem, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_HAND")

    Wait(100)

    TaskPlayAnim(ped, dict, anim, 1.0, 8.0, 5000, 31, 0.0, false, false, false)
    AttachEntityToEntity(currentProp, ped, boneIndex, 0.08, -0.04, -0.05, -75.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    Wait(5300)

    if DoesEntityExist(currentProp) then
        DeleteObject(currentProp)
    end
    currentProp = nil
    ClearPedSecondaryTask(ped)
    isPlayingAnimation = false
    
    debugPrint('[HUD DEBUG] DRINK animation complete')
end

local function PlayAnimStew(propName)
    if isPlayingAnimation then return end
    isPlayingAnimation = true
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    
    debugPrint('[HUD DEBUG] Playing STEW animation with prop: ' .. propName)
    
    local stewProp = CreateObject(GetHashKey(propName), playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    local stewSpoonProp = CreateObject(GetHashKey("p_beefstew_spoon01x"), playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    
    Citizen.InvokeNative(0x669655FFB29EF1A9, stewProp, 0, "Stew_Fill", 1.0)
    Citizen.InvokeNative(0xCAAF2BCCFEF37F77, stewProp, 20)
    Citizen.InvokeNative(0xCAAF2BCCFEF37F77, stewSpoonProp, 82)
    
    TaskItemInteraction_2(ped, 599184882, stewProp, joaat("p_bowl04x_stew_PH_L_HAND"), -583731576, 1, 0, -1.0)
    TaskItemInteraction_2(ped, 599184882, stewSpoonProp, joaat("p_spoon01x_PH_R_HAND"), -583731576, 1, 0, -1.0)
    Citizen.InvokeNative(0xB35370D5353995CB, ped, -583731576, 1.0)
    
    Wait(6000)
    
    if DoesEntityExist(stewProp) then
        DeleteObject(stewProp)
    end
    if DoesEntityExist(stewSpoonProp) then
        DeleteObject(stewSpoonProp)
    end
    ClearPedSecondaryTask(ped)
    isPlayingAnimation = false
    
    debugPrint('[HUD DEBUG] STEW animation complete')
end

local function PlayAnimCoffee(propName)
    if isPlayingAnimation then return end
    isPlayingAnimation = true
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    
    debugPrint('[HUD DEBUG] Playing COFFEE animation with prop: ' .. propName)
    
    local coffeeProp = CreateObject(joaat(propName), playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    Citizen.InvokeNative(0x669655FFB29EF1A9, coffeeProp, 0, "CTRL_cupFill", 1.0)
    TaskItemInteraction_2(ped, GetHashKey("CONSUMABLE_COFFEE"), coffeeProp, GetHashKey("P_MUGCOFFEE01X_PH_R_HAND"), GetHashKey("DRINK_COFFEE_HOLD"), 1, 0, -1082130432)
    
    Wait(5000)
    
    if DoesEntityExist(coffeeProp) then
        DeleteObject(coffeeProp)
    end
    ClearPedSecondaryTask(ped)
    isPlayingAnimation = false
    
    debugPrint('[HUD DEBUG] COFFEE animation complete')
end

local function PlayAnimMoonshine(propName)
    if isPlayingAnimation then return end
    isPlayingAnimation = true
    
    local ped = cache.ped
    local playerCoords = GetEntityCoords(ped)
    
    debugPrint('[HUD DEBUG] Playing MOONSHINE animation with prop: ' .. propName)
    
    local prop = CreateObject(GetHashKey(propName), playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
    local boneIndex = GetEntityBoneIndexByName(ped, "PH_R_HAND")
    
    AttachEntityToEntity(prop, ped, boneIndex, 0.0, 0.0, 0.04, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) then
        lib.requestAnimDict('mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5')
        TaskPlayAnim(ped, 'mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5', 'uncork', 8.0, -8.0, 500, 31, 0, true, false, false)
        Wait(500)
        TaskPlayAnim(ped, 'mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5', 'chug_a', 8.0, -8.0, 5000, 31, 0, true, false, false)
        Wait(5000)
    else
        TaskItemInteraction_2(ped, 1737033966, prop, GetHashKey("p_bottleJD01x_ph_r_hand"), GetHashKey("DRINK_Bottle_Cylinder_d1-55_H18_Neck_A8_B1-8_QUICK_RIGHT_HAND"), true, 0, 0)
        Wait(4000)
    end
    
    ClearPedTasks(ped)
    
    if DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteObject(prop)
    end
    
    currentProp = nil
    isPlayingAnimation = false
end

-- ═══════════════════════════════════════════════════════════════
-- PLAY CONSUME ANIMATION (ROUTER) - ДОЛЖНА БЫТЬ ПОСЛЕ ВСЕХ АНИМАЦИЙ!
-- ═══════════════════════════════════════════════════════════════
local function playConsumeAnimation(itemType, propName)
    if not propName or propName == '' then
        debugPrint('[HUD WARNING] No prop specified for animation')
        return false
    end
    
    debugPrint('[HUD DEBUG] Starting animation - Type: ' .. itemType .. ', Prop: ' .. propName)
    
    -- Скрыть оружие во время еды/питья (чтобы не "летало" в воздухе)
    local ped = cache.ped
    local savedWeapon = GetPedCurrentHeldWeapon(ped)
    local unarmedHash = GetHashKey("WEAPON_UNARMED")
    if savedWeapon ~= 0 and savedWeapon ~= unarmedHash then
        SetCurrentPedWeapon(ped, unarmedHash, true)
    end
    
    PlaySoundFrontend("Core_Fill_Up", "Consumption_Sounds", true, 0)
    
    if itemType == 'food' then
        PlayAnimEat(propName)
    elseif itemType == 'drink' then
        PlayAnimDrink(propName)
    elseif itemType == 'alcohol' then
        PlayAnimDrink(propName)
    elseif itemType == 'stew' then
        PlayAnimStew(propName)
    elseif itemType == 'coffee' then
        PlayAnimCoffee(propName)
    elseif itemType == 'moonshine' then
        PlayAnimMoonshine(propName)
    else
        debugPrint('[HUD WARNING] Unknown animation type: ' .. itemType .. ', using default drink')
        PlayAnimDrink(propName)
    end
    
    -- Восстановить оружие после анимации
    if savedWeapon ~= 0 and savedWeapon ~= unarmedHash then
        SetCurrentPedWeapon(ped, savedWeapon, true)
    end
    
    return true
end

local function stopConsumeAnimation()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteObject(currentProp)
        currentProp = nil
    end
    
    if isPlayingAnimation then
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasks(cache.ped)
        isPlayingAnimation = false
    end
end
-- ═══════════════════════════════════════════════════════════════
-- ALCOHOL STATS SYNC
-- ═══════════════════════════════════════════════════════════════

-- Загрузка статистики с сервера
RegisterNetEvent('hud:client:loadAlcoholStats', function(stats)
    if stats then
        alcoholStats.totalDrinksToday = stats.totalDrinksToday or 0
        alcoholStats.totalDrinksWeek = stats.totalDrinksWeek or 0
        alcoholStats.consecutiveDrinkingDays = stats.consecutiveDrinkingDays or 0
        alcoholStats.blackoutCount = stats.blackoutCount or 0
        alcoholStats.addictionLevel = stats.addictionLevel or 0
        alcoholStats.lastDrinkTime = stats.lastDrinkTime or 0
        
        debugPrint('[HUD DEBUG] Alcohol stats loaded from DB:')
        debugPrint('[HUD DEBUG] - Drinks today: ' .. alcoholStats.totalDrinksToday)
        debugPrint('[HUD DEBUG] - Addiction level: ' .. alcoholStats.addictionLevel)
        
        -- Если есть зависимость - проверяем ломку
        if alcoholStats.addictionLevel > 0 then
            checkWithdrawal()
        end
    end
end)

-- Функция сохранения на сервер
local function saveAlcoholStatsToServer()
    TriggerServerEvent('hud:server:saveAlcoholStats', {
        totalDrinksToday = alcoholStats.totalDrinksToday,
        totalDrinksWeek = alcoholStats.totalDrinksWeek,
        consecutiveDrinkingDays = alcoholStats.consecutiveDrinkingDays,
        blackoutCount = alcoholStats.blackoutCount,
        addictionLevel = alcoholStats.addictionLevel,
        lastDrinkTime = alcoholStats.lastDrinkTime
    })
end
local function applyWithdrawalEffects(addictionLevel)
    if withdrawalActive then return end
    withdrawalActive = true
    
    local ped = cache.ped
    
    debugPrint('[HUD DEBUG] Applying withdrawal effects for level: ' .. addictionLevel)
    
    if addictionLevel == 1 then
        lib.notify({ title = 'Тяга к алкоголю', description = 'Вам хочется выпить...', type = 'warning', duration = 3000 })
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
        
    elseif addictionLevel == 2 then
        lib.notify({ title = 'Абстиненция', description = 'Ваши руки трясутся, вам нужна выпивка!', type = 'error', duration = 4000 })
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
        
        local tremorDict = 'mech_loco_m@generic@drunk@unarmed@idle_moderate_drunk'
        lib.requestAnimDict(tremorDict)
        TaskPlayAnim(ped, tremorDict, 'idle', 4.0, -4.0, 2000, 31, 0, false, false, false)
        
        updateNeed('stress', 10, false)
        
    elseif addictionLevel == 3 then
        lib.notify({ title = 'ЛОМКА', description = 'Вам очень плохо! Срочно нужен врач или алкоголь!', type = 'error', duration = 5000 })
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.6)
        AnimpostfxPlay("PlayerDrunk01")
        
        local tremorDict = 'script_re@crashed_wagon'
        lib.requestAnimDict(tremorDict)
        TaskPlayAnim(ped, tremorDict, 'male_drunk_action', 4.0, -4.0, 3000, 31, 0, false, false, false)
        
        updateNeed('stress', 25, false)
        
        if math.random() < 0.3 then
            TriggerServerEvent('diseases:server:addDisease', 'delirium_tremens', { source = 'withdrawal', severity = 5 })
        end
    end
    
    CreateThread(function()
        Wait(30000)
        withdrawalActive = false
        if addictionLevel >= 2 then
            AnimpostfxStop("PlayerDrunk01")
        end
    end)
end

local function checkWithdrawal()
    if alcoholStats.addictionLevel == 0 then return end
    
    local currentTime = GetGameTimer()
    local timeSinceLastDrink = currentTime - alcoholStats.lastDrinkTime
    
    local withdrawalTime = 0
    if alcoholStats.addictionLevel == 1 then
        withdrawalTime = 7200000
    elseif alcoholStats.addictionLevel == 2 then
        withdrawalTime = 3600000
    elseif alcoholStats.addictionLevel == 3 then
        withdrawalTime = 1800000
    end
    
    if alcoholStats.lastDrinkTime > 0 and timeSinceLastDrink > withdrawalTime then
        applyWithdrawalEffects(alcoholStats.addictionLevel)
    end
end

local function applyHangover(drunkLevel)
    if drunkLevel >= 2 then
        TriggerServerEvent('diseases:server:addDisease', 'hangover', { source = 'alcohol', severity = 1 })
        lib.notify({ title = 'Похмелье', description = 'У вас раскалывается голова...', type = 'warning', duration = 4000 })
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ALCOHOL TRACKING FUNCTIONS - ДОЛЖНЫ БЫТЬ ДО applyDrunkEffects!
-- ═══════════════════════════════════════════════════════════════
local function checkAddictionProgression()
    local currentAddiction = alcoholStats.addictionLevel
    local newAddiction = 0
    
    if alcoholStats.totalDrinksToday >= ADDICTION_THRESHOLDS.severe.drinksPerDay or
       alcoholStats.consecutiveDrinkingDays >= ADDICTION_THRESHOLDS.severe.consecutiveDays or
       alcoholStats.blackoutCount >= ADDICTION_THRESHOLDS.severe.blackouts then
        newAddiction = 3
    elseif alcoholStats.totalDrinksToday >= ADDICTION_THRESHOLDS.moderate.drinksPerDay or
           alcoholStats.consecutiveDrinkingDays >= ADDICTION_THRESHOLDS.moderate.consecutiveDays or
           alcoholStats.blackoutCount >= ADDICTION_THRESHOLDS.moderate.blackouts then
        newAddiction = 2
    elseif alcoholStats.totalDrinksToday >= ADDICTION_THRESHOLDS.mild.drinksPerDay or
           alcoholStats.consecutiveDrinkingDays >= ADDICTION_THRESHOLDS.mild.consecutiveDays or
           alcoholStats.blackoutCount >= ADDICTION_THRESHOLDS.mild.blackouts then
        newAddiction = 1
    end
    
    if newAddiction > currentAddiction then
        -- LIFESTYLE: устойчивость к зависимости
        local lsAddictOk, lsAddictResist = pcall(function() return exports['shiw-lifestyle']:GetAddictionResistance() end)
        if lsAddictOk and lsAddictResist and lsAddictResist > 0 then
            -- Шанс НЕ получить зависимость = resistance * 100%
            local resistRoll = math.random()
            if resistRoll < lsAddictResist then
                debugPrint('[HUD DEBUG] LIFESTYLE: Alcohol addiction resisted! (roll=' .. resistRoll .. ', resist=' .. lsAddictResist .. ')')
                return -- Зависимость не применяется
            end
        end
        
        alcoholStats.addictionLevel = newAddiction
        
        local diseaseName = nil
        local notifyText = ''
        
        if newAddiction == 1 then
            diseaseName = 'alcohol_addiction_mild'
            notifyText = 'Вы чувствуете легкую тягу к алкоголю...'
        elseif newAddiction == 2 then
            diseaseName = 'alcohol_addiction_moderate'
            notifyText = 'Ваша тяга к алкоголю усиливается!'
        elseif newAddiction == 3 then
            diseaseName = 'alcohol_addiction_severe'
            notifyText = 'Вы стали алкоголиком. Вам нужна помощь врача!'
        end
        
        lib.notify({ title = 'Зависимость', description = notifyText, type = newAddiction >= 2 and 'error' or 'warning', duration = 5000 })
        
        if diseaseName then
            TriggerServerEvent('diseases:server:addDisease', diseaseName, { source = 'alcohol', severity = newAddiction })
        end
        saveAlcoholStatsToServer()
        debugPrint('[HUD DEBUG] Addiction level increased to: ' .. newAddiction)
    end
end

local function updateAlcoholStats(drunkLevel)
    local currentTime = GetGameTimer()
    
    alcoholStats.totalDrinksToday = alcoholStats.totalDrinksToday + 1
    alcoholStats.totalDrinksWeek = alcoholStats.totalDrinksWeek + 1
    alcoholStats.lastDrinkTime = currentTime
    alcoholStats.soberTime = 0
    
    -- blackoutCount только при реальном отключении (Rhodes TP) — отключено, крепкий алкоголь = как обычный
    
    debugPrint('[HUD DEBUG] Alcohol stats - Drinks today: ' .. alcoholStats.totalDrinksToday .. ', Blackouts: ' .. alcoholStats.blackoutCount)
    
    checkAddictionProgression()
    
    -- 🆕 СОХРАНЯЕМ В БД
    saveAlcoholStatsToServer()
end

local function checkAlcoholPoisoning(drunkLevel)
    if drunkLevel >= 3 then
        local poisonChance = 0.3 + (alcoholStats.totalDrinksToday * 0.1)
        
        if math.random() < poisonChance then
            TriggerServerEvent('diseases:server:addDisease', 'alcohol_poisoning', { source = 'alcohol', severity = 3 })
            lib.notify({ title = 'Отравление', description = 'Вы выпили слишком много! Вам плохо...', type = 'error', duration = 5000 })
            debugPrint('[HUD DEBUG] Alcohol poisoning triggered!')
            return true
        end
    end
    return false
end
-- ═══════════════════════════════════════════════════════════════
-- DRUNK EFFECTS SYSTEM - ПОСЛЕ ВСЕХ ВСПОМОГАТЕЛЬНЫХ ФУНКЦИЙ!
-- ═══════════════════════════════════════════════════════════════
local function applyDrunkEffects(level)
    if drunkEffectActive then
        debugPrint('[HUD DEBUG] Drunk effect already active, skipping')
        return
    end
    
    updateAlcoholStats(level)
    
    if checkAlcoholPoisoning(level) then
        level = math.min(level + 1, 3)
    end
    
    drunkEffectActive = true
    currentDrunkLevel = level
    isDrunk = true
    
    local ped = cache.ped
    
    debugPrint('[HUD DEBUG] Applying drunk effects - Level: ' .. level)
    
    if level == 1 then
        lib.notify({ title = 'Опьянение', description = 'Какой крепкий напиток! *ик*', type = 'inform', duration = 3000 })
        
        Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.3)
        AnimpostfxPlay("PlayerDrunk01")
        
        local drunkIdleDict = 'mech_loco_m@generic@drunk@unarmed@idle_moderate_drunk'
        lib.requestAnimDict(drunkIdleDict)
        
        CreateThread(function()
            local drunkTime = 60000
            local startTime = GetGameTimer()
            
            while (GetGameTimer() - startTime) < drunkTime and currentDrunkLevel == 1 do
                Wait(5000)
                -- Периодически перезапускаем эффект: иначе сбивается отравлением/болезнями и не держится на экране
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.3)
                AnimpostfxPlay("PlayerDrunk01")
                if not IsPedWalking(ped) and not IsPedRunning(ped) and not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) then
                    if not IsEntityPlayingAnim(ped, drunkIdleDict, 'idle', 3) then
                        TaskPlayAnim(ped, drunkIdleDict, 'idle', 4.0, -4.0, 3000, 31, 0, false, false, false)
                    end
                end
            end
            
            if currentDrunkLevel == 1 then
                AnimpostfxStop("PlayerDrunk01")
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.0)
                ClearPedTasks(ped)
                isDrunk = false
                drunkEffectActive = false
                currentDrunkLevel = 0
                
                applyHangover(1)
                
                lib.notify({ title = 'Опьянение', description = 'Вы чувствуете себя трезвым', type = 'success', duration = 3000 })
            end
        end)
        
    elseif level == 2 then
        lib.notify({ title = 'Опьянение', description = 'Вы чувствуете себя довольно пьяным... *ик*', type = 'inform', duration = 3000 })
        
        Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.6)
        AnimpostfxPlay("PlayerDrunk01")
        
        local drunkIdleDict = 'mech_loco_m@generic@drunk@unarmed@idle_moderate_drunk'
        local drunkActionDict = 'script_re@crashed_wagon'
        lib.requestAnimDict(drunkIdleDict)
        lib.requestAnimDict(drunkActionDict)
        
        CreateThread(function()
            local drunkTime = 90000
            local startTime = GetGameTimer()
            
            while (GetGameTimer() - startTime) < drunkTime and currentDrunkLevel == 2 do
                Wait(4000)
                -- Периодически перезапускаем эффект: иначе сбивается отравлением/болезнями и не держится на экране
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.6)
                AnimpostfxPlay("PlayerDrunk01")
                if not IsPedWalking(ped) and not IsPedRunning(ped) and not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) then
                    if math.random(1, 3) == 1 then
                        TaskPlayAnim(ped, drunkActionDict, 'male_drunk_action', 4.0, -4.0, 4000, 31, 0, false, false, false)
                    else
                        TaskPlayAnim(ped, drunkIdleDict, 'idle', 4.0, -4.0, 3000, 31, 0, false, false, false)
                    end
                end
                
                if math.random(1, 5) == 1 then
                    lib.notify({ title = '*ик*', type = 'inform', duration = 1000 })
                end
            end
            
            if currentDrunkLevel == 2 then
                AnimpostfxStop("PlayerDrunk01")
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.0)
                ClearPedTasks(ped)
                isDrunk = false
                drunkEffectActive = false
                currentDrunkLevel = 0
                
                applyHangover(2)
                
                lib.notify({ title = 'Опьянение', description = 'Вы протрезвели', type = 'success', duration = 3000 })
            end
        end)
        
    elseif level >= 3 then
        -- Крепкий алкоголь (moonshine, vodka и т.д.) — как Level 2: сильное опьянение 90 сек, без ТП в Rhodes
        lib.notify({ title = 'Опьянение', description = 'Вы чувствуете себя довольно пьяным... *ик*', type = 'inform', duration = 3000 })
        
        Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.6)
        AnimpostfxPlay("PlayerDrunk01")
        
        local drunkIdleDict = 'mech_loco_m@generic@drunk@unarmed@idle_moderate_drunk'
        local drunkActionDict = 'script_re@crashed_wagon'
        lib.requestAnimDict(drunkIdleDict)
        lib.requestAnimDict(drunkActionDict)
        
        CreateThread(function()
            local drunkTime = 90000
            local startTime = GetGameTimer()
            
            while (GetGameTimer() - startTime) < drunkTime and currentDrunkLevel >= 3 do
                Wait(4000)
                -- Периодически перезапускаем эффект: иначе сбивается отравлением/болезнями и не держится на экране
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.6)
                AnimpostfxPlay("PlayerDrunk01")
                if not IsPedWalking(ped) and not IsPedRunning(ped) and not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) then
                    if math.random(1, 3) == 1 then
                        TaskPlayAnim(ped, drunkActionDict, 'male_drunk_action', 4.0, -4.0, 4000, 31, 0, false, false, false)
                    else
                        TaskPlayAnim(ped, drunkIdleDict, 'idle', 4.0, -4.0, 3000, 31, 0, false, false, false)
                    end
                end
                
                if math.random(1, 5) == 1 then
                    lib.notify({ title = '*ик*', type = 'inform', duration = 1000 })
                end
            end
            
            if currentDrunkLevel >= 3 then
                AnimpostfxStop("PlayerDrunk01")
                Citizen.InvokeNative(0x406CCF555B04FAD3, ped, 1, 0.0)
                ClearPedTasks(ped)
                isDrunk = false
                drunkEffectActive = false
                currentDrunkLevel = 0
                
                applyHangover(2)
                
                lib.notify({ title = 'Опьянение', description = 'Вы протрезвели', type = 'success', duration = 3000 })
            end
        end)
    end
end
-- ═══════════════════════════════════════════════════════════════
-- SMOKING SYSTEM - РУЧНЫЕ ЗАТЯЖКИ
-- ═══════════════════════════════════════════════════════════════

-- Состояние курения
local isSmokingActive = false
local smokingProp = nil
local puffsRemaining = 0
local currentSmokingType = nil
local currentSmokingItem = nil
local currentSmokingSlot = nil
local smokingStartTime = 0
local smokingStance = "c"

-- Промпты
local SmokePuffPrompt = nil
local SmokeDropPrompt = nil
local SmokeChangePrompt = nil

-- Статистика курения
local smokingStats = {
    totalSmokesToday = 0,
    totalSmokesWeek = 0,
    consecutiveSmokingDays = 0,
    lastSmokeTime = 0,
    addictionLevel = 0,
    lungHealth = 100
}

local smokingEffectActive = false

-- Статистика каннабиса (для зависимости: 3+ косяка/24ч в течение 4 дней)
local cannabisStats = {
    dayCounts = {}
}

-- Конфигурация курения
local SMOKING_CONFIG = {
    cigarette = {
        puffs = 15,
        prop = 'P_CIGARETTE01X',
        stressRelief = 10,
        lungDamage = 1,
        addictionPoints = 1
    },
    joint = {
        puffs = 6,
        prop = 'P_CIGARETTE01X',
        stressRelief = 100,
        lungDamage = 1,
        addictionPoints = 1
    },
    cigar = {
        puffs = 20,
        prop = 'P_CIGAR01X',
        stressRelief = 15,
        lungDamage = 2,
        addictionPoints = 2
    },
    pipe = {
        puffs = 25,
        prop = 'P_PIPE01X',
        stressRelief = 20,
        lungDamage = 1,
        addictionPoints = 1
    },
    chewing_tobacco = {
        puffs = 10,
        prop = nil,
        stressRelief = 8,
        lungDamage = 0,
        addictionPoints = 1
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 1. ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ АНИМАЦИИ
-- ═══════════════════════════════════════════════════════════════

local function Anim(ped, dict, anim, duration, flag)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, anim, 4.0, -4.0, duration, flag or 31, 0, false, false, false)
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- 2. СОЗДАНИЕ ПРОПА
-- ═══════════════════════════════════════════════════════════════

local function createSmokingProp(smokingType)
    local config = SMOKING_CONFIG[smokingType]
    if not config or not config.prop then return nil end
    
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    
    local propHash = GetHashKey(config.prop)
    RequestModel(propHash)
    
    local timeout = 0
    while not HasModelLoaded(propHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(propHash) then
        print('[SMOKING] Failed to load prop model')
        return nil
    end
    
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z + 0.2, true, true, true)
    
    if not DoesEntityExist(prop) then
        print('[SMOKING] Failed to create prop')
        return nil
    end
    
    print('[SMOKING] Prop created: ' .. config.prop)
    return prop
end

-- ═══════════════════════════════════════════════════════════════
-- 3. ПРИКРЕПЛЕНИЕ ПРОПА
-- ═══════════════════════════════════════════════════════════════

local function attachPropToHand(prop, ped)
    if not prop or not DoesEntityExist(prop) then return end
    local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
    local male = IsPedMale(ped)
    
    if male then
        AttachEntityToEntity(prop, ped, righthand, 0.017, -0.01, -0.01, 0.0, 120.0, 10.0, true, true, false, true, 1, true)
    else
        AttachEntityToEntity(prop, ped, righthand, 0.01, 0.0, 0.01, 0.0, -160.0, -130.0, true, true, false, true, 1, true)
    end
end

local function attachPropToMouth(prop, ped)
    if not prop or not DoesEntityExist(prop) then return end
    local mouth = GetEntityBoneIndexByName(ped, "skel_head")
    AttachEntityToEntity(prop, ped, mouth, -0.017, 0.1, -0.01, 0.0, 90.0, -90.0, true, true, false, true, 1, true)
end

-- ═══════════════════════════════════════════════════════════════
-- 4. БАЗОВАЯ АНИМАЦИЯ
-- ═══════════════════════════════════════════════════════════════

local function playBaseAnimation()
    local ped = cache.ped
    local male = IsPedMale(ped)
    
    -- Разрешаем анимацию даже при движении - она будет в верхней части тела
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped) then
        return
    end
    
    if male then
        if smokingStance == "c" then
            Anim(ped, "amb_rest@world_human_smoking@male_c@base", "base", -1, 31)
        elseif smokingStance == "b" then
            Anim(ped, "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", -1, 31)
        elseif smokingStance == "d" then
            Anim(ped, "amb_rest@world_human_smoking@male_d@base", "base", -1, 31)
        else
            Anim(ped, "amb_wander@code_human_smoking_wander@male_a@base", "base", -1, 31)
        end
    else
        if smokingStance == "c" then
            Anim(ped, "amb_rest@world_human_smoking@female_c@base", "base", -1, 31)
        elseif smokingStance == "b" then
            Anim(ped, "amb_rest@world_human_smoking@female_b@base", "base", -1, 31)
        else
            Anim(ped, "amb_rest@world_human_smoking@female_a@base", "base", -1, 31)
        end
    end
end
-- ═══════════════════════════════════════════════════════════════
-- 5. АНИМАЦИЯ ЗАЖИГАНИЯ
-- ═══════════════════════════════════════════════════════════════

local function playLightingAnimation(smokingType, prop)
    local ped = cache.ped
    local male = IsPedMale(ped)
    local mouth = GetEntityBoneIndexByName(ped, "skel_head")
    local righthand = GetEntityBoneIndexByName(ped, "SKEL_R_Finger13")
    local righthand2 = GetEntityBoneIndexByName(ped, "SKEL_R_Finger12")
    
    print('[SMOKING] Playing lighting animation for type: ' .. tostring(smokingType))
    
    if smokingType == 'cigar' then
        -- СИГАРА - используем правильные анимации сигар
        AttachEntityToEntity(prop, ped, righthand2, 0.01, -0.005, 0.016, 0.0, 300.0, -40.0, true, true, false, true, 1, true)
        
        if male then
            Anim(ped, "amb_rest@world_human_smoke_cigar@male_a@base", "base", -1, 31)
        else
            Anim(ped, "amb_rest@world_human_smoke_cigar@female_a@base", "base", -1, 31)
        end
        Wait(1000)
        
    elseif smokingType == 'pipe' then
        -- ТРУБКА: более стабильная привязка и анимации без "залипания"
        AttachEntityToEntity(prop, ped, righthand, 0.012, -0.02, 0.015, -160.0, 65.0, -20.0, true, true, false, true, 1, true)

        local playedEnter = Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@stand_enter", "enter_front", 4200, 31)
        if playedEnter then
            Wait(3900)
        else
            Wait(1200)
        end

        if not Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@base", "base", -1, 31) then
            Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@wip_base", "wip_base", -1, 31)
        end
        
        print('[SMOKING] Pipe lighting complete (stable mode)')
        
    else
        -- СИГАРЕТЫ - стандартная анимация
        if male then
            AttachEntityToEntity(prop, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            Anim(ped, "amb_rest@world_human_smoking@male_c@stand_enter", "enter_back_rf", 5400, 0)
            Wait(1000)
            
            AttachEntityToEntity(prop, ped, righthand, 0.03, -0.01, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
            Wait(1000)
            
            AttachEntityToEntity(prop, ped, mouth, -0.017, 0.1, -0.01, 0.0, 90.0, -90.0, true, true, false, true, 1, true)
            Wait(3000)
            
            AttachEntityToEntity(prop, ped, righthand, 0.017, -0.01, -0.01, 0.0, 120.0, 10.0, true, true, false, true, 1, true)
            Wait(1000)
            
            ClearPedTasks(ped)
        else
            AttachEntityToEntity(prop, ped, mouth, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            Anim(ped, "amb_rest@world_human_smoking@female_c@base", "base", -1, 31)
            Wait(1000)
            
            AttachEntityToEntity(prop, ped, righthand, 0.01, 0.0, 0.01, 0.0, -160.0, -130.0, true, true, false, true, 1, true)
            Wait(2500)
            
            ClearPedTasks(ped)
        end
    end
    
    print('[SMOKING] Lighting animation complete')
end
-- ═══════════════════════════════════════════════════════════════
-- 6. АНИМАЦИЯ ЗАТЯЖКИ (ИСПРАВЛЕННАЯ - сигарета остаётся в руке)
-- ═══════════════════════════════════════════════════════════════

local function playPuffAnimation()
    local ped = cache.ped
    local male = IsPedMale(ped)
    
    print('[SMOKING] Playing puff animation for type: ' .. tostring(currentSmokingType))
    
    if currentSmokingType == 'cigar' then
        -- СИГАРА - анимации сигар
        if male then
            if smokingStance == "a" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_a@idle_a", "idle_a", -1, 31)
                Wait(8500)
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_b@idle_a", "idle_a", -1, 31)
                Wait(8000)
            else
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_c@idle_a", "idle_a", -1, 31)
                Wait(7000)
            end
        else
            if smokingStance == "a" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@female_a@idle_a", "idle_a", -1, 31)
                Wait(9000)
            else
                Anim(ped, "amb_rest@world_human_smoke_cigar@female_b@idle_a", "idle_b", -1, 31)
                Wait(8000)
            end
        end
        
    elseif currentSmokingType == 'pipe' then
        -- ТРУБКА: используем только стабильные словари/клипы
        if not Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@idle_a", "idle_a", -1, 31) then
            Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@wip_base", "wip_base", -1, 31)
        end
        Wait(6500)
        
    else
        -- СИГАРЕТЫ - стандартные анимации
        if male then
            if smokingStance == "c" then
                Anim(ped, "amb_rest@world_human_smoking@male_c@idle_a", "idle_a", -1, 31)
                Wait(8500)
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoking@nervous_stressed@male_b@idle_a", "idle_a", -1, 31)
                Wait(3199)
            elseif smokingStance == "d" then
                Anim(ped, "amb_rest@world_human_smoking@male_d@idle_a", "idle_b", -1, 31)
                Wait(7366)
            else
                Anim(ped, "amb_rest@world_human_smoking@male_a@idle_a", "idle_a", -1, 31)
                Wait(8200)
            end
        else
            if smokingStance == "c" then
                Anim(ped, "amb_rest@world_human_smoking@female_c@idle_a", "idle_a", -1, 31)
                Wait(9566)
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoking@female_b@idle_a", "idle_b", -1, 31)
                Wait(4266)
            else
                Anim(ped, "amb_rest@world_human_smoking@female_a@idle_a", "idle_b", -1, 31)
                Wait(6100)
            end
        end
    end
    
    ClearPedTasks(ped)
    
    print('[SMOKING] Puff animation complete')
end
-- ═══════════════════════════════════════════════════════════════
-- 7. СМЕНА ПОЗЫ
-- ═══════════════════════════════════════════════════════════════

local function changeStance()
    local ped = cache.ped
    local male = IsPedMale(ped)
    
    print('[SMOKING] Changing stance from: ' .. smokingStance .. ' for type: ' .. tostring(currentSmokingType))
    
    if currentSmokingType == 'cigar' then
        -- СИГАРА - смена поз сигар
        if male then
            if smokingStance == "a" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_b@base", "base", -1, 31)
                smokingStance = "b"
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_c@base", "base", -1, 31)
                smokingStance = "c"
            else
                Anim(ped, "amb_rest@world_human_smoke_cigar@male_a@base", "base", -1, 31)
                smokingStance = "a"
            end
        else
            if smokingStance == "a" then
                Anim(ped, "amb_rest@world_human_smoke_cigar@female_b@base", "base", -1, 31)
                smokingStance = "b"
            else
                Anim(ped, "amb_rest@world_human_smoke_cigar@female_a@base", "base", -1, 31)
                smokingStance = "a"
            end
        end
        
    elseif currentSmokingType == 'pipe' then
        -- ТРУБКА: безопасное переключение между 2 рабочими позами
        if smokingStance == "a" then
            if not Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@idle_a", "idle_a", -1, 31) then
                Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@wip_base", "wip_base", -1, 31)
            end
            smokingStance = "b"
        else
            if not Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@base", "base", -1, 31) then
                Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@wip_base", "wip_base", -1, 31)
            end
            smokingStance = "a"
        end
        
    else
        -- СИГАРЕТЫ - стандартная смена поз
        if male then
            if smokingStance == "c" then
                Anim(ped, "amb_rest@world_human_smoking@nervous_stressed@male_b@base", "base", -1, 30)
                smokingStance = "b"
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoking@male_d@base", "base", -1, 30)
                smokingStance = "d"
            elseif smokingStance == "d" then
                Anim(ped, "amb_rest@world_human_smoking@male_d@trans", "d_trans_a", -1, 30)
                Wait(4000)
                Anim(ped, "amb_wander@code_human_smoking_wander@male_a@base", "base", -1, 30)
                smokingStance = "a"
            else
                Anim(ped, "amb_rest@world_human_smoking@male_a@trans", "a_trans_c", -1, 30)
                Wait(4233)
                Anim(ped, "amb_rest@world_human_smoking@male_c@base", "base", -1, 30)
                smokingStance = "c"
            end
        else
            if smokingStance == "c" then
                Anim(ped, "amb_rest@world_human_smoking@female_b@base", "base", -1, 30)
                smokingStance = "b"
            elseif smokingStance == "b" then
                Anim(ped, "amb_rest@world_human_smoking@female_b@trans", "b_trans_a", -1, 30)
                Wait(5733)
                Anim(ped, "amb_rest@world_human_smoking@female_a@base", "base", -1, 30)
                smokingStance = "a"
            else
                Anim(ped, "amb_rest@world_human_smoking@female_c@base", "base", -1, 30)
                smokingStance = "c"
            end
        end
    end
    
    print('[SMOKING] New stance: ' .. smokingStance)
end

-- ═══════════════════════════════════════════════════════════════
-- 8. АНИМАЦИЯ ОКОНЧАНИЯ
-- ═══════════════════════════════════════════════════════════════

local function playFinishAnimation()
    local ped = cache.ped
    local male = IsPedMale(ped)
    
    print('[SMOKING] Playing finish animation for type: ' .. tostring(currentSmokingType))
    
    ClearPedSecondaryTask(ped)
    
    if currentSmokingType == 'cigar' then
        -- СИГАРА
        if male then
            Anim(ped, "amb_rest@world_human_smoke_cigar@male_a@stand_exit", "exit_back", 3000, 1)
            Wait(2800)
        else
            Anim(ped, "amb_rest@world_human_smoke_cigar@female_a@stand_exit", "exit_back", 3000, 1)
            Wait(2800)
        end
        
    elseif currentSmokingType == 'pipe' then
        -- ТРУБКА
        Anim(ped, "amb_rest@world_human_smoking@pipe@proper@male_a@stand_exit", "exit_front", 6000, 30)
        Wait(6000)
        
    else
        -- СИГАРЕТЫ
        if male then
            Anim(ped, "amb_rest@world_human_smoking@male_a@stand_exit", "exit_back", 3000, 1)
            Wait(2800)
        else
            Anim(ped, "amb_rest@world_human_smoking@female_b@trans", "b_trans_fire_stand_a", 4000, 1)
            Wait(3800)
        end
    end
    
    ClearPedTasks(ped)
    print('[SMOKING] Finish animation complete')
end

-- ═══════════════════════════════════════════════════════════════
-- 9. ПРОМПТЫ
-- ═══════════════════════════════════════════════════════════════

local function SetupSmokingPrompts()
    -- Промпт затяжки (E)
    SmokePuffPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(SmokePuffPrompt, 0xCEFD9220) -- E key
    local puffStr = CreateVarString(10, 'LITERAL_STRING', 'Затяжка')
    PromptSetText(SmokePuffPrompt, puffStr)
    PromptSetEnabled(SmokePuffPrompt, false)
    PromptSetVisible(SmokePuffPrompt, false)
    PromptSetHoldMode(SmokePuffPrompt, false)
    PromptRegisterEnd(SmokePuffPrompt)
    
    -- Промпт выбросить (F)
    SmokeDropPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(SmokeDropPrompt, 0xB2F377E8) -- F key
    local dropStr = CreateVarString(10, 'LITERAL_STRING', 'Выбросить')
    PromptSetText(SmokeDropPrompt, dropStr)
    PromptSetEnabled(SmokeDropPrompt, false)
    PromptSetVisible(SmokeDropPrompt, false)
    PromptSetHoldMode(SmokeDropPrompt, false)
    PromptRegisterEnd(SmokeDropPrompt)
    
    -- Промпт сменить позу (R)
    SmokeChangePrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(SmokeChangePrompt, 0xE30CD707) -- R key
    local changeStr = CreateVarString(10, 'LITERAL_STRING', 'Сменить позу')
    PromptSetText(SmokeChangePrompt, changeStr)
    PromptSetEnabled(SmokeChangePrompt, false)
    PromptSetVisible(SmokeChangePrompt, false)
    PromptSetHoldMode(SmokeChangePrompt, false)
    PromptRegisterEnd(SmokeChangePrompt)
    
    print('[SMOKING] Prompts created')
end

local function ShowSmokingPrompts()
    if SmokePuffPrompt then
        PromptSetEnabled(SmokePuffPrompt, true)
        PromptSetVisible(SmokePuffPrompt, true)
    end
    if SmokeDropPrompt then
        PromptSetEnabled(SmokeDropPrompt, true)
        PromptSetVisible(SmokeDropPrompt, true)
    end
    if SmokeChangePrompt then
        PromptSetEnabled(SmokeChangePrompt, true)
        PromptSetVisible(SmokeChangePrompt, true)
    end
end

local function HideSmokingPrompts()
    if SmokePuffPrompt then
        PromptSetEnabled(SmokePuffPrompt, false)
        PromptSetVisible(SmokePuffPrompt, false)
    end
    if SmokeDropPrompt then
        PromptSetEnabled(SmokeDropPrompt, false)
        PromptSetVisible(SmokeDropPrompt, false)
    end
    if SmokeChangePrompt then
        PromptSetEnabled(SmokeChangePrompt, false)
        PromptSetVisible(SmokeChangePrompt, false)
    end
end

-- Инициализация промптов
CreateThread(function()
    Wait(2000)
    SetupSmokingPrompts()
end)

-- ═══════════════════════════════════════════════════════════════
-- 10. ЭФФЕКТЫ КУРЕНИЯ
-- ═══════════════════════════════════════════════════════════════

local function checkCannabisAddiction()
    local dayId = math.floor(os.time() / 86400)
    local consec = 0
    for i = 0, 10 do
        local d = dayId - i
        if (cannabisStats.dayCounts[d] or 0) >= 3 then
            consec = consec + 1
        else
            break
        end
    end
    if consec >= 4 then
        local lsOk, lsResist = pcall(function() return exports['shiw-lifestyle']:GetAddictionResistance() end)
        if lsOk and lsResist and lsResist > 0 and math.random() < lsResist then
            return
        end
        lib.notify({ title = 'Зависимость', description = 'Вы чувствуете постоянную тягу к травке...', type = 'error', duration = 5000 })
        TriggerServerEvent('diseases:server:addDisease', 'cannabis_addiction', { source = 'cannabis' })
    end
end

local function updateCannabisStats()
    local dayId = math.floor(os.time() / 86400)
    cannabisStats.dayCounts[dayId] = (cannabisStats.dayCounts[dayId] or 0) + 1
    for d, _ in pairs(cannabisStats.dayCounts) do
        if d < dayId - 10 then cannabisStats.dayCounts[d] = nil end
    end
    TriggerServerEvent('hud:server:saveCannabisStats', cannabisStats.dayCounts)
    checkCannabisAddiction()
    -- Облегчение абстиненции на 2 часа (лечится только перекуром)
    LocalPlayer.state:set('cannabisReliefUntil', GetGameTimer() + 7200000, true)
end

local function applySmokingEffectsInternal(smokingType, itemName)
    if smokingEffectActive then return end
    smokingEffectActive = true
    
    local config = SMOKING_CONFIG[smokingType]
    if not config then 
        smokingEffectActive = false
        return 
    end
    
    print('[SMOKING] Applying effects for: ' .. smokingType)
    
    -- Снижаем стресс
    updateNeed('stress', config.stressRelief, true)
    
    local isCannabis = (smokingType == 'joint') or (itemName and string.match(itemName, '^loaded_pipe_'))
    if isCannabis then
        updateCannabisStats()
    end
    
    -- Обновляем статистику
    local currentTime = GetGameTimer()
    smokingStats.totalSmokesToday = smokingStats.totalSmokesToday + 1
    smokingStats.totalSmokesWeek = smokingStats.totalSmokesWeek + 1
    smokingStats.lastSmokeTime = currentTime
    -- LIFESTYLE: устойчивость к зависимости — снижает урон лёгким
    local lungDmg = config.lungDamage
    local lsSmkOk, lsSmkResist = pcall(function() return exports['shiw-lifestyle']:GetAddictionResistance() end)
    if lsSmkOk and lsSmkResist and lsSmkResist > 0 then
        lungDmg = math.max(0, math.floor(lungDmg * (1.0 - lsSmkResist)))
    end
    smokingStats.lungHealth = math.max(0, smokingStats.lungHealth - lungDmg)
    
    -- Сохраняем статистику
    TriggerServerEvent('hud:server:saveSmokingStats', {
        totalSmokesToday = smokingStats.totalSmokesToday,
        totalSmokesWeek = smokingStats.totalSmokesWeek,
        consecutiveSmokingDays = smokingStats.consecutiveSmokingDays,
        lastSmokeTime = smokingStats.lastSmokeTime,
        addictionLevel = smokingStats.addictionLevel,
        lungHealth = smokingStats.lungHealth
    })
    
    CreateThread(function()
        Wait(5000)
        smokingEffectActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- 11. ЗАВЕРШЕНИЕ КУРЕНИЯ
-- ═══════════════════════════════════════════════════════════════

local function finishSmoking(completed)
    if not isSmokingActive then 
        print('[SMOKING] finishSmoking called but not active, ignoring')
        return 
    end
    
    print('[SMOKING] Finishing - Completed: ' .. tostring(completed))
    
    local smokingType = currentSmokingType
    local itemName = currentSmokingItem
    local slot = currentSmokingSlot
    
    -- Скрываем промпты СРАЗУ
    HideSmokingPrompts()
    
    -- Анимация окончания
    playFinishAnimation()
    
    -- Удаляем проп
    if smokingProp and DoesEntityExist(smokingProp) then
        DetachEntity(smokingProp, true, true)
        SetEntityVelocity(smokingProp, 0.0, 0.0, -1.0)
        
        -- Удаляем проп в отдельном потоке
        local propToDelete = smokingProp
        CreateThread(function()
            Wait(2000)
            if DoesEntityExist(propToDelete) then
                DeleteObject(propToDelete)
            end
        end)
        smokingProp = nil
    end
    
    -- ВСЕГДА уведомляем сервер (чтобы очистить activeSmokers)
    TriggerServerEvent('hud:server:SmokingFinished', itemName, slot, completed)
    
    if completed then
        lib.notify({ 
            title = 'Курение', 
            description = 'Вы докурили', 
            type = 'success', 
            duration = 2000 
        })
        
        applySmokingEffectsInternal(smokingType, itemName)
    else
        lib.notify({ 
            title = 'Курение', 
            description = 'Вы выбросили', 
            type = 'inform', 
            duration = 2000 
        })
    end
    
    -- Сбрасываем ВСЁ состояние В КОНЦЕ
    currentSmokingType = nil
    currentSmokingItem = nil
    currentSmokingSlot = nil
    puffsRemaining = 0
    smokingStance = "c"
    isSmokingActive = false  -- ВАЖНО: в самом конце!
    
    print('[SMOKING] Finished and reset state - isSmokingActive: ' .. tostring(isSmokingActive))
end
-- ═══════════════════════════════════════════════════════════════
-- 12. НАЧАЛО КУРЕНИЯ (ГЛАВНАЯ ФУНКЦИЯ)
-- ═══════════════════════════════════════════════════════════════

local function startSmoking(smokingType, itemName, slot)
    print('[SMOKING] >>> startSmoking() called')
    print('[SMOKING] Type: ' .. tostring(smokingType))
    
    if isSmokingActive then
        lib.notify({ 
            title = 'Курение', 
            description = 'Вы уже курите', 
            type = 'error', 
            duration = 2000 
        })
        return false
    end
    
    local config = SMOKING_CONFIG[smokingType]
    if not config then
        print('[SMOKING] ERROR: Unknown type')
        return false
    end
    
    isSmokingActive = true
    currentSmokingType = smokingType
    currentSmokingItem = itemName
    currentSmokingSlot = slot
    puffsRemaining = config.puffs
    smokingStartTime = GetGameTimer()
    
    -- Начальная поза зависит от типа курения
    if smokingType == 'cigar' or smokingType == 'pipe' then
        smokingStance = "a"
    else
        smokingStance = "c"
    end
    
    -- Создаем проп
    if config.prop then
        smokingProp = createSmokingProp(smokingType)
        
        if not smokingProp then
            print('[SMOKING] Failed to create prop!')
            isSmokingActive = false
            return false
        end
        
        -- Анимация зажигания
        playLightingAnimation(smokingType, smokingProp)
    end
    
    -- Показываем промпты
    ShowSmokingPrompts()
    
    -- Запускаем основной цикл
    CreateThread(function()
        local ped = cache.ped
        local isPuffing = false
        
        while isSmokingActive and puffsRemaining > 0 do
            Wait(0)
            
            -- Обновляем текст промпта
            if SmokePuffPrompt then
                local puffStr = CreateVarString(10, 'LITERAL_STRING', 'Затяжка (' .. puffsRemaining .. ')')
                PromptSetText(SmokePuffPrompt, puffStr)
            end
            
            -- E - Затяжка
            if IsControlJustPressed(0, 0xCEFD9220) and not isPuffing then
                puffsRemaining = puffsRemaining - 1
                print('[SMOKING] Puff! Remaining: ' .. puffsRemaining)
                
                isPuffing = true
                
                -- Эффект "прихода" на КАЖДУЮ затяжку для косяков и набитых трубок (каждая продлевает длительность)
                if currentSmokingType == 'joint' or (currentSmokingItem and string.match(currentSmokingItem, '^loaded_pipe_')) then
                    local ok = pcall(function()
                        exports['rsg-weed']:ApplyHighEffect(1.0, true)
                    end)
                    if not ok then
                        AnimpostfxPlay('PlayerDrunk01')
                        CreateThread(function()
                            Wait(60000)
                            AnimpostfxStop('PlayerDrunk01')
                        end)
                        lib.notify({ title = 'Каннабис', description = 'Вы чувствуете расслабление...', type = 'success' })
                    end
                    -- 100% снятие стресса с каждой затяжки
                    updateNeed('stress', 100, true)
                end
                
                CreateThread(function()
                    playPuffAnimation()
                    isPuffing = false
                end)
                
                if puffsRemaining == 5 then
                    lib.notify({ 
                        title = 'Курение', 
                        description = 'Осталось 5 затяжек', 
                        type = 'warning', 
                        duration = 2000 
                    })
                elseif puffsRemaining == 1 then
                    lib.notify({ 
                        title = 'Курение', 
                        description = 'Последняя затяжка!', 
                        type = 'warning', 
                        duration = 2000 
                    })
                end
            end
            
            -- F - Выбросить
            if IsControlJustPressed(0, 0xB2F377E8) then
                print('[SMOKING] Dropped cigarette')
                finishSmoking(false)
                break
            end
            
            -- R - Сменить позу
            if IsControlJustPressed(0, 0xE30CD707) and not isPuffing then
                if not IsPedWalking(ped) and not IsPedRunning(ped) then
                    changeStance()
                end
            end
        end
        
        if isSmokingActive and puffsRemaining <= 0 then
            finishSmoking(true)
        end
    end)
    
    return true
end
-- ═══════════════════════════════════════════════════════════════
-- 13. СОБЫТИЯ
-- ═══════════════════════════════════════════════════════════════

RegisterNetEvent('hud:client:StartSmoking', function(smokingType, itemName, slot)
    print('[SMOKING] ========================================')
    print('[SMOKING] StartSmoking event received!')
    print('[SMOKING] Type: ' .. tostring(smokingType))
    print('[SMOKING] Item: ' .. tostring(itemName))
    print('[SMOKING] ========================================')
    
    startSmoking(smokingType, itemName, slot)
end)

RegisterNetEvent('hud:client:loadSmokingStats', function(stats)
    if stats then
        smokingStats.totalSmokesToday = stats.totalSmokesToday or 0
        smokingStats.totalSmokesWeek = stats.totalSmokesWeek or 0
        smokingStats.consecutiveSmokingDays = stats.consecutiveSmokingDays or 0
        smokingStats.lastSmokeTime = stats.lastSmokeTime or 0
        smokingStats.addictionLevel = stats.addictionLevel or 0
        smokingStats.lungHealth = stats.lungHealth or 100
        print('[SMOKING] Stats loaded')
    end
end)

RegisterNetEvent('hud:client:loadCannabisStats', function(dayCounts)
    if dayCounts and type(dayCounts) == 'table' then
        cannabisStats.dayCounts = dayCounts
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- 14. EXPORTS И КОМАНДЫ
-- ═══════════════════════════════════════════════════════════════

exports('IsSmoking', function()
    return isSmokingActive
end)

exports('GetPuffsRemaining', function()
    return puffsRemaining
end)

exports('CancelSmoking', function()
    if isSmokingActive then
        finishSmoking(false)
    end
end)

RegisterCommand('smokingstats', function()
    print('=== SMOKING STATS ===')
    print('Is smoking: ' .. tostring(isSmokingActive))
    print('Puffs remaining: ' .. puffsRemaining)
    print('Smokes today: ' .. smokingStats.totalSmokesToday)
    print('Lung health: ' .. smokingStats.lungHealth)
    print('=====================')
    
    lib.notify({ 
        title = 'Smoking Stats', 
        description = 'Puffs: ' .. puffsRemaining .. ' | Lungs: ' .. smokingStats.lungHealth .. '%',
        type = 'inform',
        duration = 5000
    })
end, false)

-- ═══════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════

RegisterCommand('smokingstats', function()
    print('=== SMOKING STATS ===')
    print('Smokes today: ' .. smokingStats.totalSmokesToday)
    print('Smokes week: ' .. smokingStats.totalSmokesWeek)
    print('Consecutive days: ' .. smokingStats.consecutiveSmokingDays)
    print('Addiction level: ' .. smokingStats.addictionLevel)
    print('Lung health: ' .. smokingStats.lungHealth)
    print('Is smoking: ' .. tostring(isSmokingActive))
    print('Puffs remaining: ' .. puffsRemaining)
    print('=====================')
    
    lib.notify({ 
        title = 'Smoking Stats', 
        description = 'Smokes: ' .. smokingStats.totalSmokesToday .. ' | Lungs: ' .. smokingStats.lungHealth .. '% | Puffs: ' .. puffsRemaining,
        type = 'inform',
        duration = 5000
    })
end, false)

RegisterCommand('resetsmoking', function()
    -- Полный сброс состояния курения
    isSmokingActive = false
    currentSmokingType = nil
    currentSmokingItem = nil
    currentSmokingSlot = nil
    puffsRemaining = 0
    smokingStance = "c"
    smokingEffectActive = false
    
    -- Удаляем проп если есть
    if smokingProp and DoesEntityExist(smokingProp) then
        DeleteObject(smokingProp)
        smokingProp = nil
    end
    
    -- Скрываем промпты
    HideSmokingPrompts()
    
    -- Очищаем анимации
    ClearPedTasks(cache.ped)
    
    -- Сбрасываем статистику курения
    smokingStats = {
        totalSmokesToday = 0,
        totalSmokesWeek = 0,
        consecutiveSmokingDays = 0,
        lastSmokeTime = 0,
        addictionLevel = 0,
        lungHealth = 100
    }
    TriggerServerEvent('hud:server:resetAllSmokingStats')
    
    lib.notify({ title = 'Reset', description = 'Курение полностью сброшено', type = 'success' })
    print('[SMOKING] Full reset completed - isSmokingActive: ' .. tostring(isSmokingActive))
end, false)

RegisterCommand('testsmoking', function(source, args)
    local smokingType = args[1] or 'cigarette'
    startSmoking(smokingType, 'test_' .. smokingType, 1)
end, false)
------------------------------------------------
-- gradual consumption system
------------------------------------------------
local function consumeItem(itemName)
    debugPrint('[HUD DEBUG] === consumeItem called ===')
    debugPrint('[HUD DEBUG] Item: ' .. itemName)
    debugPrint('[HUD DEBUG] isConsuming: ' .. tostring(isConsuming))
    debugPrint('[HUD DEBUG] isPlayingAnimation: ' .. tostring(isPlayingAnimation))
    
    if isConsuming or isPlayingAnimation then
        debugPrint('[HUD DEBUG] Already consuming/animating, aborting')
        lib.notify({ title = 'Вы уже что-то употребляете', type = 'inform', duration = 2000 })
        return
    end

    local itemConfig = Config.ConsumableItems[itemName]
    if not itemConfig then
        debugPrint('[HUD ERROR] Item "' .. itemName .. '" not found in Config.ConsumableItems')
        lib.notify({ title = 'Предмет не настроен: ' .. itemName, type = 'error', duration = 2000 })
        return
    end

    debugPrint('[HUD DEBUG] Item config found, starting consumption')
    debugPrint('[HUD DEBUG] - hunger: ' .. tostring(itemConfig.hunger))
    debugPrint('[HUD DEBUG] - thirst: ' .. tostring(itemConfig.thirst))
    debugPrint('[HUD DEBUG] - bladder: ' .. tostring(itemConfig.bladder))
    debugPrint('[HUD DEBUG] - stress: ' .. tostring(itemConfig.stress))
    debugPrint('[HUD DEBUG] - type: ' .. tostring(itemConfig.type))
    debugPrint('[HUD DEBUG] - prop: ' .. tostring(itemConfig.prop))
    debugPrint('[HUD DEBUG] - drunkLevel: ' .. tostring(itemConfig.drunkLevel))

    isConsuming = true
    
    local itemType = itemConfig.type or 'food'
    local propName = itemConfig.prop or 'p_bread04x'
    local animType = itemConfig.animType or itemType
    
    CreateThread(function()
        playConsumeAnimation(animType, propName)
    end)
    
    -- Добавляем еду в историю рациона
    addFoodToHistory(itemName)
    
    -- Получаем множитель эффективности
    local dietMultiplier = calculateFoodEffectiveness(itemName)

    if not Config.GradualConsumption then
        debugPrint('[HUD DEBUG] Using instant consumption')
        
        local duration = 5500
        
        CreateThread(function()
            Wait(duration)
            
            debugPrint('[HUD DEBUG] Applying instant effects with diet multiplier: ' .. string.format("%.2f", dietMultiplier))
            
            -- ★ shiw-lifestyle: Аскет — еда/вода восстанавливают меньше
            local lsFoodPenalty = 0
            pcall(function() lsFoodPenalty = exports['shiw-lifestyle']:GetFoodWaterPenalty() or 0 end)
            local foodWaterMult = (lsFoodPenalty > 0) and (1.0 - lsFoodPenalty) or 1.0
            
            if itemConfig.hunger and itemConfig.hunger ~= 0 then
                local adjustedHunger = itemConfig.hunger * dietMultiplier * foodWaterMult
                updateNeed('hunger', math.abs(adjustedHunger), adjustedHunger < 0)
            end
            if itemConfig.thirst and itemConfig.thirst ~= 0 then
                local adjustedThirst = itemConfig.thirst * foodWaterMult
                updateNeed('thirst', math.abs(adjustedThirst), adjustedThirst < 0)
            end
            if itemConfig.stress and itemConfig.stress ~= 0 then
                updateNeed('stress', math.abs(itemConfig.stress), itemConfig.stress < 0)
            end
            if itemConfig.bladder and itemConfig.bladder ~= 0 then
                local bladderValue = itemConfig.bladder
                if bladderValue > 0 then
                    local bladderMult = Config.BladderItemGainMultiplier or 1.0
                    bladderValue = bladderValue * bladderMult
                end
                updateNeed('bladder', math.abs(bladderValue), bladderValue < 0)
            end
            
            isConsuming = false
            isPlayingAnimation = false
            
            if itemConfig.type == 'alcohol' and itemConfig.drunkLevel then
                debugPrint('[HUD DEBUG] Applying drunk effects - Level: ' .. itemConfig.drunkLevel)
                applyDrunkEffects(itemConfig.drunkLevel)
            end
			-- Проверка на курительные предметы
			if itemConfig.type == 'smoking' and itemConfig.smokingType then
				debugPrint('[HUD DEBUG] Detected smoking item - Type: ' .. itemConfig.smokingType)
    
				-- Останавливаем обычную обработку
				isConsuming = false
    
				-- Запускаем систему курения
				TriggerServerEvent('hud:server:StartSmokingItem', itemName)
				return
			end
            debugPrint('[HUD DEBUG] Instant consumption complete!')
        end)
        
        return
    end

    debugPrint('[HUD DEBUG] Using gradual consumption with diet multiplier: ' .. string.format("%.2f", dietMultiplier))
    
    local ticksRemaining = Config.ConsumptionTicks
    
    -- ★ shiw-lifestyle: Аскет — еда/вода восстанавливают меньше
    local lsFoodPenalty2 = 0
    pcall(function() lsFoodPenalty2 = exports['shiw-lifestyle']:GetFoodWaterPenalty() or 0 end)
    local foodWaterMult2 = (lsFoodPenalty2 > 0) and (1.0 - lsFoodPenalty2) or 1.0
    
    -- Применяем множитель рациона к голоду + штраф lifestyle
    local hungerPerTick = ((itemConfig.hunger or 0) * dietMultiplier * foodWaterMult2) / Config.ConsumptionTicks
    local thirstPerTick = ((itemConfig.thirst or 0) * foodWaterMult2) / Config.ConsumptionTicks
    local stressPerTick = (itemConfig.stress or 0) / Config.ConsumptionTicks
    local baseBladder = itemConfig.bladder or 0
    if baseBladder > 0 then
        baseBladder = baseBladder * (Config.BladderItemGainMultiplier or 1.0)
    end
    local bladderPerTick = baseBladder / Config.ConsumptionTicks

    CreateThread(function()
        while ticksRemaining > 0 do
            Wait(Config.ConsumptionTickInterval)
            
            if hungerPerTick ~= 0 then
                updateNeed('hunger', math.abs(hungerPerTick), hungerPerTick < 0)
            end
            if thirstPerTick ~= 0 then
                updateNeed('thirst', math.abs(thirstPerTick), thirstPerTick < 0)
            end
            if stressPerTick ~= 0 then
                updateNeed('stress', math.abs(stressPerTick), stressPerTick < 0)
            end
            if bladderPerTick ~= 0 then
                updateNeed('bladder', math.abs(bladderPerTick), bladderPerTick < 0)
            end
            
            ticksRemaining = ticksRemaining - 1
        end
        
        isConsuming = false
        isPlayingAnimation = false
        
        if itemConfig.type == 'alcohol' and itemConfig.drunkLevel then
            debugPrint('[HUD DEBUG] Applying drunk effects - Level: ' .. itemConfig.drunkLevel)
            applyDrunkEffects(itemConfig.drunkLevel)
        end
        
        debugPrint('[HUD DEBUG] Gradual consumption complete!')
    end)
end

exports('ConsumeItem', consumeItem)
exports('ApplyDrunkEffects', applyDrunkEffects)
------------------------------------------------
-- consumption events
------------------------------------------------
RegisterNetEvent('hud:client:TryConsumeItem', function(itemName, slot)
    debugPrint('[HUD DEBUG] TryConsumeItem: ' .. itemName)
    
    if isConsuming or isPlayingAnimation then
        debugPrint('[HUD DEBUG] Already consuming/animating, cancelling')
        lib.notify({ title = 'Вы уже что-то употребляете', type = 'inform', duration = 2000 })
        TriggerEvent('hud:client:ConsumeItemFailed', 'Already consuming')
        return
    end
    
    local itemConfig = Config.ConsumableItems[itemName]
    if not itemConfig then
        debugPrint('[HUD ERROR] Item "' .. itemName .. '" not found in Config.ConsumableItems')
        lib.notify({ title = 'Предмет не настроен: ' .. itemName, type = 'error', duration = 2000 })
        TriggerEvent('hud:client:ConsumeItemFailed', 'Item not configured')
        return
    end
    
    debugPrint('[HUD DEBUG] All checks passed, confirming to server')
    TriggerServerEvent('hud:server:ConsumeItemConfirmed', itemName, slot)
end)

RegisterNetEvent('hud:client:ConsumeItemStart', function(itemName)
    debugPrint('[HUD DEBUG] ConsumeItemStart: ' .. itemName)
    consumeItem(itemName)
end)

RegisterNetEvent('hud:client:ConsumeItemFailed', function(reason)
    debugPrint('[HUD DEBUG] Consumption failed: ' .. (reason or 'Unknown reason'))
end)

RegisterNetEvent('hud:client:ConsumeItem', function(itemName)
    consumeItem(itemName)
end)

------------------------------------------------
-- pee command с эффектами частиц
------------------------------------------------
local isPeeing = false
local ptfxHandle = nil

-- Настройки частиц
local ptfxDict = "core"
local ptfxName = "liquid_leak_water"

-- Функция загрузки частиц (RedM версия)
local function loadPtfxDict(dict)
    RequestNamedPtfxAsset(GetHashKey(dict))
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(GetHashKey(dict)) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasNamedPtfxAssetLoaded(GetHashKey(dict))
end

-- Запуск частиц (RedM версия)
local function startPtfx()
    if not loadPtfxDict(ptfxDict) then
        debugPrint('[HUD DEBUG] Failed to load ptfx dict')
        return false
    end
    
    -- RedM использует UseParticleFxAsset, а не UseParticleFxAssetNextCall
    UseParticleFxAsset(ptfxDict)
    
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    
    ptfxHandle = StartParticleFxLoopedAtCoord(
        ptfxName, 
        coords.x, 
        coords.y, 
        coords.z - 0.3,
        0.0, 0.0, 0.0, 
        2.0,
        false, false, false, true
    )
    
    debugPrint('[HUD DEBUG] PTFX started, handle: ' .. tostring(ptfxHandle))
    
    return ptfxHandle ~= nil and ptfxHandle ~= 0
end

-- Остановка частиц
local function stopPtfx()
    if ptfxHandle then
        StopParticleFxLooped(ptfxHandle, false)
        ptfxHandle = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
-- СИСТЕМА ВРЕМЕННОГО СНЯТИЯ ОДЕЖДЫ ДЛЯ /PEE (ЖЕНЩИНЫ)
-- Интеграция с rsg-appearance (naked_body system)
-- ═══════════════════════════════════════════════════════════════

local savedClothingForPee = nil

-- Хеш компонента штанов/юбок
local PANTS_COMPONENT_HASH = 0x1D4C528A

-- Функция снятия штанов/юбки и применения голого тела
local function removeBottomClothingForPee(ped)
    local clothingData = {
        pantsHash = nil,
        skirtsHash = nil,
    }
    
    -- Пробуем получить hash штанов из rsg-appearance
    local success, result = pcall(function()
        return exports['rsg-appearance']:GetClothingCategoryHash('pants')
    end)
    if success and result and result ~= 0 then
        clothingData.pantsHash = result
        debugPrint('[HUD DEBUG] Сохранён hash штанов: ' .. tostring(result))
    end
    
    -- Пробуем получить hash юбки
    success, result = pcall(function()
        return exports['rsg-appearance']:GetClothingCategoryHash('skirts')
    end)
    if success and result and result ~= 0 then
        clothingData.skirtsHash = result
        debugPrint('[HUD DEBUG] Сохранён hash юбки: ' .. tostring(result))
    end
    
    -- Снимаем компонент штанов/юбки
    debugPrint('[HUD DEBUG] Снимаем штаны/юбку для /pee')
    Citizen.InvokeNative(0xD710A5007C2AC539, ped, PANTS_COMPONENT_HASH, 0) -- _REMOVE_PED_COMPONENT
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false) -- _UPDATE_PED_VARIATION
    
    Wait(100)
    
    -- Применяем голое тело снизу через rsg-appearance
    local nakedSuccess = pcall(function()
        exports['rsg-appearance']:ApplyNakedLowerBody(ped)
    end)
    
    if not nakedSuccess then
        -- Fallback: пробуем через событие
        TriggerEvent('rsg-appearance:applyNakedLower')
        debugPrint('[HUD DEBUG] Использован fallback для naked lower body')
    else
        debugPrint('[HUD DEBUG] Применено голое тело (lower) через export')
    end
    
    return clothingData
end

-- Функция восстановления: используем equipClothing из appearance (тот же путь при надевании штанов)
local function restoreBottomClothingAfterPee(ped, clothingData)
    RSGCore.Functions.TriggerCallback('rsg-clothing:server:getEquippedClothing', function(equippedItems)
        if not equippedItems then return end
        local lowerCats = {'pants', 'skirts', 'dresses'}
        for _, cat in ipairs(lowerCats) do
            if equippedItems[cat] and equippedItems[cat].hash and equippedItems[cat].hash ~= 0 then
                local data = equippedItems[cat]
                data.category = cat
                TriggerEvent('rsg-clothing:client:equipClothing', data)
                return
            end
        end
        -- Нет штанов/юбки/платья — только снимаем naked и загружаем всё
        pcall(function()
            exports['rsg-appearance']:RemoveNakedLowerBody(ped, true)
        end)
        Wait(100)
        pcall(function()
            exports['rsg-appearance']:LoadClothingFromInventory()
        end)
    end)
end

-- Основная функция
local function doPee()
    if isPeeing then
        lib.notify({ title = 'Вы уже справляете нужду', type = 'error', duration = 2000 })
        return
    end

    local bladderLevel = LocalPlayer.state.bladder or 0
    if bladderLevel < 20 then
        lib.notify({ title = 'Вам пока не нужно в туалет', type = 'inform', duration = 2000 })
        return
    end

    isPeeing = true
    
    local playerPed = cache.ped
    local isMale = IsPedMale(playerPed)
    
    debugPrint('[HUD DEBUG] Starting pee - IsMale: ' .. tostring(isMale))
    
    ClearPedTasks(playerPed)
    ClearPedSecondaryTask(playerPed)
    
    if isMale then
        -- ═══════════════════════════════════════
        -- МУЖСКОЙ СЦЕНАРИЙ (встроенные эффекты)
        -- ═══════════════════════════════════════
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_PEE", 0, true)
        
        lib.notify({ title = 'Справляете нужду...', type = 'inform', duration = 3000 })
        
        local animTime = 10000
        local startTime = GetGameTimer()
        
        CreateThread(function()
            while GetGameTimer() - startTime < animTime do
                Wait(100)
                
                if not IsPedUsingAnyScenario(playerPed) then
                    isPeeing = false
                    lib.notify({ title = 'Отменено', type = 'error', duration = 2000 })
                    return
                end
            end
            
            ClearPedTasks(playerPed)
            ClearPedSecondaryTask(playerPed)
            
            local newBladder = math.floor(bladderLevel * 0.5)
            LocalPlayer.state:set('bladder', newBladder, true)
            
            local currentStress = LocalPlayer.state.stress or 0
            local newStress = math.max(0, currentStress - 10)
            LocalPlayer.state:set('stress', newStress, true)
            
            lib.notify({ title = 'Вы справили нужду', type = 'success', duration = 2000 })
            
            isPeeing = false
        end)
    else
        -- ═══════════════════════════════════════
        -- ЖЕНСКАЯ АНИМАЦИЯ + ЧАСТИЦЫ + СНЯТИЕ ШТАНОВ + NAKED BODY
        -- ═══════════════════════════════════════
        local dict = "amb_camp@world_camp_fire_crouch_ground@male_a@base"
        local anim = "base"
        
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        
        if HasAnimDictLoaded(dict) then
            -- ═══════════════════════════════════════
            -- СНИМАЕМ ШТАНЫ/ЮБКУ + ПРИМЕНЯЕМ NAKED LOWER BODY
            -- ═══════════════════════════════════════
            savedClothingForPee = removeBottomClothingForPee(playerPed)
            
            Wait(250) -- Даём время на применение изменений
            
            TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
            
            lib.notify({ title = 'Справляете нужду...', type = 'inform', duration = 3000 })
            
            CreateThread(function()
                -- Ждём начало анимации, потом запускаем частицы
                Wait(1500)
                
                if isPeeing then
                    startPtfx()
                end
                
                -- Обновляем позицию частиц, пока идёт анимация
                local animTime = 8500  -- Оставшееся время (10000 - 1500)
                local startTime = GetGameTimer()
                
                while GetGameTimer() - startTime < animTime and isPeeing do
                    Wait(100)
                    
                    -- Проверка отмены
                    if not IsEntityPlayingAnim(playerPed, dict, anim, 3) then
                        stopPtfx()
                        
                        -- ═══════════════════════════════════════
                        -- ВОССТАНАВЛИВАЕМ ОДЕЖДУ ПРИ ОТМЕНЕ
                        -- ═══════════════════════════════════════
                        restoreBottomClothingAfterPee(playerPed, savedClothingForPee)
                        savedClothingForPee = nil
                        
                        isPeeing = false
                        lib.notify({ title = 'Отменено', type = 'error', duration = 2000 })
                        return
                    end
                    
                    -- Обновляем позицию частиц (если персонаж двигается)
                    if ptfxHandle then
                        local coords = GetEntityCoords(playerPed)
                        SetParticleFxLoopedOffsets(ptfxHandle, coords.x, coords.y, coords.z - 0.5, 0.0, 0.0, 0.0)
                    end
                end
                
                -- Останавливаем частицы
                stopPtfx()
                
                Wait(500)
                
                ClearPedTasks(playerPed)
                ClearPedSecondaryTask(playerPed)
                
                -- ═══════════════════════════════════════
                -- ВОССТАНАВЛИВАЕМ ОДЕЖДУ ПОСЛЕ ЗАВЕРШЕНИЯ
                -- ═══════════════════════════════════════
                Wait(300)
                
                restoreBottomClothingAfterPee(playerPed, savedClothingForPee)
                savedClothingForPee = nil
                
                local newBladder = math.floor(bladderLevel * 0.5)
            LocalPlayer.state:set('bladder', newBladder, true)
                
                local currentStress = LocalPlayer.state.stress or 0
                local newStress = math.max(0, currentStress - 10)
                LocalPlayer.state:set('stress', newStress, true)
                
                lib.notify({ title = 'Вы справили нужду', type = 'success', duration = 2000 })
                
                RemoveAnimDict(dict)
                isPeeing = false
            end)
        else
            isPeeing = false
            lib.notify({ title = 'Ошибка анимации', type = 'error', duration = 2000 })
        end
    end
end

RegisterCommand('pee', function()
    doPee()
end, false)

exports('DoPee', doPee)

-- ═══════════════════════════════════════════════════════════════
-- DoPoo: справление большой нужды (сидячая анимация, снять штаны)
-- После завершения: loadcharacter, spawn p_wolfpoop03x на 2 мин
-- ═══════════════════════════════════════════════════════════════

local isPooing = false
local POOP_PROP = `p_wolfpoop03x`
local POOP_DURATION_MS = 120000 -- 2 минуты

local function doPoo(skipBladderCheck)
    if isPooing then
        lib.notify({ title = 'Вы уже этим занимаетесь', type = 'error', duration = 2000 })
        return
    end
    if not skipBladderCheck then
        local bladderLevel = LocalPlayer.state.bladder or 0
        if bladderLevel < 20 then
            lib.notify({ title = 'Вам пока не нужно', type = 'inform', duration = 2000 })
            return
        end
    end

    isPooing = true
    local playerPed = cache.ped
    local savedClothing = removeBottomClothingForPee(playerPed)

    local dict = "amb_camp@world_camp_fire_crouch_ground@male_a@base"
    local anim = "base"
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasAnimDictLoaded(dict) then
        isPooing = false
        lib.notify({ title = 'Ошибка анимации', type = 'error', duration = 2000 })
        return
    end

    ClearPedTasks(playerPed)
    TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    lib.notify({ title = 'Справляете нужду...', type = 'inform', duration = 5000 })

    CreateThread(function()
        local animTime = 12000
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < animTime and isPooing do
            Wait(100)
            if not IsEntityPlayingAnim(playerPed, dict, anim, 3) then
                break
            end
        end

        ClearPedTasks(playerPed)
        restoreBottomClothingAfterPee(playerPed, savedClothing)
        RemoveAnimDict(dict)
        isPooing = false

        -- ★ Сброс bladder на 0
        LocalPlayer.state:set('bladder', 0, true)


        local coords = GetEntityCoords(playerPed)
        local groundZ = coords.z
        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
        if found then groundZ = z end

        local poopObj = CreateObject(POOP_PROP, coords.x, coords.y, groundZ, false, false, false)
        if DoesEntityExist(poopObj) then
            PlaceObjectOnGroundProperly(poopObj)
            SetEntityAsMissionEntity(poopObj, true, true)
            SetTimeout(POOP_DURATION_MS, function()
                if DoesEntityExist(poopObj) then
                    DeleteObject(poopObj)
                end
            end)
        end

        lib.notify({ title = 'Готово', type = 'success', duration = 2000 })
    end)
end

RegisterCommand('poo', function()
    doPoo(false)
end, false)

exports('DoPoo', doPoo)

-- DoPooToilet: для унитаза (ox_target / shiw-toilet) — сидит на координатах, без спавна какашки
function DoPooToilet(seatCoords)
    if isPooing then
        lib.notify({ title = 'Вы уже этим занимаетесь', type = 'error', duration = 2000 })
        return
    end
    local bladderLevel = LocalPlayer.state.bladder or 0
    if bladderLevel < 20 then
        lib.notify({ title = 'Вам пока не нужно', type = 'inform', duration = 2000 })
        return
    end

    if not seatCoords or not seatCoords.x then
        lib.notify({ title = 'Ошибка координат', type = 'error', duration = 2000 })
        return
    end

    isPooing = true
    local playerPed = cache.ped
    local prevCoords = GetEntityCoords(playerPed)
    local prevHeading = GetEntityHeading(playerPed)

    local savedClothing = removeBottomClothingForPee(playerPed)
    local x, y, z = seatCoords.x, seatCoords.y, seatCoords.z
    local h = seatCoords.w or seatCoords.heading or 0.0

    -- Как в spooni_interactions: ClearPedTasksImmediately + FreezeEntityPosition перед сценарием
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, true)
    -- PROP_HUMAN_SEAT_CHAIR — основной сценарий для стульев в spooni (WORLD_HUMAN_SIT_CHAIR часто не срабатывает)
    local scenarioHash = joaat('PROP_HUMAN_SEAT_CHAIR')
    if scenarioHash == 0 then
        scenarioHash = joaat('GENERIC_SEAT_BENCH_SCENARIO')
    end
    TaskStartScenarioAtPosition(playerPed, scenarioHash, x, y, z, h, -1, false, true)

    lib.notify({ title = 'Справляете нужду...', type = 'inform', duration = 5000 })

    CreateThread(function()
        Wait(12000)
        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)
        restoreBottomClothingAfterPee(playerPed, savedClothing)
        isPooing = false

        local newBladder = math.floor(bladderLevel * 0.5)
        LocalPlayer.state:set('bladder', newBladder, true)
        lib.notify({ title = 'Готово', type = 'success', duration = 2000 })
    end)
end
exports('DoPooToilet', DoPooToilet)


------------------------------------------------
-- Water Cleansing System
------------------------------------------------
local function isPlayerInWater()
    local ped = cache.ped
    
    -- Используем ТОЛЬКО методы плавания
    local method1 = Citizen.InvokeNative(0x5BA7919BED300023, ped, 1.0)
    local method2 = IsPedSwimming(ped)
    local method3 = IsPedSwimmingUnderWater(ped)
    
    local result = method1 or method2 or method3
    
    if result then
        debugPrint('[HUD DEBUG] Water detected! Swimming/InWater: true')
    end
    
    return result
end

CreateThread(function()
    while true do
        Wait(1000)
        
        if LocalPlayer.state.isLoggedIn then
            local ped = cache.ped
            local inWaterNow = isPlayerInWater()
            
            if inWaterNow then
                if not isInWater then
                    isInWater = true
                    waterCleansingActive = true
                    
                    debugPrint('[HUD DEBUG] *** ENTERED WATER - STARTING CLEANSING ***')
                    
                    if is_particle_effect_active then
                        if current_ptfx_handle_id then
                            if Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                                Citizen.InvokeNative(0x459598F579C98929, current_ptfx_handle_id, false)
                            end
                        end
                        current_ptfx_handle_id = false
                        is_particle_effect_active = false
                    end
                end
                
                local currentTime = GetGameTimer()
                if currentTime - lastWaterCheck >= 2000 then
                    lastWaterCheck = currentTime
                    
                    local currentCleanliness = LocalPlayer.state.cleanliness or 100
                    
                    debugPrint('[HUD DEBUG] Water cleansing - Current cleanliness: ' .. currentCleanliness)
                    
                    local cleanAmount = 3
                    
                    if currentCleanliness < 100 then
                        local newCleanliness = math.min(100, currentCleanliness + cleanAmount)
                        LocalPlayer.state:set('cleanliness', newCleanliness, true)
                        
                        debugPrint('[HUD DEBUG] Cleanliness updated to: ' .. newCleanliness)
                        
                        Citizen.InvokeNative(0x7F5D88333EE8A86F, ped, 1)
                        Citizen.InvokeNative(0x6585D955A68452A5, ped)
                        Citizen.InvokeNative(0x9C720776DAA43E7E, ped, 0)
                        Citizen.InvokeNative(0x8FE22675A5A45817, ped, 0, 0, 0, 0)
                    else
                        debugPrint('[HUD DEBUG] Cleanliness already at 100%')
                    end
                end
            else
                if isInWater then
                    isInWater = false
                    waterCleansingActive = false
                    
                    debugPrint('[HUD DEBUG] *** LEFT WATER ***')
                    
                    local currentCleanliness = LocalPlayer.state.cleanliness or 100
                    if currentCleanliness > 60 then
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    repeat Wait(100) until LocalPlayer.state.isLoggedIn
    
    while true do
        Wait(20000)
        
        local playerData = RSGCore.Functions.GetPlayerData()
        
        if LocalPlayer.state.isLoggedIn and not playerData.metadata['isdead'] then
            if not LocalPlayer.state.isBathingActive and not isInWater then
                updateNeed('cleanliness', 0.3, true)
                debugPrint('[HUD DEBUG] Cleanliness decreased by 1')
            end
        end
    end
end)

------------------------------------------------
-- Bathing Integration (с раздеванием/одеванием)
------------------------------------------------

local savedClothesBeforeBath = nil
local isBathingNaked = false

-- Все категории MetaPed для полного раздевания
local allClothingCategories = {
    'hats', 'eyewear', 'masks', 'neckwear',
    'shirts_full', 'vests', 'coats', 'coats_closed',
    'suspenders', 'cloaks', 'ponchos',
    'pants', 'skirts', 'dresses', 'chaps',
    'boots', 'spurs',
    'gloves', 'gunbelts', 'satchels', 'belts',
}

-- Хеши MetaPed компонентов для прямого удаления
local bathMetaPedComponents = {
    ['hats'] = 0x9925C067,
    ['shirts_full'] = 0x2026C46D,
    ['pants'] = 0x1D4C528A,
    ['boots'] = 0x777EC6EF,
    ['vests'] = 0x485EE834,
    ['coats'] = 0xE06D30CE,
    ['coats_closed'] = 0x662AC34,
    ['gloves'] = 0xEABE0032,
    ['neckwear'] = 0x7A96FACA,
    ['masks'] = 0x7505EF42,
    ['eyewear'] = 0x5F1BE9EC,
    ['gunbelts'] = 0xF1542D11,
    ['satchels'] = 0x94504D26,
    ['suspenders'] = 0x877A2CF7,
    ['chaps'] = 0x3107499B,
    ['spurs'] = 0x18729F39,
    ['cloaks'] = 0x3C1A74CD,
    ['ponchos'] = 0xAF14310B,
    ['skirts'] = 0xA0E3AB7F,
    ['belts'] = 0xA6D134C6,
    ['dresses'] = 0x0662AC34,
}

-- Функция раздевания для ванны
local function undressForBath(ped)
    debugPrint('[HUD DEBUG] Раздеваемся для купания...')
    
    -- Шаг 1: Сохраняем текущую одежду через rsg-appearance export
    local success, clothesCache = pcall(function()
        return exports['rsg-appearance']:GetClothesCache()
    end)
    
    if success and clothesCache and next(clothesCache) then
        savedClothesBeforeBath = {}
        for category, data in pairs(clothesCache) do
            if data and type(data) == 'table' then
                savedClothesBeforeBath[category] = {
                    hash = data.hash,
                    model = data.model,
                    texture = data.texture,
                    palette = data.palette,
                    tints = data.tints,
                    kaf = data.kaf,
                    draw = data.draw,
                    albedo = data.albedo,
                    normal = data.normal,
                    material = data.material,
                }
            end
        end
        local savedCount = 0
        for _ in pairs(savedClothesBeforeBath) do savedCount = savedCount + 1 end
        debugPrint('[HUD DEBUG] Сохранено категорий одежды: ' .. tostring(savedCount))
    else
        debugPrint('[HUD DEBUG] Не удалось получить ClothesCache, сохраняем пустой')
        savedClothesBeforeBath = {}
    end
    
    -- Шаг 2: Снимаем ВСЮ одежду через MetaPed (нативное удаление каждой категории)
    for _, category in ipairs(allClothingCategories) do
        -- Удаляем по имени категории
        Citizen.InvokeNative(0xD710A5007C2AC539, ped, GetHashKey(category), 0)
        -- Удаляем по MetaPed хешу
        if bathMetaPedComponents[category] then
            Citizen.InvokeNative(0xD710A5007C2AC539, ped, bathMetaPedComponents[category], 0)
        end
    end
    
    -- Финализация удаления
    Citizen.InvokeNative(0x704C908E9C405136, ped)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
    
    -- Ждём завершения обновления визуала
    local t = 0
    while not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped) and t < 50 do Wait(10) t = t + 1 end
    Wait(100)
    
    -- Шаг 3: Применяем голое тело через имеющиеся экспорты rsg-appearance
    local nakedLowerOk = pcall(function()
        exports['rsg-appearance']:ApplyNakedLowerBody(ped)
    end)
    debugPrint('[HUD DEBUG] Naked lower body: ' .. tostring(nakedLowerOk))
    
    Wait(100)
    
    -- Верхнюю часть голого тела применяем только для женщин (для мужчин экспорт вернёт false)
    local nakedUpperOk = pcall(function()
        exports['rsg-appearance']:ApplyNakedUpperBody(ped)
    end)
    debugPrint('[HUD DEBUG] Naked upper body: ' .. tostring(nakedUpperOk))
    
    -- Переприменяем морф тела (чтобы телосложение сохранилось)
    pcall(function()
        exports['rsg-appearance']:ReapplyBodyMorph(ped)
    end)
    
    isBathingNaked = true
    debugPrint('[HUD DEBUG] Раздевание для купания завершено')
end

-- Функция одевания после ванны
local function dressAfterBath(ped)
    debugPrint('[HUD DEBUG] Одеваемся после купания...')
    
    -- Шаг 1: Убираем naked body оверлеи
    pcall(function()
        exports['rsg-appearance']:RemoveNakedLowerBody(ped)
    end)
    pcall(function()
        exports['rsg-appearance']:RemoveNakedUpperBody(ped)
    end)
    
    Wait(100)
    
    -- Шаг 2: Загружаем одежду из инвентаря (экипированные предметы)
    local loadSuccess = pcall(function()
        exports['rsg-appearance']:LoadClothingFromInventory(function(success, count)
            debugPrint('[HUD DEBUG] LoadClothingFromInventory result: ' .. tostring(success) .. ', items: ' .. tostring(count or 0))
        end)
    end)
    
    if not loadSuccess then
        -- Фоллбэк: если экспорт не сработал, используем /loadcharacter
        debugPrint('[HUD DEBUG] Fallback: используем /loadcharacter')
        ExecuteCommand('loadcharacter')
    end
    
    savedClothesBeforeBath = nil
    isBathingNaked = false
    
    debugPrint('[HUD DEBUG] Одевание после купания завершено')
end

RegisterNetEvent('hud:client:StartBathing', function(bathType)
    debugPrint('[HUD DEBUG] Starting bathing: ' .. (bathType or 'default'))
    
    if is_particle_effect_active then
        if current_ptfx_handle_id then
            if Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                Citizen.InvokeNative(0x459598F579C98929, current_ptfx_handle_id, false)
            end
        end
        current_ptfx_handle_id = false
        is_particle_effect_active = false
    end
    
    LocalPlayer.state:set('isBathingActive', true, true)
    
    -- ═══════════════════════════════════════
    -- РАЗДЕВАЕМСЯ ПРИ ВХОДЕ В ВАННУ
    -- ═══════════════════════════════════════
    local playerPed = cache.ped
    undressForBath(playerPed)
    
    CreateThread(function()
        local cleaningRate = 3
        local maxCleanliness = 100
        
        while LocalPlayer.state.isBathingActive do
            Wait(1000)
            
            local currentCleanliness = LocalPlayer.state.cleanliness or 100
            if currentCleanliness < maxCleanliness then
                local newCleanliness = math.min(maxCleanliness, currentCleanliness + cleaningRate)
                LocalPlayer.state:set('cleanliness', newCleanliness, true)
                
                Citizen.InvokeNative(0x7F5D88333EE8A86F, cache.ped, 1)
                Citizen.InvokeNative(0x6585D955A68452A5, cache.ped)
                Citizen.InvokeNative(0x9C720776DAA43E7E, cache.ped, 0)
                Citizen.InvokeNative(0x8FE22675A5A45817, cache.ped, 0, 0, 0, 0)
            end
        end
    end)
end)

RegisterNetEvent('hud:client:StopBathing', function()
    debugPrint('[HUD DEBUG] Stopping bathing')
    
    LocalPlayer.state:set('isBathingActive', false, true)
    
    -- Финальная визуальная очистка
    Citizen.InvokeNative(0x7F5D88333EE8A86F, cache.ped, 1)
    Citizen.InvokeNative(0x6585D955A68452A5, cache.ped)
    Citizen.InvokeNative(0x9C720776DAA43E7E, cache.ped, 0)
    Citizen.InvokeNative(0x8FE22675A5A45817, cache.ped, 0, 0, 0, 0)
    
    local currentCleanliness = LocalPlayer.state.cleanliness or 100
    
    -- ═══════════════════════════════════════
    -- ОДЕВАЕМСЯ ПРИ ВЫХОДЕ ИЗ ВАННЫ
    -- ═══════════════════════════════════════
    local playerPed = cache.ped
    
    -- Небольшая задержка перед одеванием (для плавности)
    SetTimeout(500, function()
        dressAfterBath(playerPed)
    end)
end)

exports('StartBathing', function(bathType)
    TriggerEvent('hud:client:StartBathing', bathType)
end)

exports('StopBathing', function()
    TriggerEvent('hud:client:StopBathing')
end)

-- Экспорт для проверки состояния купания
exports('IsBathingNaked', function()
    return isBathingNaked
end)

exports('GetSavedBathClothes', function()
    return savedClothesBeforeBath
end)

CreateThread(function()
    Wait(1000)
    sendLocalesToNUI()
end)

------------------------------------------------
-- initialize player state on login
------------------------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    if LocalPlayer.state.bladder == nil then
        LocalPlayer.state:set('bladder', 0, true)
    end
    if LocalPlayer.state.hunger == nil then
        LocalPlayer.state:set('hunger', 100, true)
    end
    if LocalPlayer.state.thirst == nil then
        LocalPlayer.state:set('thirst', 100, true)
    end
    if LocalPlayer.state.stress == nil then
        LocalPlayer.state:set('stress', 0, true)
    end
    if LocalPlayer.state.cleanliness == nil then
        LocalPlayer.state:set('cleanliness', 100, true)
    end
	TriggerServerEvent('hud:server:loadAlcoholStats')
	TriggerServerEvent('hud:server:loadSmokingStats')
	TriggerServerEvent('hud:server:loadCannabisStats')
	TriggerServerEvent('hud:server:loadDietStats')
end)
RegisterCommand('smokingstats', function()
    print('=== SMOKING STATS ===')
    print('Smokes today: ' .. smokingStats.totalSmokesToday)
    print('Smokes week: ' .. smokingStats.totalSmokesWeek)
    print('Consecutive days: ' .. smokingStats.consecutiveSmokingDays)
    print('Addiction level: ' .. smokingStats.addictionLevel)
    print('Lung health: ' .. smokingStats.lungHealth)
    print('Is smoking: ' .. tostring(isSmoking))
    print('=====================')
    
    lib.notify({ 
        title = 'Smoking Stats', 
        description = 'Smokes: ' .. smokingStats.totalSmokesToday .. ' | Lungs: ' .. smokingStats.lungHealth .. '%',
        type = 'inform',
        duration = 5000
    })
end, false)

RegisterNetEvent("HideAllUI")
AddEventHandler("HideAllUI", function()
    showUI = not showUI
end)
RegisterNetEvent('hud:client:SmokingEffect', function(smokingType)
    debugPrint('[HUD DEBUG] SmokingEffect received: ' .. smokingType)
    applySmokingEffects(smokingType)
end)
CreateThread(function()
    while true do
        Wait(0)
        if isPeeing then
            Citizen.InvokeNative(0x8509B634FBE7DA11, "INPUT_CONTEXT_X")
            Citizen.InvokeNative(0x0C38B1B2E6B23E2E, "Press ~INPUT_CONTEXT_X~ to cancel")
            Citizen.InvokeNative(0xCD51CB87417C2CC0)
            
            if IsControlJustPressed(0, 0x8FD015D8) then
                ClearPedTasks(cache.ped)
                ClearPedSecondaryTask(cache.ped)
                Citizen.InvokeNative(0xD2A207EEBDF9889B, cache.ped, 0)
                isPeeing = false
                lib.notify({ title = 'Отменено', type = 'error', duration = 2000 })
            end
        else
            Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    if Config.HidePlayerHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 4, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 5, 2)
    end
    if Config.HidePlayerStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 0, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 1, 2)
    end
    if Config.HidePlayerDeadEyeNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 2, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 3, 2)
    end
    if Config.HideHorseHealthNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 6, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 7, 2)
    end
    if Config.HideHorseStaminaNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 8, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 9, 2)
    end
    if Config.HideHorseCourageNative then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 10, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 11, 2)
    end
    if Config.HideAmmoHUD then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 12, 2)
        Citizen.InvokeNative(0xC116E6DF68DCE667, 13, 2)
    end
end)

local function updateStress(amount, isGain)
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        if not PlayerData.metadata['isdead'] and (isGain or PlayerData.job.type ~= 'leo') then
            local currentStress = LocalPlayer.state.stress or 0
            local newStress = currentStress + (isGain and amount or -amount)
            newStress = lib.math.clamp(newStress, 0, 100)
            LocalPlayer.state:set('stress', lib.math.round(newStress, 2), true)
            local title = isGain and 'Вы испытываете стресс' or 'Вы расслабились'
            lib.notify({ title = title, type = 'inform', duration = 5000 })
        end
    end)
end

local function GetShakeIntensity(stresslevel)
    local retval = 0.05
    for _, v in pairs(Config.Intensity['shake']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.intensity
            break
        end
    end
    return retval
end

local function GetEffectInterval(stresslevel)
    local retval = 60000
    for _, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.timeout
            break
        end
    end
    return retval
end

local current_ptfx_handle_id = false
local is_particle_effect_active = false

local FliesSpawn = function (clean)
    if LocalPlayer.state.isBathingActive or isInWater then
        if is_particle_effect_active then
            if current_ptfx_handle_id then
                if Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                    Citizen.InvokeNative(0x459598F579C98929, current_ptfx_handle_id, false) 
                end
            end
            current_ptfx_handle_id = false
            is_particle_effect_active = false
        end
        return
    end

    local new_ptfx_dictionary = "scr_mg_cleaning_stalls"
    local new_ptfx_name = "scr_mg_stalls_manure_flies"
    local current_ptfx_dictionary = new_ptfx_dictionary
    local current_ptfx_name = new_ptfx_name
    local bone_index = IsPedMale(cache.ped) and 413 or 464
    local ptfx_offcet_x = 0.2
    local ptfx_offcet_y = 0.0
    local ptfx_offcet_z = -0.4
    local ptfx_rot_x = 0.0
    local ptfx_rot_y = 0.0
    local ptfx_rot_z = 0.0
    local ptfx_scale = 1.0
    local ptfx_axis_x = 0
    local ptfx_axis_y = 0
    local ptfx_axis_z = 0

    if not is_particle_effect_active and clean < Config.MinCleanliness then
        current_ptfx_dictionary = new_ptfx_dictionary
        current_ptfx_name = new_ptfx_name
         if not Citizen.InvokeNative(0x65BB72F29138F5D6, joaat(current_ptfx_dictionary)) then
             Citizen.InvokeNative(0xF2B2353BBC0D4E8F, joaat(current_ptfx_dictionary))
             local counter = 0
             while not Citizen.InvokeNative(0x65BB72F29138F5D6, joaat(current_ptfx_dictionary)) and counter <= 300 do
                 Citizen.Wait(0)
             end
         end
         if Citizen.InvokeNative(0x65BB72F29138F5D6, joaat(current_ptfx_dictionary)) then
            Citizen.InvokeNative(0xA10DB07FC234DD12, current_ptfx_dictionary)
            current_ptfx_handle_id = Citizen.InvokeNative(0x9C56621462FFE7A6,current_ptfx_name,PlayerPedId(),ptfx_offcet_x,ptfx_offcet_y,ptfx_offcet_z,ptfx_rot_x,ptfx_rot_y,ptfx_rot_z,bone_index,ptfx_scale,ptfx_axis_x,ptfx_axis_y,ptfx_axis_z)
            is_particle_effect_active = true
        else
            print("cant load ptfx dictionary!")
        end
    elseif is_particle_effect_active and clean >= Config.MinCleanliness then
        if current_ptfx_handle_id then
            if Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                Citizen.InvokeNative(0x459598F579C98929, current_ptfx_handle_id, false)
            end
        end
        current_ptfx_handle_id = false
        is_particle_effect_active = false
    elseif is_particle_effect_active then
        if current_ptfx_handle_id then
            if not Citizen.InvokeNative(0x9DD5AFF561E88F2A, current_ptfx_handle_id) then
                current_ptfx_handle_id = false
                is_particle_effect_active = false
            end
        end
    end
end

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst, newCleanliness, newBladder)
    local cleanStats = Citizen.InvokeNative(0x147149F2E909323C, cache.ped, 16, Citizen.ResultAsInteger())
    updateNeed('hunger', newHunger)
    updateNeed('thirst', newThirst)
    updateNeed('cleanliness', newCleanliness - cleanStats)
    updateNeed('bladder', newBladder or 0)
end)

RegisterNetEvent('hud:client:UpdateHunger', function(newHunger)
    updateNeed('hunger', newHunger)
end)

RegisterNetEvent('hud:client:UpdateThirst', function(newThirst)
    updateNeed('thirst', newThirst)
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress)
    updateNeed('stress', newStress)
end)

RegisterNetEvent('hud:client:UpdateCleanliness', function(newCleanliness)
    local cleanStats = Citizen.InvokeNative(0x147149F2E909323C, cache.ped, 16, Citizen.ResultAsInteger())
    updateNeed('cleanliness', newCleanliness - cleanStats)
end)

RegisterNetEvent('hud:client:UpdateBladder', function(newBladder)
    updateNeed('bladder', newBladder)
end)

CreateThread(function()
    while true do
        Wait(30000)
        RSGCore.Functions.TriggerCallback('hud:server:getoutlawstatus', function(result)
            outlawstatus = result[1].outlawstatus
        end)
    end
end)

exports('GetOutlawStatus', function()
    return outlawstatus
end)

local function sendHudTick()
    if not LocalPlayer.state.isLoggedIn then
        SendNUIMessage({ action = 'hudtick', show = false })
        return
    end
    local isNuiOpen = IsNuiFocused()
    local show = isNuiOpen or (showUI and not IsCinematicCamRendering() and not LocalPlayer.state.inClothingStore)
    if IsPauseMenuActive() and not isNuiOpen then show = false end

    local stamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x0FF421E467373FCF, cache.playerId, Citizen.ResultAsFloat())))
    local mounted = IsPedOnMount(cache.ped)
    local voice = 0
    local talking = false
    if MumbleIsPlayerTalking then
        talking = (MumbleIsPlayerTalking(PlayerId()) == 1)
    else
        talking = Citizen.InvokeNative(0x33EEF97F, cache.playerId)
    end
    if LocalPlayer.state['proximity'] then
        voice = LocalPlayer.state['proximity'].distance or 0
    end

    local horsehealth, horsestamina, horseclean = 0, 0, 0
    if mounted then
        local horse = GetMount(cache.ped)
        local maxHealth = Citizen.InvokeNative(0x4700A416E8324EF3, horse, Citizen.ResultAsInteger())
        local maxStamina = Citizen.InvokeNative(0xCB42AFE2B613EE55, horse, Citizen.ResultAsFloat())
        local horseCleanliness = Citizen.InvokeNative(0x147149F2E909323C, horse, 16, Citizen.ResultAsInteger())
        horseclean = (horseCleanliness == 0) and 100 or (100 - horseCleanliness)
        horsehealth = tonumber(string.format("%.2f", Citizen.InvokeNative(0x82368787EA73C0F7, horse) / maxHealth * 100))
        horsestamina = tonumber(string.format("%.2f", Citizen.InvokeNative(0x775A1CA7893AA8B5, horse, Citizen.ResultAsFloat()) / maxStamina * 100))
    end

    SendNUIMessage({
        action = 'hudtick',
        show = show,
        inventoryOpen = IsNuiFocused(),
        health = GetEntityHealth(cache.ped) / 6,
        stamina = stamina,
        armor = Citizen.InvokeNative(0x2CE311A7, cache.ped),
        thirst = LocalPlayer.state.thirst or 100,
        hunger = LocalPlayer.state.hunger or 100,
        bladder = LocalPlayer.state.bladder or 0,
        cleanliness = LocalPlayer.state.cleanliness or 100,
        stress = LocalPlayer.state.stress or 0,
        talking = talking,
        temp = temperature,
        tempValue = temp,
        onHorse = mounted,
        horsehealth = horsehealth,
        horsestamina = horsestamina,
        horseclean = horseclean,
        voice = voice,
        voiceAlwaysVisible = Config.VoiceAlwaysVisible,
        youhavemail = (LocalPlayer.state.telegramUnreadMessages or 0) > 0,
        outlawstatus = outlawstatus,
        iconColors = Config.IconColors,
        logoConfig = {
            show = Config.ShowLogo or false,
            image = Config.LogoImage or '',
            size = Config.LogoSize or 150,
            opacity = Config.LogoOpacity or 0.8,
            position = Config.LogoPosition or { top = '20px', right = '20px' }
        }
    })
end

AddEventHandler('mumbleConnected', function()
    for _ = 1, 5 do
        sendHudTick()
        Wait(100)
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        sendHudTick()
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local isMounted = IsPedOnMount(cache.ped) or IsPedInAnyVehicle(cache.ped)

        if isMounted or LocalPlayer.state.telegramIsBirdPostApproaching then
            if Config.MountMinimap and showUI then
                if Config.MountCompass then
                    SetMinimapType(3)
                else
                    SetMinimapType(1)
                end
            else
                SetMinimapType(0)
            end
        else
            if Config.OnFootMinimap and showUI then
                SetMinimapType(1)
                if GetInteriorFromEntity(cache.ped) ~= 0 then
                    SetRadarConfigType(0xDF5DB58C, 0)
                else
                    SetRadarConfigType(0x25B517BF, 0)
                end
            else
                if Config.OnFootCompass and showUI then
                    SetMinimapType(3)
                else
                    SetMinimapType(0)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local coords = GetEntityCoords(cache.ped)
        
        if Config.TempFeature then
            local hat = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x9925C067)
            local shirt = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x2026C46D)
            local pants = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x1D4C528A)
            local boots = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x777EC6EF)
            local coat = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0xE06D30CE)
            local opencoat = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x662AC34)
            local gloves = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0xEABE0032)
            local vest = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x485EE834)
            local poncho = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0xAF14310B)
            local skirts = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0xA0E3AB7F)
            local chaps = Citizen.InvokeNative(0xFB4891BD7578CDC1, cache.ped, 0x3107499B)

            local what = hat == 1 and Config.WearingHat or 0
            local wshirt = shirt == 1 and Config.WearingShirt or 0
            local wpants = pants == 1 and Config.WearingPants or 0
            local wboots = boots == 1 and Config.WearingBoots or 0
            local wcoat = coat == 1 and Config.WearingCoat or 0
            local wopencoat = opencoat == 1 and Config.WearingOpenCoat or 0
            local wgloves = gloves == 1 and Config.WearingGloves or 0
            local wvest = vest == 1 and Config.WearingVest or 0
            local wponcho = poncho == 1 and Config.WearingPoncho or 0
            local wskirts = skirts == 1 and Config.WearingSkirt or 0
            local wchaps = chaps == 1 and Config.WearingChaps or 0

            tempadd = (what + wshirt + wpants + wboots + wcoat + wopencoat + wgloves + wvest + wponcho + wskirts + wchaps)

            if Config.EnableNoWarmthJobs and Config.NoWarmthJobs then
                local playerData = RSGCore.Functions.GetPlayerData()
                if playerData.job and playerData.job.type then
                    for _, jobType in pairs(Config.NoWarmthJobs) do
                        if playerData.job.type == jobType then
                            tempadd = 0
                            break
                        end
                    end
                end
            end

            if Config.TempFormat == 'celsius' then
                temperature = math.floor(GetTemperatureAtCoords(coords)) + tempadd .. "°C"
                temp = math.floor(GetTemperatureAtCoords(coords)) + tempadd
            end
            if Config.TempFormat == 'fahrenheit' then
                temperature = math.floor(GetTemperatureAtCoords(coords) * 9/5 + 32) + tempadd .. "°F"
                temp = math.floor(GetTemperatureAtCoords(coords) * 9/5 + 32) + tempadd
            end
        else
            if Config.TempFormat == 'celsius' then
                temperature = math.floor(GetTemperatureAtCoords(coords)) .. "°C"
                temp = math.floor(GetTemperatureAtCoords(coords))
            end
            if Config.TempFormat == 'fahrenheit' then
                temperature = math.floor(GetTemperatureAtCoords(coords) * 9/5 + 32) .. "°F"
                temp = math.floor(GetTemperatureAtCoords(coords) * 9/5 + 32)
            end
        end
    end
end)

exports('GetCurrentTemperature', function()
    return temp
end)

CreateThread(function()
    repeat Wait(100) until LocalPlayer.state.isLoggedIn

    while true do
        Wait(Config.StatusInterval)
        local playerData = RSGCore.Functions.GetPlayerData()

        if LocalPlayer.state.isLoggedIn and not playerData.metadata['isdead'] then
            local state = LocalPlayer.state

            if state.hunger == nil then LocalPlayer.state:set('hunger', 100, true) end
            if state.thirst == nil then LocalPlayer.state:set('thirst', 100, true) end
            if state.cleanliness == nil then LocalPlayer.state:set('cleanliness', 100, true) end
            if state.stress == nil then LocalPlayer.state:set('stress', 0, true) end
            if state.bladder == nil then LocalPlayer.state:set('bladder', 0, true) end

            if Config.FlyEffect then
                FliesSpawn(state.cleanliness or 100)
            end

            local bladderLevel = state.bladder or 0
            if bladderLevel >= Config.BladderCriticalLevel then
                if math.random(1, 10) == 1 then
                    lib.notify({ title = 'Вы очень хотите в туалет!', type = 'error', duration = 3000 })
                end
                if Config.BladderHealthDamage then
                    local health = GetEntityHealth(cache.ped)
                    SetEntityHealth(cache.ped, math.max(0, health - Config.BladderDamageAmount))
                end
            elseif bladderLevel >= Config.BladderWarningLevel then
                if math.random(1, 20) == 1 then
                    lib.notify({ title = 'Вам нужно в туалет', type = 'warning', duration = 3000 })
                end
            end

            if Config.DoHealthDamage then
                local health = GetEntityHealth(cache.ped)

                -- Урон от критически низкого голода или жажды (при <= 15%)
                local hungerLevel = state.hunger or 100
                local thirstLevel = state.thirst or 100
                
                if hungerLevel <= Config.CriticalHungerLevel or thirstLevel <= Config.CriticalThirstLevel then
                    local decreaseThreshold = math.random(5, 10)
                    
                    -- Более сильный урон при 0%
                    if hungerLevel <= 0 or thirstLevel <= 0 then
                        decreaseThreshold = math.random(10, 15)
                    end
                    
                    if Config.DoHealthPainSound then
                        PlayPain(cache.ped, 9, 1, true, true)
                    end
                    if Config.DoHealthDamageFx then
                        Citizen.InvokeNative(0x4102732DF6B4005F, "MP_Downed", 0, true)
                    end
                    SetEntityHealth(cache.ped, math.max(0, health - decreaseThreshold))
                    
                    debugPrint('[HUD DEBUG] Health damage from hunger/thirst: ' .. decreaseThreshold)
                end

                if Config.TempFeature then
                    if temp < Config.MinTemp then 
                        if Config.DoHealthDamageFx then
                            Citizen.InvokeNative(0x4102732DF6B4005F, "MP_Downed", 0, true)
                        end
                        if Config.DoHealthPainSound then
                            PlayPain(cache.ped, 9, 1, true, true)
                        end
                        SetEntityHealth(cache.ped, math.max(0, health - Config.RemoveHealth))
                    elseif Citizen.InvokeNative(0x4A123E85D7C4CA0B, "MP_Downed") and Config.DoHealthDamageFx then
                        Citizen.InvokeNative(0xB4FD7446BAB2F394, "MP_Downed")
                    end

                    if temp > Config.MaxTemp then
                        if Config.DoHealthDamageFx then
                            Citizen.InvokeNative(0x4102732DF6B4005F, "MP_Downed", 0, true)
                        end
                        if Config.DoHealthPainSound then
                            PlayPain(cache.ped, 9, 1, true, true)
                        end
                        SetEntityHealth(cache.ped, math.max(0, health - Config.RemoveHealth))
                    elseif Citizen.InvokeNative(0x4A123E85D7C4CA0B, "MP_Downed") and Config.DoHealthDamageFx then
                        Citizen.InvokeNative(0xB4FD7446BAB2F394, "MP_Downed")
                    end
                end

                if (state.cleanliness or 100) <= Config.CriticalCleanlinessLevel then
                    if Config.DoHealthDamageFx then
                        Citizen.InvokeNative(0x4102732DF6B4005F, "MP_Downed", 0, true)
                    end
                    if Config.DoHealthPainSound then
                        PlayPain(cache.ped, 12, 1, true, true)
                    end
                    SetEntityHealth(cache.ped, math.max(0, health - Config.RemoveHealth))
                    debugPrint('[HUD DEBUG] Health damage from low cleanliness')
                elseif Citizen.InvokeNative(0x4A123E85D7C4CA0B, "MP_Downed") and Config.DoHealthDamageFx then
                    Citizen.InvokeNative(0xB4FD7446BAB2F394, "MP_Downed")
                end
            end

            updateNeed('hunger', Config.HungerRate, true)
            updateNeed('thirst', Config.ThirstRate, true)
            updateNeed('stress', Config.StressDecayRate, true)
            -- ★ shiw-lifestyle: Сердце Таверны — bladder заполняется быстрее
            local bladderRate = Config.BladderRate
            local lsBladderBonus = 0
            pcall(function() lsBladderBonus = exports['shiw-lifestyle']:GetBladderSpeedBonus() or 0 end)
            if lsBladderBonus > 0 then
                bladderRate = bladderRate * (1.0 + lsBladderBonus)
            end
            updateNeed('bladder', bladderRate, false)
        end
    end
end)

CreateThread(function()
    repeat Wait(100) until LocalPlayer.state.isLoggedIn
    while true do
        Wait(Config.StatusInterval)
        local playerData = RSGCore.Functions.GetPlayerData()
        if LocalPlayer.state.isLoggedIn and not playerData.metadata['isdead'] then
        end
    end
end)

RegisterNetEvent('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({ action = 'show', type = 'cash', cash = string.format("%.2f", amount) })
    elseif type == 'bloodmoney' then
        SendNUIMessage({ action = 'show', type = 'bloodmoney', bloodmoney = string.format("%.2f", amount) })
    elseif type == 'bank' then
        SendNUIMessage({ action = 'show', type = 'bank', bank = string.format("%.2f", amount) })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        cashAmount = PlayerData.money.cash
        bloodmoneyAmount = PlayerData.money.bloodmoney
        bankAmount = PlayerData.money.bank
    end)
    SendNUIMessage({
        action = 'update',
        cash = lib.math.round(cashAmount, 2),
        bloodmoney = lib.math.round(bloodmoneyAmount, 2),
        bank = lib.math.round(bankAmount, 2),
        amount = lib.math.round(amount, 2),
        minus = isMinus,
        type = type,
    })
end)

CreateThread(function()
    while true do
        if RSGCore ~= nil then
            if IsPedInAnyVehicle(cache.ped, false) then
                speed = GetEntitySpeed(GetVehiclePedIsIn(cache.ped, false)) * 2.237
                if speed >= Config.MinimumSpeed then
                    TriggerEvent('hud:client:GainStress', math.random(1, 3))
                end
            end
        end
        Wait(10000)
    end
end)

lib.onCache('weapon', function(weapon)
    local player = PlayerPedId()
    if weapon ~= -1569615261 then
        isWeapon = true
    else
        isWeapon = false
    end
     CreateThread(function()
         while isWeapon do
             local isShooting = IsPedShooting(player)
             if isShooting then
                 if math.random() < Config.StressChance then
                     updateStress(math.random(1, 3), true)
                 end
             end
             Wait(100)
         end
     end)
end)

CreateThread(function()
    while true do
        local stress = LocalPlayer.state.stress or 0
        local sleep = GetEffectInterval(stress)

        if stress >= 100 then
            local ShakeIntensity = GetShakeIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = (FallRepeat * 1750)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)

            if not IsPedRagdoll(cache.ped) and IsPedOnFoot(cache.ped) and not IsPedSwimming(cache.ped) then
                SetPedToRagdollWithFall(cache.ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(cache.ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(500)
            for i = 1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            end
        elseif stress >= Config.MinimumStress then
            local ShakeIntensity = GetShakeIntensity(stress)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
        end
        Wait(sleep)
    end
end)
-- ═══════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════
RegisterCommand('alcoholstats', function()
    print('=== ALCOHOL STATS ===')
    print('Drinks today: ' .. alcoholStats.totalDrinksToday)
    print('Drinks week: ' .. alcoholStats.totalDrinksWeek)
    print('Consecutive days: ' .. alcoholStats.consecutiveDrinkingDays)
    print('Blackouts: ' .. alcoholStats.blackoutCount)
    print('Addiction level: ' .. alcoholStats.addictionLevel)
    print('Last drink time: ' .. alcoholStats.lastDrinkTime)
    print('Is drunk: ' .. tostring(isDrunk))
    print('Drunk level: ' .. currentDrunkLevel)
    print('=====================')
    
    lib.notify({ 
        title = 'Alcohol Stats', 
        description = 'Drinks: ' .. alcoholStats.totalDrinksToday .. ' | Addiction: ' .. alcoholStats.addictionLevel,
        type = 'inform',
        duration = 5000
    })
end, false)

RegisterCommand('testdrunk', function(source, args)
    local level = tonumber(args[1]) or 1
    print('[TEST] Forcing drunk level: ' .. level)
    applyDrunkEffects(level)
end, false)

RegisterCommand('testaddiction', function(source, args)
    local level = tonumber(args[1]) or 1
    alcoholStats.addictionLevel = level
    print('[TEST] Addiction level set to: ' .. level)
    lib.notify({ title = 'Test', description = 'Addiction = ' .. level, type = 'inform' })
end, false)

RegisterCommand('resetalcohol', function()
    alcoholStats = {
        totalDrinksToday = 0,
        totalDrinksWeek = 0,
        lastDrinkTime = 0,
        consecutiveDrinkingDays = 0,
        soberTime = 0,
        drunkTime = 0,
        blackoutCount = 0,
        addictionLevel = 0
    }
    isDrunk = false
    currentDrunkLevel = 0
    drunkEffectActive = false
    
    -- 🆕 УДАЛЯЕМ ИЗ БД
    TriggerServerEvent('hud:server:resetAllAlcoholStats')
    
    print('[TEST] Alcohol stats reset!')
    lib.notify({ title = 'Reset', description = 'Alcohol stats cleared', type = 'success' })
end, false)
-- ═══════════════════════════════════════════════════════════════
-- AUTO-SAVE ALCOHOL STATS (каждые 5 минут)
-- ═══════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(300000) -- 5 минут
        
        if LocalPlayer.state.isLoggedIn then
            saveAlcoholStatsToServer()
            debugPrint('[HUD DEBUG] Auto-saved alcohol stats')
        end
    end
end)
------------------------------------------------
-- Inventory HUD Control
------------------------------------------------
local inventoryOpen = false
local forceShowHUD = false

-- Отслеживание открытия инвентаря через NUI Focus
CreateThread(function()
    while true do
        Wait(100)
        
        local nuiFocused = IsNuiFocused()
        
        if nuiFocused and not inventoryOpen then
            -- Проверяем что это именно инвентарь (по задержке после нажатия I)
            local keyPressed = IsControlJustReleased(0, 0x20190AB4) -- I key
            if keyPressed or nuiFocused then
                inventoryOpen = true
                forceShowHUD = true
                
                -- Форсируем показ HUD через NUI
                SendNUIMessage({
                    action = 'forceShow'
                })
                
                debugPrint('[HUD DEBUG] Inventory opened - HUD forced ON')
            end
        elseif not nuiFocused and inventoryOpen then
            inventoryOpen = false
            forceShowHUD = false
            debugPrint('[HUD DEBUG] Inventory closed - HUD normal mode')
        end
    end
end)

RegisterNetEvent('hud:client:GainStress', function(amount)
    updateStress(amount, true)
end)

RegisterNetEvent('hud:client:RelieveStress', function(amount)
    updateStress(amount, false)
end)

local function setupLoginWatcher()
    local wasLoggedIn = false
    CreateThread(function()
        while true do
            Wait(100)
            local isLoggedIn = LocalPlayer.state.isLoggedIn
            if isLoggedIn and not wasLoggedIn then
                showUI = true
                wasLoggedIn = true
                for _ = 1, 5 do
                    sendHudTick()
                    Wait(150)
                end
            elseif not isLoggedIn and wasLoggedIn then
                showUI = false
                wasLoggedIn = false
            end
        end
    end)
end

setupLoginWatcher()

RegisterCommand('resethud', function()
    SendNUIMessage({ action = 'resetPositions' })
    lib.notify({
        title = 'Сброс HUD',
        description = 'Позиции элементов HUD сброшены',
        type = 'success',
        duration = 3000
    })
end, false)

RegisterNUICallback('disableEditMode', function(data, cb)
    if editMode then
        editMode = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'toggleEditMode',
            enabled = false
        })
        lib.notify({
            title = 'Режим редактирования',
            description = 'Редактирование HUD завершено',
            type = 'inform',
            duration = 3000
        })
    end
    cb('ok')
end)

RegisterCommand('testclean', function()
    LocalPlayer.state:set('cleanliness', 10, true)
    lib.notify({ title = 'Тест', description = 'Чистота установлена на 10%', type = 'inform' })
end, false)

RegisterCommand('testbath', function()
    TriggerEvent('hud:client:StartBathing', 'test')
    Wait(10000)
    TriggerEvent('hud:client:StopBathing')
end, false)

-- ═══════════════════════════════════════════════════════════════
-- FOOD DECAY SYSTEM - CLIENT EVENTS
-- ═══════════════════════════════════════════════════════════════

-- Уведомление об обновлении порчи
RegisterNetEvent('hud:client:FoodDecayUpdate', function()
    debugPrint('[HUD DEBUG] Food decay updated')
end)

-- Результат проверки качества еды
RegisterNetEvent('hud:client:FoodQualityResult', function(itemName, quality)
    debugPrint('[HUD DEBUG] Food quality: ' .. itemName .. ' = ' .. quality .. '%')
    
    -- Показываем уведомление если качество низкое
    if quality < 30 then
        lib.notify({
            title = 'Испорченный продукт',
            description = itemName .. ' почти испорчен (' .. math.floor(quality) .. '%)',
            type = 'error',
            duration = 3000
        })
    elseif quality < 60 then
        lib.notify({
            title = 'Свежесть',
            description = itemName .. ' не очень свежий (' .. math.floor(quality) .. '%)',
            type = 'warning',
            duration = 3000
        })
    end
end)

-- Показ информации о порче (команда /checkdecay)
RegisterNetEvent('hud:client:ShowDecayInfo', function(decayItems)
    if not decayItems or #decayItems == 0 then
        lib.notify({
            title = 'Порча еды',
            description = 'В инвентаре нет портящихся продуктов',
            type = 'inform',
            duration = 3000
        })
        return
    end
    
    print('═══════════════════════════════════════════')
    print('         ИНФОРМАЦИЯ О ПОРЧЕ ЕДЫ           ')
    print('═══════════════════════════════════════════')
    
    for _, item in ipairs(decayItems) do
        local status = 'Свежий'
        if item.quality < 30 then
            status = 'Испорчен!'
        elseif item.quality < 60 then
            status = 'Не свежий'
        elseif item.quality < 80 then
            status = 'Нормальный'
        end
        
        print(string.format('  [Слот %d] %s: %.1f%% (%s)', item.slot, item.name, item.quality, status))
    end
    
    print('═══════════════════════════════════════════')
    
    lib.notify({
        title = 'Порча еды',
        description = 'Найдено ' .. #decayItems .. ' продуктов (см. F8)',
        type = 'inform',
        duration = 5000
    })
end)

-- Модификация эффективности еды в зависимости от качества
local function getQualityMultiplier(quality)
    if quality >= 80 then
        return 1.0  -- Полный эффект
    elseif quality >= 60 then
        return 0.8  -- 80% эффекта
    elseif quality >= 40 then
        return 0.5  -- 50% эффекта
    elseif quality >= 20 then
        return 0.25 -- 25% эффекта
    else
        return 0.1  -- 10% эффекта + шанс отравления
    end
end

-- Экспорт для использования в других скриптах
exports('GetFoodQualityMultiplier', getQualityMultiplier)

-- ═══════════════════════════════════════════════════════════════
-- STREAMER MODE SYSTEM
-- ═══════════════════════════════════════════════════════════════
local isStreamerMode = false
local nearbyStreamers = {}
local streamerCheckThread = nil

-- Команда для включения/выключения режима стримера
RegisterCommand('streamermode', function()
    if not Config.StreamerMode or not Config.StreamerMode.enabled then
        lib.notify({
            title = 'Режим стримера',
            description = 'Режим стримера отключен на сервере',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    isStreamerMode = not isStreamerMode
    
    -- Отправляем на сервер изменение статуса
    TriggerServerEvent('hud:server:toggleStreamerMode', isStreamerMode)
    
    if isStreamerMode then
        lib.notify({
            title = 'Режим стримера',
            description = 'Режим стримера ВКЛЮЧЕН. Игроки рядом будут видеть иконку.',
            type = 'success',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Режим стримера',
            description = 'Режим стримера ВЫКЛЮЧЕН.',
            type = 'inform',
            duration = 3000
        })
    end
end, false)

-- Получение списка стримеров поблизости от сервера
RegisterNetEvent('hud:client:updateNearbyStreamers', function(streamers)
    nearbyStreamers = streamers or {}
    
    -- Отправляем в NUI информацию о стримерах
    local hasNearbyStreamer = #nearbyStreamers > 0
    SendNUIMessage({
        action = 'updateStreamerMode',
        hasNearbyStreamer = hasNearbyStreamer,
        streamerCount = #nearbyStreamers,
        isStreaming = isStreamerMode
    })
end)

-- Уведомление о стримере поблизости
RegisterNetEvent('hud:client:streamerNearbyNotification', function(streamerName)
    lib.notify({
        title = '📺 Внимание!',
        description = Config.StreamerMode.notificationMessage or "В радиусе кто-то стримит, следите за словами!",
        type = 'warning',
        duration = 8000
    })
end)

-- Поток для периодической проверки и отправки позиции (если стример)
CreateThread(function()
    while true do
        Wait(2000) -- Проверяем каждые 2 секунды
        
        if LocalPlayer.state.isLoggedIn and Config.StreamerMode and Config.StreamerMode.enabled then
            local playerCoords = GetEntityCoords(cache.ped)
            
            -- Отправляем на сервер нашу позицию для проверки стримеров рядом
            TriggerServerEvent('hud:server:checkNearbyStreamers', {
                x = playerCoords.x,
                y = playerCoords.y,
                z = playerCoords.z
            })
        end
    end
end)

-- Экспорт для проверки режима стримера
exports('IsStreamerMode', function()
    return isStreamerMode
end)

exports('HasNearbyStreamer', function()
    return #nearbyStreamers > 0
end)