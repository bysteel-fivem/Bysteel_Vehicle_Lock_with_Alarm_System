ESX = exports["es_extended"]:getSharedObject()

-- Ox_Target stuff

local options =     {
	{
		name = 'bysteel_carlock:target',
		icon = BySteel.targetIcon,
		label = BySteel.Locale["TargetLabel"],
		onSelect = function(data)
			ToggleLock(data.entity)
		end
	},
	{
		name = 'bysteel_carlock:share',
		icon = "fa-solid fa-key",
		label = "Gerir Chaves",
		onSelect = function(data)
			lib.registerContext(
			    {
			        id = "manage_keys",
			        title = "Gerir Chaves da Viatura",
			        options = {
			            {
			                title = "Partilhar chaves",
			                icon = "key",
			                onSelect = function()
			                    ESX.TriggerServerCallback('bysteel_carlock:getVeh', function(Owned)
									if Owned == "shared" then
										--lib.notify({
										--	title = BySteel.Locale["NotifyTitle"],
										--	description = "Não pode aceder a este menu com chaves partilhadas",
										--	position = 'bottom-right',
										--	style = {
										--		backgroundColor = '#1e2e2ed2',
										--		color = '#C1C2C5',
										--		['.description'] = {
										--		color = '#909296'
										--		}
										--	},
										--	icon = 'triangle-exclamation',
										--	iconColor = '#be2525'
										--})
										exports['fx_notify']:fx_notify("error", BySteel.Locale["NotifyTitle"], "Não pode aceder a este menu com chaves partilhadas", "5000")
									end

									if Owned == true then
										local opt = {}
										for k,v in pairs(GetActivePlayers()) do
											table.insert(opt,{
												value = GetPlayerServerId(v), label = ('[%s] %s'):format(GetPlayerServerId(v),GetPlayerName(v))
											})
										end
										local player = lib.inputDialog("Escolher pessoa", {
											{
												type = 'select',
												label = "Selecionar a pessoa com quem quer partilhar a chave",
												icon = "person",
												options = opt
											},
										})
										if player then
											lib.callback.await('bysteel_carlock:shareKeys', 250, player[1],GetVehicleNumberPlateText(data.entity))
										end
									end
							
								end, ESX.Math.Trim(GetVehicleNumberPlateText(data.entity)))
			                end
			            },
			            {
			                title = "Remover a partilha de chaves",
			                icon = "trash-alt",
			                onSelect = function()
								local keys = lib.callback.await('bysteel_carlock:getSharedKeys', 250, GetVehicleNumberPlateText(data.entity))
								local opt = {}
								if #keys == 0 then
									opt = {
										{
											title = "Ainda não partilhou a chaves da viatura com outro cidadão.",
											disabled = true
										}
									}
								else
									for k,v in pairs(keys) do
										table.insert(opt,{
											
												title = ("[%s] %s"):format(v.id,v.player),
												description = ("Matricula: %s"):format(v.plate),
												icon = "trash-alt",
												onSelect = function ()
													local confirm =
														lib.alertDialog(
														{
															header = "Atenção",
															content = ("Retirar o acesso a chave da viatura %s do %s"):format(v.plate,v.player),
															centered = true,
															cancel = true
														}
													)
													if confirm == "confirm" then
														lib.callback.await('bysteel_carlock:removeKeys', 250, v.id,v.plate)				
													end
													
												end
											
										})
									end
								end
								lib.registerContext({
									id = "remove_options",
									title = "Escolher o cidadão",
									options = opt
								})
								lib.showContext("remove_options")
			                end
			            }
			        }
			    }
			)
			lib.showContext("manage_keys")
		end
	},
}

if BySteel.targetSupport then exports.ox_target:addGlobalVehicle(options) end

-- Main functions

local function vehLights(vehicle)
	SetVehicleLights(vehicle, 2)
	Wait(200)
	SetVehicleLights(vehicle, 0)
	Wait(150)
	SetVehicleLights(vehicle, 2)
	Wait(500)
	SetVehicleLights(vehicle, 0)
end
local function vehHorn(vehicle)
	StartVehicleHorn(vehicle, 200, "HELDDOWN", false)
	Wait(300)
	StartVehicleHorn(vehicle, 150, "HELDDOWN", false)
end

