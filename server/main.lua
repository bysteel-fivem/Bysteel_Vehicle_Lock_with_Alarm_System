ESX = exports["es_extended"]:getSharedObject()

local sharedKeys = {}

local function trimPlate(plate)
    return string.gsub(plate or '', '^%s*(.-)%s*$', '%1')
end

local function Notify(id, data)
    TriggerClientEvent("ox_lib:notify", id, data)
end

-- =========================================================
-- VEHICLE OWNERSHIP / KEYS
-- IMPORTANT: This callback is registered exactly ONCE.
-- =========================================================

ESX.RegisterServerCallback('bysteel_carlock:getVeh', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cb(false)
        return
    end

    plate = trimPlate(plate)

    if plate == '' then
        cb(false)
        return
    end

    -- Shared key
    if sharedKeys[tostring(source)] and trimPlate(sharedKeys[tostring(source)]) == plate then
        cb("shared")
        return
    end

    -- Vehicle owner
    MySQL.Async.fetchAll(
        'SELECT 1 FROM owned_vehicles WHERE owner = @owner AND plate = @plate LIMIT 1',
        {
            ['@owner'] = xPlayer.identifier,
            ['@plate'] = plate
        },
        function(result)
            cb(result and result[1] ~= nil or false)
        end
    )
end)

-- =========================================================
-- SHARED KEYS
-- =========================================================

lib.callback.register('bysteel_carlock:shareKeys', function(source, target, plate)
    target = tonumber(target)
    plate = trimPlate(plate)

    if not target or not plate then
        return false
    end

    if sharedKeys[tostring(target)] and trimPlate(sharedKeys[tostring(target)]) == plate then
        Notify(source, {
            title = "Shared Keys",
            description = "Este jogador já possui as chaves desta viatura.",
            iconAnimation = "beat",
            type = "error",
            duration = 4000
        })
        return false
    end

    sharedKeys[tostring(target)] = plate

    Notify(target, {
        title = "Shared Keys",
        description = "Recebeste as chaves da viatura " .. plate,
        iconAnimation = "beat",
        type = "success",
        duration = 4000
    })

    Notify(source, {
        title = "Shared Keys",
        description = "Partilhaste as chaves da viatura " .. plate .. " com " .. (GetPlayerName(target) or "jogador"),
        iconAnimation = "beat",
        type = "success",
        duration = 4000
    })

    return true
end)

lib.callback.register('bysteel_carlock:removeKeys', function(source, target, plate)
    target = tonumber(target)
    plate = trimPlate(plate)

    if not target or plate == '' then
        return false
    end

    local key = tostring(target)

    if sharedKeys[key] and trimPlate(sharedKeys[key]) == plate then
        sharedKeys[key] = nil

        Notify(target, {
            title = "Shared Keys",
            description = "As tuas chaves da viatura " .. plate .. " foram removidas pelo proprietário.",
            iconAnimation = "beat",
            type = "error",
            duration = 4000
        })

        Notify(source, {
            title = "Shared Keys",
            description = "Removeste as chaves da viatura " .. plate .. " desse jogador.",
            iconAnimation = "beat",
            type = "success",
            duration = 4000
        })

        return true
    end

    return false
end)

lib.callback.register('bysteel_carlock:getSharedKeys', function(source, plate)
    plate = trimPlate(plate)

    if plate == '' then
        return {}
    end

    local toreturn = {}

    for playerId, sharedPlate in pairs(sharedKeys) do
        if trimPlate(sharedPlate) == plate then
            local id = tonumber(playerId)

            table.insert(toreturn, {
                id = id,
                plate = sharedPlate,
                player = id and GetPlayerName(id) or 'Jogador offline'
            })
        end
    end

    return toreturn
end)

exports("shareKey", function(playerId, plate)
    playerId = tonumber(playerId)
    plate = trimPlate(plate)

    if not playerId or plate == '' then
        return false
    end

    local key = tostring(playerId)

    if sharedKeys[key] and trimPlate(sharedKeys[key]) == plate then
        return false
    end

    sharedKeys[key] = plate
    return true
end)

-- =========================================================
-- LOCKPICK
-- =========================================================

local function hasLockpick(source)
    local itemName = 'lockpick'

    if BySteel and BySteel.Lockpick and BySteel.Lockpick.Item then
        itemName = BySteel.Lockpick.Item
    end

    local count = exports.ox_inventory:Search(source, 'count', itemName)

    return (count or 0) > 0
end

lib.callback.register('bysteel_carlock:server:hasLockpick', function(source)
    return hasLockpick(source)
end)

lib.callback.register('bysteel_carlock:server:prepareLockpick', function(source, plate)
    if not hasLockpick(source) then
        return {
            hasLockpick = false,
            hasAlarm = false
        }
    end

    plate = trimPlate(plate)

    if plate == '' then
        return {
            hasLockpick = true,
            hasAlarm = false
        }
    end

    local vehicleAlarm = MySQL.scalar.await(
        'SELECT vehicle_alarm FROM owned_vehicles WHERE plate = ? LIMIT 1',
        { plate }
    )

    return {
        hasLockpick = true,
        hasAlarm = vehicleAlarm == true or tonumber(vehicleAlarm) == 1
    }
end)

