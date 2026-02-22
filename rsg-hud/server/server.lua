local RSGCore = exports['rsg-core']:GetCoreObject()
local ResetStress = false
local registeredItems = {}
lib.locale()

-- ═══════════════════════════════════════════════════════════════
-- DIET VARIETY SYSTEM (Система рационов)
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    
    local createDietTable = [[
        CREATE TABLE IF NOT EXISTS `player_diet_stats` (
            `citizenid` VARCHAR(50) NOT NULL,
            `food_history` LONGTEXT DEFAULT '{}',
            `week_start` BIGINT DEFAULT 0,
            `unique_foods_count` INT DEFAULT 0,
            `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    
    MySQL.query(createDietTable, {}, function(result)
        print('[RSG-HUD] Diet stats table ready')
    end)
end)

-- Загрузка статистики рациона
RegisterNetEvent('hud:server:loadDietStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local currentTime = os.time()
    
    MySQL.query('SELECT * FROM player_diet_stats WHERE citizenid = ?', {citizenid}, function(result)
        local stats = {
            foodHistory = {},
            weekStart = currentTime,
            uniqueFoodsCount = 0
        }
        
        if result and result[1] then
            local data = result[1]
            local weekStart = data.week_start or 0
            
            -- Проверяем нужно ли сбросить (прошла неделя)
            if currentTime - weekStart >= (Config.DietSystem and Config.DietSystem.resetInterval or 604800) then
                -- Сбрасываем данные
                stats.foodHistory = {}
                stats.weekStart = currentTime
                stats.uniqueFoodsCount = 0
                
                -- Обновляем в БД
                MySQL.query('UPDATE player_diet_stats SET food_history = ?, week_start = ?, unique_foods_count = 0 WHERE citizenid = ?', 
                    {json.encode({}), currentTime, citizenid})
                
                print('[RSG-HUD] Diet stats reset for ' .. citizenid .. ' (new week)')
            else
                -- Загружаем существующие данные
                local foodHistory = {}
                if data.food_history and data.food_history ~= '' then
                    foodHistory = json.decode(data.food_history) or {}
                end
                
                stats.foodHistory = foodHistory
                stats.weekStart = weekStart
                stats.uniqueFoodsCount = data.unique_foods_count or 0
            end
            
            print('[RSG-HUD] Loaded diet stats for ' .. citizenid)
        else
            -- Создаём новую запись
            MySQL.query('INSERT INTO player_diet_stats (citizenid, food_history, week_start, unique_foods_count) VALUES (?, ?, ?, 0)',
                {citizenid, json.encode({}), currentTime})
            print('[RSG-HUD] Created new diet stats for ' .. citizenid)
        end
        
        TriggerClientEvent('hud:client:loadDietStats', src, stats)
    end)
end)

-- Сохранение статистики рациона
RegisterNetEvent('hud:server:saveDietStats', function(stats)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not stats then return end
    
    local citizenid = Player.PlayerData.citizenid
    local foodHistoryJson = json.encode(stats.foodHistory or {})
    
    -- Считаем уникальные продукты
    local uniqueCount = 0
    for _, _ in pairs(stats.foodHistory or {}) do
        uniqueCount = uniqueCount + 1
    end
    
    MySQL.query([[
        INSERT INTO player_diet_stats (citizenid, food_history, week_start, unique_foods_count)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        food_history = VALUES(food_history),
        week_start = VALUES(week_start),
        unique_foods_count = VALUES(unique_foods_count)
    ]], {citizenid, foodHistoryJson, stats.weekStart or os.time(), uniqueCount})
end)

-- Добавление еды в историю
RegisterNetEvent('hud:server:addFoodToHistory', function(foodItem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not foodItem then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT food_history, week_start FROM player_diet_stats WHERE citizenid = ?', {citizenid}, function(result)
        local foodHistory = {}
        local weekStart = os.time()
        
        if result and result[1] then
            if result[1].food_history and result[1].food_history ~= '' then
                foodHistory = json.decode(result[1].food_history) or {}
            end
            weekStart = result[1].week_start or os.time()
        end
        
        -- Добавляем или увеличиваем счётчик
        foodHistory[foodItem] = (foodHistory[foodItem] or 0) + 1
        
        -- Считаем уникальные
        local uniqueCount = 0
        for _, _ in pairs(foodHistory) do
            uniqueCount = uniqueCount + 1
        end
        
        -- Сохраняем
        MySQL.query([[
            INSERT INTO player_diet_stats (citizenid, food_history, week_start, unique_foods_count)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            food_history = VALUES(food_history),
            unique_foods_count = VALUES(unique_foods_count)
        ]], {citizenid, json.encode(foodHistory), weekStart, uniqueCount})
        
        -- Отправляем обновление клиенту
        TriggerClientEvent('hud:client:updateDietStats', src, {
            foodHistory = foodHistory,
            weekStart = weekStart,
            uniqueFoodsCount = uniqueCount
        })
    end)
end)

-- Сброс статистики рациона
RegisterNetEvent('hud:server:resetDietStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local currentTime = os.time()
    
    MySQL.query('UPDATE player_diet_stats SET food_history = ?, week_start = ?, unique_foods_count = 0 WHERE citizenid = ?',
        {json.encode({}), currentTime, citizenid})
    
    TriggerClientEvent('hud:client:loadDietStats', src, {
        foodHistory = {},
        weekStart = currentTime,
        uniqueFoodsCount = 0
    })
    
    print('[RSG-HUD] Reset diet stats for ' .. citizenid)
end)

-- ═══════════════════════════════════════════════════════════════
-- ALCOHOL STATS DATABASE SYSTEM
-- ═══════════════════════════════════════════════════════════════

-- Создание таблицы при старте
CreateThread(function()
    Wait(1000)
    
    local createTable = [[
        CREATE TABLE IF NOT EXISTS `player_alcohol_stats` (
            `citizenid` VARCHAR(50) NOT NULL,
            `total_drinks_today` INT DEFAULT 0,
            `total_drinks_week` INT DEFAULT 0,
            `consecutive_days` INT DEFAULT 0,
            `blackout_count` INT DEFAULT 0,
            `addiction_level` INT DEFAULT 0,
            `last_drink_time` BIGINT DEFAULT 0,
            `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    
    MySQL.query(createTable, {}, function(result)
        print('[RSG-HUD] Alcohol stats table ready')
    end)
end)

-- Загрузка статистики при входе игрока
RegisterNetEvent('hud:server:loadAlcoholStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM player_alcohol_stats WHERE citizenid = ?', {citizenid}, function(result)
        local stats = {
            totalDrinksToday = 0,
            totalDrinksWeek = 0,
            consecutiveDrinkingDays = 0,
            blackoutCount = 0,
            addictionLevel = 0,
            lastDrinkTime = 0
        }
        
        if result and result[1] then
            local data = result[1]
            stats.totalDrinksToday = data.total_drinks_today or 0
            stats.totalDrinksWeek = data.total_drinks_week or 0
            stats.consecutiveDrinkingDays = data.consecutive_days or 0
            stats.blackoutCount = data.blackout_count or 0
            stats.addictionLevel = data.addiction_level or 0
            stats.lastDrinkTime = data.last_drink_time or 0
            
            print('[RSG-HUD] Loaded alcohol stats for ' .. citizenid)
        else
            print('[RSG-HUD] No alcohol stats found for ' .. citizenid .. ', using defaults')
        end
        
        TriggerClientEvent('hud:client:loadAlcoholStats', src, stats)
    end)
end)

-- Сохранение статистики
RegisterNetEvent('hud:server:saveAlcoholStats', function(stats)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not stats then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    local query = [[
        INSERT INTO player_alcohol_stats 
        (citizenid, total_drinks_today, total_drinks_week, consecutive_days, blackout_count, addiction_level, last_drink_time)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        total_drinks_today = VALUES(total_drinks_today),
        total_drinks_week = VALUES(total_drinks_week),
        consecutive_days = VALUES(consecutive_days),
        blackout_count = VALUES(blackout_count),
        addiction_level = VALUES(addiction_level),
        last_drink_time = VALUES(last_drink_time)
    ]]
    
    MySQL.query(query, {
        citizenid,
        stats.totalDrinksToday or 0,
        stats.totalDrinksWeek or 0,
        stats.consecutiveDrinkingDays or 0,
        stats.blackoutCount or 0,
        stats.addictionLevel or 0,
        stats.lastDrinkTime or 0
    }, function(result)
        if result then
            print('[RSG-HUD] Saved alcohol stats for ' .. citizenid)
        end
    end)
end)

-- Сброс дневной статистики
RegisterNetEvent('hud:server:resetDailyAlcohol', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('UPDATE player_alcohol_stats SET total_drinks_today = 0 WHERE citizenid = ?', {citizenid})
    
    print('[RSG-HUD] Reset daily alcohol stats for ' .. citizenid)
end)

-- Сброс недельной статистики
RegisterNetEvent('hud:server:resetWeeklyAlcohol', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('UPDATE player_alcohol_stats SET total_drinks_week = 0 WHERE citizenid = ?', {citizenid})
    
    print('[RSG-HUD] Reset weekly alcohol stats for ' .. citizenid)
end)

-- Полный сброс
RegisterNetEvent('hud:server:resetAllAlcoholStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('DELETE FROM player_alcohol_stats WHERE citizenid = ?', {citizenid}, function()
        print('[RSG-HUD] Deleted all alcohol stats for ' .. citizenid)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
-- SMOKING STATS DATABASE SYSTEM
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    
    local createTable = [[
        CREATE TABLE IF NOT EXISTS `player_smoking_stats` (
            `citizenid` VARCHAR(50) NOT NULL,
            `total_smokes_today` INT DEFAULT 0,
            `total_smokes_week` INT DEFAULT 0,
            `consecutive_days` INT DEFAULT 0,
            `last_smoke_time` BIGINT DEFAULT 0,
            `addiction_level` INT DEFAULT 0,
            `lung_health` INT DEFAULT 100,
            `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
    
    MySQL.query(createTable, {}, function(result)
        print('[RSG-HUD] Smoking stats table ready')
    end)
end)

RegisterNetEvent('hud:server:loadSmokingStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('SELECT * FROM player_smoking_stats WHERE citizenid = ?', {citizenid}, function(result)
        local stats = {
            totalSmokesToday = 0,
            totalSmokesWeek = 0,
            consecutiveSmokingDays = 0,
            lastSmokeTime = 0,
            addictionLevel = 0,
            lungHealth = 100
        }
        
        if result and result[1] then
            local data = result[1]
            stats.totalSmokesToday = data.total_smokes_today or 0
            stats.totalSmokesWeek = data.total_smokes_week or 0
            stats.consecutiveSmokingDays = data.consecutive_days or 0
            stats.lastSmokeTime = data.last_smoke_time or 0
            stats.addictionLevel = data.addiction_level or 0
            stats.lungHealth = data.lung_health or 100
            
            print('[RSG-HUD] Loaded smoking stats for ' .. citizenid)
        end
        
        TriggerClientEvent('hud:client:loadSmokingStats', src, stats)
    end)
end)

RegisterNetEvent('hud:server:saveSmokingStats', function(stats)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not stats then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    local query = [[
        INSERT INTO player_smoking_stats 
        (citizenid, total_smokes_today, total_smokes_week, consecutive_days, last_smoke_time, addiction_level, lung_health)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        total_smokes_today = VALUES(total_smokes_today),
        total_smokes_week = VALUES(total_smokes_week),
        consecutive_days = VALUES(consecutive_days),
        last_smoke_time = VALUES(last_smoke_time),
        addiction_level = VALUES(addiction_level),
        lung_health = VALUES(lung_health)
    ]]
    
    MySQL.query(query, {
        citizenid,
        stats.totalSmokesToday or 0,
        stats.totalSmokesWeek or 0,
        stats.consecutiveSmokingDays or 0,
        stats.lastSmokeTime or 0,
        stats.addictionLevel or 0,
        stats.lungHealth or 100
    })
end)

-- ═══════════════════════════════════════════════════════════════
-- CANNABIS STATS (для зависимости: 3+ косяка/24ч в течение 4 дней)
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `player_cannabis_stats` (
            `citizenid` VARCHAR(50) NOT NULL,
            `day_counts` LONGTEXT DEFAULT '{}',
            `last_update` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        print('[RSG-HUD] Cannabis stats table ready')
    end)
end)

RegisterNetEvent('hud:server:loadCannabisStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    MySQL.query('SELECT day_counts FROM player_cannabis_stats WHERE citizenid = ?', {citizenid}, function(result)
        local dayCounts = {}
        if result and result[1] and result[1].day_counts and result[1].day_counts ~= '' then
            dayCounts = json.decode(result[1].day_counts) or {}
        end
        TriggerClientEvent('hud:client:loadCannabisStats', src, dayCounts)
    end)
end)

RegisterNetEvent('hud:server:saveCannabisStats', function(dayCounts)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not dayCounts then return end
    local citizenid = Player.PlayerData.citizenid
    local dayCountsJson = json.encode(dayCounts or {})
    MySQL.query([[
        INSERT INTO player_cannabis_stats (citizenid, day_counts) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE day_counts = VALUES(day_counts)
    ]], {citizenid, dayCountsJson})
end)

RegisterNetEvent('hud:server:resetAllSmokingStats', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.query('DELETE FROM player_smoking_stats WHERE citizenid = ?', {citizenid})
    print('[RSG-HUD] Reset smoking stats for ' .. citizenid)
end)

-- ═══════════════════════════════════════════════════════════════
-- SMOKING HANDLER
-- ═══════════════════════════════════════════════════════════════

local activeSmokers = {}

-- Обработчик завершения курения (всегда вызывается)
RegisterNetEvent('hud:server:SmokingFinished', function(itemName, slot, completed)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local smokerData = activeSmokers[src]
    
    -- Если докурил полностью - добавляем следующий предмет
    if completed and smokerData and smokerData.nextItem then
        Player.Functions.AddItem(smokerData.nextItem, 1)
        print('[RSG-HUD] Gave next item: ' .. smokerData.nextItem)
    end
    
    -- ВСЕГДА очищаем activeSmokers
    activeSmokers[src] = nil
    print('[RSG-HUD] ' .. GetPlayerName(src) .. ' finished smoking (completed: ' .. tostring(completed) .. ')')
end)

-- Старый обработчик для совместимости
RegisterNetEvent('hud:server:SmokingCompleted', function(itemName, slot)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player or not activeSmokers[src] then return end
    
    local smokerData = activeSmokers[src]
    
    -- Добавляем следующий предмет если есть
    if smokerData.nextItem then
        Player.Functions.AddItem(smokerData.nextItem, 1)
        print('[RSG-HUD] Gave next item: ' .. smokerData.nextItem)
    end
    
    activeSmokers[src] = nil
    print('[RSG-HUD] ' .. GetPlayerName(src) .. ' finished smoking (legacy)')
end)

-- Очистка при дисконнекте
AddEventHandler('playerDropped', function()
    local src = source
    if activeSmokers[src] then
        activeSmokers[src] = nil
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- AUTO-REGISTER ALL CONSUMABLE ITEMS
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    
    print('^3[RSG-HUD]^7 Starting consumable items registration...')
    
    local registeredCount = 0
    for itemName, itemData in pairs(Config.ConsumableItems) do
        if registeredItems[itemName] then
            print('^1[RSG-HUD WARNING]^7 Item already registered: ' .. itemName)
        else
            RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
                local Player = RSGCore.Functions.GetPlayer(source)
                if not Player then 
                    print('^1[RSG-HUD ERROR]^7 Player not found for source: ' .. source)
                    return 
                end
                
                print('^2[RSG-HUD]^7 ' .. GetPlayerName(source) .. ' is trying to use: ' .. itemName)
                
                -- Проверяем наличие предмета
                local hasItem = Player.Functions.GetItemBySlot(item.slot)
                if not hasItem then
                    print('^1[RSG-HUD ERROR]^7 Item not found in slot: ' .. item.slot)
                    return
                end
                
                -- СПЕЦИАЛЬНАЯ ОБРАБОТКА ДЛЯ КУРЕНИЯ
                local itemConfig = Config.ConsumableItems[itemName]
                if itemConfig and itemConfig.type == 'smoking' then
                    print('^3[RSG-HUD]^7 Processing smoking item: ' .. itemName)
                    
                    -- ПРЯМАЯ ОБРАБОТКА БЕЗ СОБЫТИЙ
                    -- Проверяем что игрок не курит
                    if activeSmokers[source] then
                        TriggerClientEvent('ox_lib:notify', source, { 
                            title = 'Курение', 
                            description = 'Вы уже курите!', 
                            type = 'error' 
                        })
                        return
                    end
                    
                    local smokingType = itemConfig.smokingType
                    
                    -- Определяем следующий предмет в пачке
                    local nextItem = nil
                    if string.match(itemName, 'cigaret(%d+)') then
                        local num = tonumber(string.match(itemName, 'cigaret(%d+)'))
                        if num and num < 10 then
                            nextItem = 'cigaret' .. (num + 1)
                        end
                    elseif itemName == 'cigaret' then
                        nextItem = 'cigaret2'
                    elseif string.match(itemName, 'chewingtobacco(%d+)') then
                        local num = tonumber(string.match(itemName, 'chewingtobacco(%d+)'))
                        if num and num < 5 then
                            nextItem = 'chewingtobacco' .. (num + 1)
                        end
                    elseif itemName == 'chewingtobacco' then
                        nextItem = 'chewingtobacco2'
                    end
                    
                    -- Проверяем требования к курению заранее и одним сообщением
                    local missingItems = {}
                    local needMatches = (smokingType == 'cigarette' or smokingType == 'cigar' or smokingType == 'pipe' or smokingType == 'joint')
                    local needPipeTobacco = (smokingType == 'pipe' and not (itemConfig.isLoadedPipe))

                    if needMatches then
                        local matchesItem = Player.Functions.GetItemByName('matches')
                        local matchesCount = (matchesItem and matchesItem.amount) or 0
                        if matchesCount < 1 then
                            missingItems[#missingItems + 1] = 'спички'
                        end
                    end

                    if needPipeTobacco then
                        local tobaccoItem = Player.Functions.GetItemByName('pipetobacco')
                        local tobaccoCount = (tobaccoItem and tobaccoItem.amount) or 0
                        if tobaccoCount < 1 then
                            missingItems[#missingItems + 1] = 'табак для трубки'
                        end
                    end

                    if #missingItems > 0 then
                        lib.notify(source, {
                            title = 'Курение',
                            description = 'Не хватает: ' .. table.concat(missingItems, ', '),
                            type = 'error'
                        })
                        print('^3[RSG-HUD]^7 Missing requirements for smoking: ' .. table.concat(missingItems, ', '))
                        return
                    end

                    -- Списываем расходники только после успешной проверки
                    local matchRemoved = false
                    if needMatches then
                        matchRemoved = Player.Functions.RemoveItem('matches', 1) and true or false
                        if not matchRemoved then
                            lib.notify(source, { title = 'Курение', description = 'Не удалось использовать спички', type = 'error' })
                            return
                        end
                        print('^2[RSG-HUD]^7 Removed 1 match')
                    end

                    if needPipeTobacco then
                        local tobaccoRemoved = Player.Functions.RemoveItem('pipetobacco', 1) and true or false
                        if not tobaccoRemoved then
                            -- откатываем спичку, если уже списали
                            if matchRemoved then
                                Player.Functions.AddItem('matches', 1)
                            end
                            lib.notify(source, { title = 'Курение', description = 'Не удалось использовать табак для трубки', type = 'error' })
                            return
                        end
                        print('^2[RSG-HUD]^7 Removed 1 pipetobacco')
                    end
                    
                    -- Удаляем предмет (кроме обычной трубки - она многоразовая; набитые трубки rsg-weed расходуются)
                    if smokingType ~= 'pipe' or (itemConfig.isLoadedPipe) then
                        Player.Functions.RemoveItem(itemName, 1, item.slot)
                        print('^2[RSG-HUD]^7 Removed smoking item: ' .. itemName)
                        -- Показываем "Использовано" только когда предмет реально потреблён
                        if RSGCore.Shared.Items[itemName] then
                            TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[itemName], 'use')
                        end
                    else
                        print('^2[RSG-HUD]^7 Pipe is reusable (not loaded_pipe), not removing')
                        if RSGCore.Shared.Items[itemName] then
                            TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[itemName], 'use')
                        end
                    end
                    
                    -- Сохраняем данные курильщика
                    activeSmokers[source] = {
                        item = itemName,
                        nextItem = nextItem,
                        startTime = os.time()
                    }
                    
                    print('^2[RSG-HUD]^7 ' .. GetPlayerName(source) .. ' started smoking: ' .. itemName)
                    
                    -- ОТПРАВЛЯЕМ НА КЛИЕНТ
                    TriggerClientEvent('hud:client:StartSmoking', source, smokingType, itemName, item.slot)
                    print('^2[RSG-HUD]^7 Sent StartSmoking event to client')
                    
                    return  -- Важно! Выходим из функции
                end
                
                -- Обычные предметы - отправляем на клиент для проверки
                TriggerClientEvent('hud:client:TryConsumeItem', source, itemName, item.slot)
            end)
            
            registeredItems[itemName] = true
            registeredCount = registeredCount + 1
            print('^2[RSG-HUD]^7 ✓ Registered: ^3' .. itemName .. '^7 (type: ^3' .. (itemData.type or 'food') .. '^7)')
        end
    end
    
    print('^2[RSG-HUD]^7 Successfully registered ^3' .. registeredCount .. '^7 consumable items!')
end)

-- Обработчик подтверждения для обычных предметов
-- ═══ НАЙДИТЕ ЭТОТ ОБРАБОТЧИК И ЗАМЕНИТЕ ЦЕЛИКОМ ═══

RegisterNetEvent('hud:server:ConsumeItemConfirmed', function(itemName, slot)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Удаляем предмет
    if Player.Functions.RemoveItem(itemName, 1, slot) then
        -- Уведомление об удалении
        if RSGCore.Shared.Items[itemName] then
            TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items[itemName], 'remove', 1)
        end
        
        print('^2[RSG-HUD]^7 Item removed: ' .. itemName)
        
        -- ═══════════════════════════════════════════════════════════
        -- ВОЗВРАТ ПРЕДМЕТА (empty_bottle и т.д.)
        -- ═══════════════════════════════════════════════════════════
        local itemConfig = Config.ConsumableItems[itemName]
        if itemConfig and itemConfig.returnItem then
            local returnItemName = itemConfig.returnItem
            
            if RSGCore.Shared.Items[returnItemName] then
                SetTimeout(6000, function()
                    local StillOnline = RSGCore.Functions.GetPlayer(source)
                    if StillOnline then
                        StillOnline.Functions.AddItem(returnItemName, 1)
                        TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items[returnItemName], 'add', 1)
                        print('^2[RSG-HUD]^7 Returned item: ' .. returnItemName .. ' to player ' .. source)
                    end
                end)
            else
                print('^1[RSG-HUD ERROR]^7 Return item not found in shared items: ' .. returnItemName)
            end
        end
        
        -- Подтверждаем клиенту
        TriggerClientEvent('hud:client:ConsumeItemStart', source, itemName)
    else
        print('^1[RSG-HUD ERROR]^7 Failed to remove item: ' .. itemName)
        TriggerClientEvent('hud:client:ConsumeItemFailed', source, 'Failed to remove item')
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════

RSGCore.Commands.Add('huditemslist', 'List registered HUD consumable items', {}, false, function(source)
    local count = 0
    for item, _ in pairs(registeredItems) do
        count = count + 1
        print('Registered: ' .. item)
    end
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"HUD", "Registered " .. count .. " consumable items (check F8 console)"}
    })
end, 'admin')

exports('GetConsumableItems', function()
    return Config.ConsumableItems
end)

RSGCore.Commands.Add('cash', 'Check Cash Balance', {}, false, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(source)
    local cashamount = Player.PlayerData.money.cash
    if cashamount ~= nil then
        TriggerClientEvent('hud:client:ShowAccounts', source, 'cash', cashamount)
    end
end)

RSGCore.Commands.Add('bloodmoney', 'Check Bloodmoney Balance', {}, false, function(source, args)
    local Player = RSGCore.Functions.GetPlayer(source)
    local bloodmoneyamount = Player.PlayerData.money.bloodmoney
    if bloodmoneyamount ~= nil then
        TriggerClientEvent('hud:client:ShowAccounts', source, 'bloodmoney', bloodmoneyamount)
    end
end)

RSGCore.Functions.CreateCallback('hud:server:getoutlawstatus', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player ~= nil then
        MySQL.query('SELECT outlawstatus FROM players WHERE citizenid = ?', {Player.PlayerData.citizenid}, function(result)
            if result[1] then
                cb(result)
            else
                cb(nil)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- FOOD DECAY SYSTEM (Система порчи еды) - ИСПРАВЛЕННАЯ ВЕРСИЯ
-- ═══════════════════════════════════════════════════════════════

-- Время последней проверки для каждого игрока
local lastDecayCheck = {}

-- Функция обработки порчи для одного игрока
local function ProcessFoodDecay(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local currentTime = os.time()
    local lastCheck = lastDecayCheck[source]
    
    -- Первый запуск - инициализируем
    if not lastCheck then
        lastDecayCheck[source] = currentTime
        print('[FoodDecay] Initialized timer for player ' .. source)
        return
    end
    
    local timePassed = currentTime - lastCheck
    
    -- Минимум 5 секунд между проверками (вместо 60)
    if timePassed < 5 then return end
    
    -- Обновляем время последней проверки
    lastDecayCheck[source] = currentTime
    
    local items = Player.PlayerData.items
    if not items then return end
    
    local itemsUpdated = false
    local speedMultiplier = (Config.FoodDecay and Config.FoodDecay.speedMultiplier) or 1
    local itemsToRemove = {}
    local processedCount = 0
    
    for slot, item in pairs(items) do
        if item and item.name then
            local decayConfig = Config.FoodDecay and Config.FoodDecay[item.name]
            
            if decayConfig and decayConfig.decayRate and decayConfig.decayRate > 0 then
                processedCount = processedCount + 1
                
                local currentQuality = 100
                if item.info and item.info.quality then
                    currentQuality = item.info.quality
                end
                
                local minQuality = decayConfig.minQuality or 0
                
                -- Если уже на 0 или ниже - помечаем для удаления
                if currentQuality <= 0 then
                    table.insert(itemsToRemove, {
                        slot = slot,
                        name = item.name,
                        amount = item.amount or 1
                    })
                    goto continue
                end
                
                -- Если на минимуме (но не 0) - пропускаем
                if minQuality > 0 and currentQuality <= minQuality then
                    goto continue
                end
                
                -- Рассчитываем порчу
                local daysPassedIRL = timePassed / 86400
                local decayAmount = decayConfig.decayRate * daysPassedIRL * speedMultiplier
                
                -- Пропускаем если изменение слишком маленькое
                if decayAmount < 0.001 then
                    goto continue
                end
                
                local newQuality = math.max(0, currentQuality - decayAmount)
                newQuality = math.floor(newQuality * 100) / 100
                
                -- Применяем изменения
                if not item.info then item.info = {} end
                item.info.quality = newQuality
                itemsUpdated = true
                                
                -- Если качество упало до 0 - помечаем для удаления
                if newQuality <= 0 then
                    table.insert(itemsToRemove, {
                        slot = slot,
                        name = item.name,
                        amount = item.amount or 1
                    })
                end
            end
            ::continue::
        end
    end
    
    -- Удаляем испорченные предметы
    if #itemsToRemove > 0 then
        for _, itemData in ipairs(itemsToRemove) do
            items[itemData.slot] = nil
            itemsUpdated = true
            
            print('[FoodDecay] SPOILED & REMOVED: ' .. itemData.name .. ' (slot ' .. itemData.slot .. ')')
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Испорчено!',
                description = itemData.name .. ' полностью испортился и был выброшен',
                type = 'error',
                duration = 5000
            })
            
            local itemInfo = RSGCore.Shared.Items[itemData.name]
            if itemInfo then
                TriggerClientEvent('inventory:client:ItemBox', source, itemInfo, 'remove', itemData.amount)
            end
        end
    end
    
    -- Сохраняем изменения
    if itemsUpdated then
        Player.Functions.SetInventory(items, true)
        TriggerClientEvent('hud:client:FoodDecayUpdate', source)
        print('[FoodDecay] Inventory updated for player ' .. source)
    end
    
    -- Отладка: показываем сколько предметов обработано
    if processedCount > 0 then
        print('[FoodDecay] Player ' .. source .. ': processed ' .. processedCount .. ' decayable items, timePassed=' .. timePassed .. 's')
    end
end

-- Запускаем цикл порчи ПОСЛЕ загрузки конфига
CreateThread(function()
    -- Ждём загрузки конфига
    Wait(3000)
    
    -- Проверяем конфиг
    local enabled = Config.FoodDecay and Config.FoodDecay.enabled
    local interval = (Config.FoodDecay and Config.FoodDecay.checkInterval) or 60000
    local speedMult = (Config.FoodDecay and Config.FoodDecay.speedMultiplier) or 1
    
    print('═══════════════════════════════════════════')
    print('[FoodDecay] SYSTEM STATUS:')
    print('[FoodDecay] Config.FoodDecay exists: ' .. tostring(Config.FoodDecay ~= nil))
    print('[FoodDecay] enabled: ' .. tostring(enabled))
    print('[FoodDecay] checkInterval: ' .. tostring(interval) .. 'ms')
    print('[FoodDecay] speedMultiplier: ' .. tostring(speedMult))
    print('═══════════════════════════════════════════')
    
    if not enabled then
        print('[FoodDecay] System is DISABLED in config')
        return
    end
    
    print('[FoodDecay] Starting decay loop...')
    
    while true do
        Wait(interval)
        
        -- Обрабатываем всех онлайн игроков
        local players = RSGCore.Functions.GetRSGPlayers()
        local playerCount = 0
        
        for _, Player in pairs(players) do
            if Player then
                playerCount = playerCount + 1
                ProcessFoodDecay(Player.PlayerData.source)
            end
        end
        
        -- Логируем каждую проверку для отладки
        if playerCount > 0 then
            print('[FoodDecay] Processed ' .. playerCount .. ' players')
        end
    end
end)

-- Событие при использовании предмета - проверяем качество
RegisterNetEvent('hud:server:CheckFoodQuality', function(itemName, slot)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local item = Player.Functions.GetItemBySlot(slot)
    if not item then return end
    
    local quality = 100
    if item.info and item.info.quality then
        quality = item.info.quality
    end
    
    TriggerClientEvent('hud:client:FoodQualityResult', source, itemName, quality)
end)

-- ═══════════════════════════════════════════════════════════════
-- DEBUG COMMANDS FOR FOOD DECAY
-- ═══════════════════════════════════════════════════════════════

RSGCore.Commands.Add('decaydebug', 'Debug food decay system', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    print('═══════════════════════════════════════════')
    print('[FoodDecay DEBUG]')
    print('═══════════════════════════════════════════')
    print('Config.FoodDecay exists: ' .. tostring(Config.FoodDecay ~= nil))
    print('Config.FoodDecay.enabled: ' .. tostring(Config.FoodDecay and Config.FoodDecay.enabled))
    print('Config.FoodDecay.checkInterval: ' .. tostring(Config.FoodDecay and Config.FoodDecay.checkInterval))
    print('Config.FoodDecay.speedMultiplier: ' .. tostring(Config.FoodDecay and Config.FoodDecay.speedMultiplier))
    print('lastDecayCheck[' .. source .. ']: ' .. tostring(lastDecayCheck[source]))
    print('Current os.time(): ' .. tostring(os.time()))
    
    if lastDecayCheck[source] then
        print('Time since last check: ' .. (os.time() - lastDecayCheck[source]) .. ' seconds')
    end
    
    local items = Player.PlayerData.items
    local decayableCount = 0
    
    print('')
    print('Items with decay config:')
    for slot, item in pairs(items) do
        if item and item.name then
            local decayConfig = Config.FoodDecay and Config.FoodDecay[item.name]
            if decayConfig and decayConfig.decayRate and decayConfig.decayRate > 0 then
                decayableCount = decayableCount + 1
                local quality = (item.info and item.info.quality) or 100
                print('  Slot ' .. slot .. ': ' .. item.name .. ' | quality=' .. quality .. ' | decayRate=' .. tostring(decayConfig.decayRate))
            end
        end
    end
    print('Total decayable items: ' .. decayableCount)
    print('═══════════════════════════════════════════')
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Decay Debug',
        description = 'Check F8 console. Decayable: ' .. decayableCount,
        type = 'inform',
        duration = 5000
    })
end, 'admin')

RSGCore.Commands.Add('forcedecay', 'Force decay (simulate 1 day)', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    print('[FoodDecay] FORCE DECAY for player ' .. source)
    
    -- Симулируем прошедшие сутки
    lastDecayCheck[source] = os.time() - 86500
    
    ProcessFoodDecay(source)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Force Decay',
        description = 'Simulated 1 day of decay',
        type = 'success',
        duration = 3000
    })
end, 'admin')

RSGCore.Commands.Add('checkdecay', 'Check food decay status', {}, false, function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local items = Player.PlayerData.items
    local decayItems = {}
    
    for slot, item in pairs(items) do
        if item and item.name and Config.FoodDecay and Config.FoodDecay[item.name] then
            local quality = 100
            if item.info and item.info.quality then
                quality = item.info.quality
            end
            table.insert(decayItems, {
                name = item.name,
                slot = slot,
                quality = quality,
                decayRate = Config.FoodDecay[item.name].decayRate
            })
        end
    end
    
    TriggerClientEvent('hud:client:ShowDecayInfo', source, decayItems)
    
    print('[FoodDecay] Items for ' .. Player.PlayerData.citizenid .. ':')
    for _, item in ipairs(decayItems) do
        print('  - ' .. item.name .. ' (slot ' .. item.slot .. '): ' .. item.quality .. '% (decay: ' .. item.decayRate .. '%/day)')
    end
end, 'admin')

RSGCore.Commands.Add('setquality', 'Set item quality', {{name = 'slot', help = 'Slot number'}, {name = 'quality', help = 'Quality 0-100'}}, false, function(source, args)
    local slot = tonumber(args[1])
    local quality = tonumber(args[2])
    
    if not slot or not quality then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Usage: /setquality [slot] [quality]', type = 'error' })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local item = Player.Functions.GetItemBySlot(slot)
    if not item then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'No item in slot ' .. slot, type = 'error' })
        return
    end
    
    if not item.info then
        item.info = {}
    end
    item.info.quality = math.max(0, math.min(100, quality))
    
    local items = Player.PlayerData.items
    items[slot] = item
    Player.Functions.SetInventory(items, true)
    
    TriggerClientEvent('ox_lib:notify', source, { 
        title = 'Quality Set', 
        description = item.name .. ' quality set to ' .. item.info.quality .. '%', 
        type = 'success' 
    })
    
    print('[FoodDecay] Admin set ' .. item.name .. ' quality to ' .. item.info.quality .. '%')
end, 'admin')

RSGCore.Commands.Add('setallquality', 'Set quality for all decayable items', {{name = 'quality', help = 'Quality 0-100'}}, false, function(source, args)
    local quality = tonumber(args[1])
    if not quality then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Error', description = 'Usage: /setallquality [0-100]', type = 'error' })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local items = Player.PlayerData.items
    local updated = 0
    
    for slot, item in pairs(items) do
        if item and item.name and Config.FoodDecay and Config.FoodDecay[item.name] then
            local decayConfig = Config.FoodDecay[item.name]
            if decayConfig.decayRate and decayConfig.decayRate > 0 then
                if not item.info then item.info = {} end
                item.info.quality = quality
                updated = updated + 1
                print('[FoodDecay] Set ' .. item.name .. ' (slot ' .. slot .. ') quality to ' .. quality)
            end
        end
    end
    
    if updated > 0 then
        Player.Functions.SetInventory(items, true)
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Quality Set',
        description = 'Updated ' .. updated .. ' items to ' .. quality .. '%',
        type = 'success',
        duration = 3000
    })
end, 'admin')

-- ═══════════════════════════════════════════════════════════════
-- STREAMER MODE SYSTEM
-- ═══════════════════════════════════════════════════════════════
local activeStreamers = {} -- {playerId = {citizenid, name, coords, lastUpdate}}
local lastNotificationTime = {} -- {playerId = timestamp} - для контроля интервала уведомлений

-- Включение/выключение режима стримера
RegisterNetEvent('hud:server:toggleStreamerMode', function(enabled)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local charinfo = Player.PlayerData.charinfo
    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
    
    if enabled then
        activeStreamers[src] = {
            citizenid = citizenid,
            name = playerName,
            coords = GetEntityCoords(GetPlayerPed(src)),
            lastUpdate = os.time()
        }
        print('[RSG-HUD] Streamer mode ENABLED for ' .. playerName .. ' (ID: ' .. src .. ')')
    else
        activeStreamers[src] = nil
        print('[RSG-HUD] Streamer mode DISABLED for ' .. playerName .. ' (ID: ' .. src .. ')')
    end
end)

-- Проверка стримеров поблизости
RegisterNetEvent('hud:server:checkNearbyStreamers', function(playerCoords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local nearbyStreamers = {}
    local radius = Config.StreamerMode and Config.StreamerMode.radius or 50.0
    local notificationInterval = Config.StreamerMode and Config.StreamerMode.notificationInterval or 1200000
    local currentTime = os.time() * 1000 -- в миллисекундах
    
    -- Если игрок сам стример - обновляем его координаты
    if activeStreamers[src] then
        activeStreamers[src].coords = vector3(playerCoords.x, playerCoords.y, playerCoords.z)
        activeStreamers[src].lastUpdate = os.time()
    end
    
    -- Проверяем всех активных стримеров
    for streamerId, streamerData in pairs(activeStreamers) do
        -- Не проверяем самого себя
        if streamerId ~= src then
            -- Проверяем актуальность данных стримера (не старше 30 секунд)
            if os.time() - streamerData.lastUpdate < 30 then
                local streamerCoords = streamerData.coords
                if streamerCoords then
                    local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - streamerCoords)
                    
                    if distance <= radius then
                        table.insert(nearbyStreamers, {
                            id = streamerId,
                            name = streamerData.name,
                            distance = distance
                        })
                        
                        -- Проверяем нужно ли отправить уведомление
                        local notifyKey = src .. '_' .. streamerId
                        if not lastNotificationTime[notifyKey] or (currentTime - lastNotificationTime[notifyKey]) >= notificationInterval then
                            -- Отправляем уведомление игроку
                            TriggerClientEvent('hud:client:streamerNearbyNotification', src, streamerData.name)
                            lastNotificationTime[notifyKey] = currentTime
                        end
                    end
                end
            else
                -- Удаляем неактивного стримера
                activeStreamers[streamerId] = nil
            end
        end
    end
    
    -- Отправляем клиенту список стримеров поблизости
    TriggerClientEvent('hud:client:updateNearbyStreamers', src, nearbyStreamers)
end)

-- Очистка при отключении игрока
AddEventHandler('playerDropped', function()
    local src = source
    if activeStreamers[src] then
        activeStreamers[src] = nil
        print('[RSG-HUD] Streamer ' .. src .. ' disconnected, removing from active list')
    end
    
    -- Очищаем записи уведомлений связанные с этим игроком
    for key, _ in pairs(lastNotificationTime) do
        if string.find(key, tostring(src)) then
            lastNotificationTime[key] = nil
        end
    end
end)

-- Команда для администраторов - просмотр активных стримеров
RSGCore.Commands.Add('streamers', 'View active streamers (Admin)', {}, false, function(source)
    local count = 0
    print('═══════════════════════════════════════════')
    print('         ACTIVE STREAMERS                  ')
    print('═══════════════════════════════════════════')
    
    for playerId, data in pairs(activeStreamers) do
        count = count + 1
        print(string.format('  [%d] %s (citizenid: %s)', playerId, data.name, data.citizenid))
    end
    
    if count == 0 then
        print('  No active streamers')
    end
    
    print('═══════════════════════════════════════════')
    print('Total: ' .. count)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Active Streamers',
        description = count .. ' streamer(s) online',
        type = 'inform',
        duration = 3000
    })
end, 'admin')