function ToggleLock(entity)
	local vehicle
	local ped = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(ped))
	if not entity then
		if IsPedInAnyVehicle(ped, false) then
			vehicle = GetVehiclePedIsIn(ped, false)
		else
			vehicle = GetClosestVehicle(x,y,z, 8.0, 0, 71)
		end
	else
		vehicle = entity
	end
	if not DoesEntityExist(vehicle) then
		if BySteel.Notifications.NoNearbyVehicles then
			--lib.notify({
			--	title = BySteel.Locale["NotifyTitle"],
			--	description = BySteel.Locale["NoVehicleNearby"],
			--	position = 'bottom-right',
			--	style = {
			--		backgroundColor = '#1e2e2ed2',
			--		color = '#C1C2C5',
			--		['.description'] = {
			--		color = '#909296'
			--		}
			--	},
			--	icon = 'triangle-exclamation',
			--	iconColor = '#be2525'
			--})
			exports['fx_notify']:fx_notify("error", BySteel.Locale["NotifyTitle"], BySteel.Locale["NoVehicleNearby"], "5000")
		end
		return
	end

	ESX.TriggerServerCallback('bysteel_carlock:getVeh', function(Owned)

		if Owned or Owned == "shared" then
			local lockStatus = GetVehicleDoorLockStatus(vehicle)

			if lockStatus == 1 then -- Vehicle is unlocked
				SetVehicleDoorsLocked(vehicle, 2)
				if BySteel.commandOnLock then ExecuteCommand(BySteel.commandOnLock) end
				lib.progressCircle({
					duration = BySteel.progressLength,
					label = BySteel.Locale['ProgressLocking'],
					position = 'bottom-right',
					useWhileDead = false,
					canCancel = false,
					disable = BySteel.ToDisable,
					anim = BySteel.Anim,

				})
				if BySteel.Notifications.Locked then
					--lib.notify({
					--	title = BySteel.Locale["NotifyTitle"],
					--	description = BySteel.Locale["NotifyLocked"],
					--	position = 'bottom-right',
					--	style = {
					--		backgroundColor = '#1e2e2ed2',
					--		color = '#C1C2C5',
					--		['.description'] = {
					--		color = '#909296'
					--		}
					--	},
					--	icon = 'lock',
					--	iconColor = '#be2525'
					--})
					exports['fx_notify']:fx_notify("info", BySteel.Locale["NotifyTitle"], BySteel.Locale["NotifyLocked"], "5000")
				end
				if BySteel.Sounds then PlaySoundFromCoord(-1,"PIN_BUTTON",x,y,z,"ATM_SOUNDS", true, 5, false) end
				vehLights(vehicle)
			elseif lockStatus == 2 then -- Vehicle is locked
				SetVehicleDoorsLocked(vehicle, 1)
				if BySteel.commandOnUnLock then ExecuteCommand(BySteel.commandOnUnLock) end
				lib.progressCircle({
					duration = BySteel.progressLength,
					label = BySteel.Locale['ProgressUnLocking'],
					position = 'bottom',
					useWhileDead = false,
					canCancel = false,
					disable = BySteel.ToDisable,
					anim = BySteel.Anim,

				})				
				if BySteel.Notifications.Unlocked then
					--lib.notify({
					--	title = BySteel.Locale["NotifyTitle"],
					--	description = BySteel.Locale["NotifyUnLocked"],
					--	position = 'bottom-right',
					--	style = {
					--		backgroundColor = '#1e2e2ed2',
					--		color = '#C1C2C5',
					--		['.description'] = {
					--		color = '#909296'
					--		}
					--	},
					--	icon = 'lock-open',
					--	iconColor = '#49be25'
					--})
					exports['fx_notify']:fx_notify("info", BySteel.Locale["NotifyTitle"], BySteel.Locale["NotifyUnLocked"], "5000")
				end
				if BySteel.Sounds then PlaySoundFromCoord(-1,"PIN_BUTTON",x,y,z,"ATM_SOUNDS", true, 5, false) end
				if BySteel.Horn then vehHorn(vehicle) end
				if BySteel.Lights then vehLights(vehicle) end
			end
		else
			if BySteel.Notifications.NotYourVehicle then
				--lib.notify({
				--	title = BySteel.Locale["NotifyTitle"],
				--	description = BySteel.Locale["NotOwned"],
				--	position = 'bottom-right',
				--	style = {
				--		backgroundColor = '#1e2e2ed2',
				--		color = '#C1C2C5',
				--		['.description'] = {
				--		color = '#909296'
				--		}
				--	},
				--	icon = 'triangle-exclamation',
				--	iconColor = '#be2525'
				--})
				exports['fx_notify']:fx_notify("error", BySteel.Locale["NotifyTitle"], BySteel.Locale["NotOwned"], "5000")
				return
			end
		end

	end, ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
end


-- Check if the player is sitting in locked vehicle
Citizen.CreateThread(function ()
		while true do
			Wait(0)
			if IsPedInAnyVehicle(PlayerPedId(),false) and GetVehicleDoorLockStatus(GetVehiclePedIsIn(PlayerPedId(),false)) == 2 then
				DisableControlAction(0,75,true)
			elseif not IsPedInAnyVehicle(PlayerPedId(),false) then
				EnableControlAction(0,75,true)
			else
				EnableControlAction(0,75,true)
			end
		end
end)


RegisterCommand('carlock',function ()
	ToggleLock()
	Citizen.Wait(300)
end,false)
RegisterKeyMapping('carlock', 'Trancar/Destrancar viatura pessoal', 'keyboard', 'l')

-- =========================================================
-- BYSTEEL LOCKPICK
-- =========================================================

local lockpickBusy = false
local alarmInstallBusy = false

local function BySteelLockpickNotify(notifyType, message)
    exports['fx_notify']:fx_notify(
        notifyType,
        'Carlock',
        message,
        '5000'
    )
end

local function BySteelGetLockpickConfig()
    if BySteel and BySteel.Lockpick then
        return BySteel.Lockpick
    end

    return {
        Enabled = true,
        Item = 'lockpick',
        Duration = 7000,
        Label = 'A arrombar a viatura...',
        CanCancel = true,
        Disable = {
            move = true,
            car = true,
            combat = true,
        },
        Animation = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
        Alarm = {
            Enabled = true,
            Duration = 14000,
            PostUnlockDuration = 15000,
            BlinkInterval = 450,
            HornDuration = 400,
            DispatchJobs = { 'police' },
            DispatchMessage = 'Tentativa de furto de viatura',
            DispatchCode = '10-60',
            DispatchBlip = 161,
            DispatchColor = 1,
        },
    }
end

local function BySteelGetAlarmInstallationConfig()
    if BySteel and BySteel.AlarmInstallation then
        return BySteel.AlarmInstallation
    end

    return {
        Enabled = true,
        Item = 'vehicle_alarm',
        AllowedJobs = {
            mechanic = 0,
        },
        Duration = 10000,
        Label = 'A instalar o alarme...',
        TargetLabel = 'Instalar alarme',
        TargetIcon = 'fa-solid fa-shield-halved',
        TargetDistance = 2.0,
        CanCancel = true,
        RemoveOnSuccess = true,
        Disable = {
            move = true,
            car = true,
            combat = true,
        },
        Animation = {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    }
end

local function BySteelCanInstallAlarm()
    local playerData = ESX.GetPlayerData()
    local job = playerData and playerData.job

    if not job or not job.name then
        return false
    end

    local cfg = BySteelGetAlarmInstallationConfig()
    local minimumGrade = (cfg.AllowedJobs or {})[job.name]

    if minimumGrade == nil or minimumGrade == false then
        return false
    end

    if minimumGrade == true then
        return true
    end

    return (tonumber(job.grade) or 0) >= (tonumber(minimumGrade) or 0)
end

local function BySteelAlarmInstallationNotify(status)
    local locale = BySteel.AlarmInstallationLocale or {}
    local messages = {
        not_allowed = locale.NoPermission or 'O teu emprego não está autorizado a instalar alarmes.',
        no_item = locale.NoItem or 'Não tens um alarme de viatura contigo.',
        already_installed = locale.AlreadyInstalled or 'Esta viatura já tem um alarme instalado.',
        not_owned = locale.NotOwned or 'Esta viatura não está registada em owned_vehicles.',
        invalid_vehicle = locale.InvalidVehicle or 'Não foi encontrada nenhuma viatura válida.',
        cancelled = locale.Cancelled or 'Cancelaste a instalação do alarme.',
        success = locale.Success or 'Alarme instalado com sucesso.',
        disabled = locale.Failed or 'Não foi possível instalar o alarme.',
        failed = locale.Failed or 'Não foi possível instalar o alarme.',
    }

    BySteelLockpickNotify(status == 'success' and 'success' or 'error', messages[status] or messages.failed)
end

local function BySteelIsVehicleLocked(vehicle)
    if not vehicle or vehicle == 0 then
        return false
    end

    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        return false
    end

    local status = GetVehicleDoorLockStatus(vehicle)

    return status == 2
        or status == 3
        or status == 4
        or status == 7
        or status == 8
end

local function BySteelTriggerAlarmDispatch(vehicle, alarmCfg)
    local coords = GetEntityCoords(PlayerPedId(), true)
    local playerPos = vector3(coords.x, coords.y, coords.z)
    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local message = alarmCfg.DispatchMessage or 'Tentativa de furto de viatura'

    if plate ~= '' then
        message = ('%s | Matrícula: %s'):format(message, plate)
    end

    TriggerServerEvent(
        'dynamic_dispatch:CreateDispatch',
        alarmCfg.DispatchJobs or { 'police' },
        message,
        alarmCfg.DispatchCode or '10-60',
        playerPos,
        alarmCfg.DispatchBlip or 161,
        alarmCfg.DispatchColor or 1
    )
end

local function BySteelStartAlarmEffect(vehicle, alarmCfg)
    local active = true
    local blinkInterval = math.max(tonumber(alarmCfg.BlinkInterval) or 450, 100)
    local hornDuration = math.max(tonumber(alarmCfg.HornDuration) or 400, 100)

    CreateThread(function()
        while active and DoesEntityExist(vehicle) do
            if not NetworkHasControlOfEntity(vehicle) then
                NetworkRequestControlOfEntity(vehicle)
            end

            SetVehicleLights(vehicle, 2)
            StartVehicleHorn(vehicle, hornDuration, 'HELDDOWN', false)
            Wait(blinkInterval)

            if DoesEntityExist(vehicle) then
                SetVehicleLights(vehicle, 0)
            end

            Wait(blinkInterval)
        end

        if DoesEntityExist(vehicle) then
            SetVehicleLights(vehicle, 0)
        end
    end)

    return function()
        active = false

        if DoesEntityExist(vehicle) then
            SetVehicleLights(vehicle, 0)
        end
    end
end

function StartLockpick(vehicle)
    if lockpickBusy then
        return
    end

    local cfg = BySteelGetLockpickConfig()

    if cfg.Enabled == false then
        return
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        BySteelLockpickNotify('error', 'Não foi encontrada nenhuma viatura válida.')
        return
    end

    if not IsEntityAVehicle(vehicle) then
        BySteelLockpickNotify('error', 'O alvo selecionado não é uma viatura.')
        return
    end

    if not BySteelIsVehicleLocked(vehicle) then
        BySteelLockpickNotify('error', 'Esta viatura já está destrancada.')
        return
    end

    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local lockpickData = lib.callback.await(
        'bysteel_carlock:server:prepareLockpick',
        false,
        plate
    )

    if not lockpickData or not lockpickData.hasLockpick then
        BySteelLockpickNotify('error', 'Não tens uma lockpick contigo.')
        return
    end

    lockpickBusy = true

    local ped = PlayerPedId()
    local alarmCfg = cfg.Alarm or {}
    local hasAlarm = lockpickData.hasAlarm == true and alarmCfg.Enabled ~= false
    local stopAlarmEffect

    TaskTurnPedToFaceEntity(ped, vehicle, 500)
    Wait(300)

    if hasAlarm then
        BySteelTriggerAlarmDispatch(vehicle, alarmCfg)
        stopAlarmEffect = BySteelStartAlarmEffect(vehicle, alarmCfg)
    end

    local completed = lib.progressCircle({
        duration = hasAlarm and (alarmCfg.Duration or 14000) or (cfg.Duration or 7000),
        label = cfg.Label or 'A arrombar a viatura...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = cfg.CanCancel ~= false,
        disable = cfg.Disable or {
            move = true,
            car = true,
            combat = true,
        },
        anim = cfg.Animation or {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    ClearPedTasks(ped)

    if not completed then
        if stopAlarmEffect then
            stopAlarmEffect()
        end

        lockpickBusy = false
        BySteelLockpickNotify('error', 'Cancelaste o arrombamento da viatura.')
        return
    end

    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        if stopAlarmEffect then
            stopAlarmEffect()
        end

        lockpickBusy = false
        BySteelLockpickNotify('error', 'A viatura deixou de estar disponível.')
        return
    end

    if not BySteelIsVehicleLocked(vehicle) then
        if stopAlarmEffect then
            stopAlarmEffect()
        end

        lockpickBusy = false
        BySteelLockpickNotify('error', 'A viatura já não está trancada.')
        return
    end

    -- O servidor valida novamente e remove a lockpick.
    local lockpickResult = lib.callback.await(
        'bysteel_carlock:server:completeLockpick',
        false,
        plate
    )

    if not lockpickResult or not lockpickResult.success then
        if stopAlarmEffect then
            stopAlarmEffect()
        end

        lockpickBusy = false
        BySteelLockpickNotify('error', 'Não foi possível utilizar a lockpick.')
        return
    end

    if stopAlarmEffect then
        if lockpickResult.hasAlarm then
            local alarmStop = stopAlarmEffect
            local postUnlockDuration = math.max(tonumber(alarmCfg.PostUnlockDuration) or 15000, 0)

            CreateThread(function()
                Wait(postUnlockDuration)
                alarmStop()
            end)
        else
            stopAlarmEffect()
        end

        stopAlarmEffect = nil
    end

    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)

    BySteelLockpickNotify('success', 'Conseguiste arrombar a viatura.')

    Wait(300)

    if DoesEntityExist(vehicle) then
        -- Abre a porta do condutor
        SetVehicleDoorOpen(vehicle, 0, false, false)

        -- Faz o jogador entrar normalmente na viatura
        TaskEnterVehicle(ped, vehicle, -1, -1, 1.0, 1, 0)

        -- Aguarda até o jogador estar dentro
        local timeout = GetGameTimer() + 10000

        while not IsPedInVehicle(ped, vehicle, false) and GetGameTimer() < timeout do
            Wait(100)
        end

        -- Fecha a porta depois de entrar
        if IsPedInVehicle(ped, vehicle, false) then
            SetVehicleDoorShut(vehicle, 0, false)

            -- Liga o motor
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleUndriveable(vehicle, false)
        end
    end

    lockpickBusy = false
end

local function StartAlarmInstallation(vehicle)
    if alarmInstallBusy or lockpickBusy then
        return
    end

    local cfg = BySteelGetAlarmInstallationConfig()

    if cfg.Enabled == false then
        return
    end

    if not BySteelCanInstallAlarm() then
        BySteelAlarmInstallationNotify('not_allowed')
        return
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        BySteelAlarmInstallationNotify('invalid_vehicle')
        return
    end

    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
    local status = lib.callback.await(
        'bysteel_carlock:server:prepareAlarmInstallation',
        false,
        plate
    )

    if status ~= 'ready' then
        BySteelAlarmInstallationNotify(status or 'failed')
        return
    end

    alarmInstallBusy = true

    local ped = PlayerPedId()

    TaskTurnPedToFaceEntity(ped, vehicle, 500)
    Wait(300)

    local completed = lib.progressCircle({
        duration = cfg.Duration or 10000,
        label = cfg.Label or 'A instalar o alarme...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = cfg.CanCancel ~= false,
        disable = cfg.Disable or {
            move = true,
            car = true,
            combat = true,
        },
        anim = cfg.Animation or {
            dict = 'mini@repair',
            clip = 'fixing_a_player',
        },
    })

    ClearPedTasks(ped)

    if not completed then
        alarmInstallBusy = false
        BySteelAlarmInstallationNotify('cancelled')
        return
    end

    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        alarmInstallBusy = false
        BySteelAlarmInstallationNotify('invalid_vehicle')
        return
    end

    local result = lib.callback.await(
        'bysteel_carlock:server:completeAlarmInstallation',
        false,
        plate
    )

    alarmInstallBusy = false
    BySteelAlarmInstallationNotify(result or 'failed')
end

CreateThread(function()
    Wait(1000)

    if not BySteel.targetSupport then
        return
    end

    exports.ox_target:addGlobalVehicle({
        {
            name = 'bysteel_carlock:lockpick',
            icon = BySteel.Lockpick.TargetIcon or 'fa-solid fa-screwdriver-wrench',
            label = BySteel.Lockpick.TargetLabel or 'Arrombar viatura',
            distance = BySteel.Lockpick.TargetDistance or 2.0,

            canInteract = function(entity)
                if lockpickBusy or alarmInstallBusy then
                    return false
                end

                local cfg = BySteelGetLockpickConfig()

                if cfg.Enabled == false then
                    return false
                end

                return BySteelIsVehicleLocked(entity)
            end,

            onSelect = function(data)
                StartLockpick(data.entity)
            end
        },
        {
            name = 'bysteel_carlock:install_alarm',
            icon = BySteel.AlarmInstallation.TargetIcon or 'fa-solid fa-shield-halved',
            label = BySteel.AlarmInstallation.TargetLabel or 'Instalar alarme',
            distance = BySteel.AlarmInstallation.TargetDistance or 2.0,

            canInteract = function(entity)
                if lockpickBusy or alarmInstallBusy then
                    return false
                end

                local cfg = BySteelGetAlarmInstallationConfig()

                if cfg.Enabled == false or not BySteelCanInstallAlarm() then
                    return false
                end

                return DoesEntityExist(entity) and IsEntityAVehicle(entity)
            end,

            onSelect = function(data)
                StartAlarmInstallation(data.entity)
            end
        }
    })
end)