lib.callback.register('bysteel_carlock:server:completeLockpick', function(source, plate)
    local itemName = 'lockpick'

    if BySteel and BySteel.Lockpick and BySteel.Lockpick.Item then
        itemName = BySteel.Lockpick.Item
    end

    local count = exports.ox_inventory:Search(source, 'count', itemName)

    if not count or count < 1 then
        return {
            success = false,
            hasAlarm = false
        }
    end

    plate = trimPlate(plate)

    if plate == '' then
        return {
            success = false,
            hasAlarm = false
        }
    end

    local vehicleAlarm = MySQL.scalar.await(
        'SELECT vehicle_alarm FROM owned_vehicles WHERE plate = ? LIMIT 1',
        { plate }
    )
    local hasAlarm = vehicleAlarm == true or tonumber(vehicleAlarm) == 1

    local removed = exports.ox_inventory:RemoveItem(source, itemName, 1)

    if removed ~= true then
        return {
            success = false,
            hasAlarm = hasAlarm
        }
    end

    if Logs and Logs.VehicleLockpicked then
        Logs.VehicleLockpicked(source, plate, hasAlarm)
    end

    if hasAlarm then
        local alarmCfg = BySteel and BySteel.Lockpick and BySteel.Lockpick.Alarm or {}
        local postUnlockDuration = math.max(tonumber(alarmCfg.PostUnlockDuration) or 15000, 0)

        SetTimeout(postUnlockDuration, function()
            MySQL.update.await(
                'UPDATE owned_vehicles SET vehicle_alarm = 0 WHERE plate = ? AND vehicle_alarm = 1',
                { plate }
            )
        end)
    end

    return {
        success = true,
        hasAlarm = hasAlarm
    }
end)

-- =========================================================
-- ALARM INSTALLATION
-- =========================================================

local function getAlarmInstallationConfig()
    return BySteel and BySteel.AlarmInstallation or {}
end

local function canInstallAlarm(xPlayer)
    if not xPlayer or not xPlayer.job or not xPlayer.job.name then
        return false
    end

    local allowedJobs = getAlarmInstallationConfig().AllowedJobs or {}
    local minimumGrade = allowedJobs[xPlayer.job.name]

    if minimumGrade == nil or minimumGrade == false then
        return false
    end

    if minimumGrade == true then
        return true
    end

    return (tonumber(xPlayer.job.grade) or 0) >= (tonumber(minimumGrade) or 0)
end

local function getAlarmInstallationStatus(source, plate)
    local cfg = getAlarmInstallationConfig()

    if cfg.Enabled == false then
        return 'disabled'
    end

    local xPlayer = ESX.GetPlayerFromId(source)

    if not canInstallAlarm(xPlayer) then
        return 'not_allowed'
    end

    local itemName = cfg.Item or 'vehicle_alarm'
    local count = exports.ox_inventory:Search(source, 'count', itemName)

    if not count or count < 1 then
        return 'no_item'
    end

    plate = trimPlate(plate)

    if plate == '' then
        return 'invalid_vehicle'
    end

    local vehicle = MySQL.single.await(
        'SELECT vehicle_alarm FROM owned_vehicles WHERE plate = ? LIMIT 1',
        { plate }
    )

    if not vehicle then
        return 'not_owned'
    end

    if vehicle.vehicle_alarm == true or tonumber(vehicle.vehicle_alarm) == 1 then
        return 'already_installed'
    end

    return 'ready'
end

lib.callback.register('bysteel_carlock:server:prepareAlarmInstallation', function(source, plate)
    return getAlarmInstallationStatus(source, plate)
end)

lib.callback.register('bysteel_carlock:server:completeAlarmInstallation', function(source, plate)
    local status = getAlarmInstallationStatus(source, plate)

    if status ~= 'ready' then
        return status
    end

    plate = trimPlate(plate)

    local updated = MySQL.update.await(
        'UPDATE owned_vehicles SET vehicle_alarm = 1 WHERE plate = ? AND COALESCE(vehicle_alarm, 0) = 0',
        { plate }
    )

    if not updated or updated < 1 then
        return 'already_installed'
    end

    local cfg = getAlarmInstallationConfig()

    if cfg.RemoveOnSuccess ~= false then
        local itemName = cfg.Item or 'vehicle_alarm'
        local removed = exports.ox_inventory:RemoveItem(source, itemName, 1)

        if removed ~= true then
            MySQL.update.await(
                'UPDATE owned_vehicles SET vehicle_alarm = 0 WHERE plate = ?',
                { plate }
            )

            return 'no_item'
        end
    end

    if Logs and Logs.AlarmInstalled then
        Logs.AlarmInstalled(source, plate)
    end

    return 'success'
end)
