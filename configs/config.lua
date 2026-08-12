BySteel = {}

BySteel.targetSupport = true -- You can enable ox_target support!

BySteel.targetIcon = 'fa-solid fa-lock' -- https://fontawesome.com/search - Search icons here (only the free ones will work)

BySteel.progressLength = 850 -- In ms, how long should it take to unlock the vehicle

BySteel.checkRadius = 5.0 -- Radius to check for vehicles around the player

BySteel.commandOnLock = false
BySteel.commandOnUnLock = false

BySteel.Sounds = true -- Play sound in small radius on lock/unlock

BySteel.Horn = true -- Enable horn on vehicle unlock

BySteel.Lights = true -- Enable short headlight flash when locking/unlocking

BySteel.Notifications = { -- Which notifications to display?
    Locked = true, -- When locking vehicle
    Unlocked = true, -- When unlocking vehicle
    NotYourVehicle = true, -- When the nearest vehicle doesn't belong to player
    NoNearbyVehicles = true -- When there's no nearby vehicles
}

BySteel.ToDisable = { -- Which one of these should be disabled while locking/unlocking vehicles?
    car = true, -- Disable car movement
    move = false, -- Disable player movement
    combat = true -- Disable shooting, aiming and other combat stuff
}

BySteel.Anim = {
    dict = 'anim@mp_player_intmenu@key_fob@',
    clip = 'fob_click_fp'
}

BySteel.Locale = {
    ["ProgressLocking"] = "A trancar...",
    ["ProgressUnLocking"] = "A destrancar...",

    ["TargetLabel"] = "Trancar/Destrancar",

    ["NotifyTitle"] = "Sistema de Fecho Central",
    ["NotifyLocked"] = "Viatura trancada.",
    ["NotifyUnLocked"] = "Viatura destrancada.",
    ["NoVehicleNearby"] = "Não existem viaturas próximas.",
    ["NotOwned"] = "Essa viatura não lhe pertence.",
    ["LockedWhileInside"] = "Não pode sair com o carro trancado!",
}


-- =========================================================
-- LOCKPICK
-- =========================================================
BySteel.Lockpick = {
    Enabled = true,
    Item = 'lockpick',
    Duration = 7000,
    Label = 'A arrombar a viatura...',
    TargetLabel = 'Arrombar viatura',
    TargetIcon = 'fa-solid fa-screwdriver-wrench',
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
    Alarm = {
        Enabled = true,
        Duration = 14000, -- Tempo da lockpick quando vehicle_alarm = 1
        PostUnlockDuration = 15000, -- Continua a tocar após a abertura e depois é removido
        BlinkInterval = 450,
        HornDuration = 400,
        DispatchJobs = { 'police' },
        DispatchMessage = 'Tentativa de furto de viatura',
        DispatchCode = '10-60',
        DispatchBlip = 161,
        DispatchColor = 1,
    },
}

BySteel.LockpickLocale = {
    NoLockpick = 'Não tens uma lockpick contigo.',
    NotLocked = 'Esta viatura já está destrancada.',
    Cancelled = 'Cancelaste o arrombamento da viatura.',
    Success = 'Conseguiste arrombar a viatura.',
    Failed = 'Não foi possível arrombar a viatura.',
}


-- =========================================================
-- INSTALAÇÃO DO ALARME
-- =========================================================
BySteel.AlarmInstallation = {
    Enabled = true,
    Item = 'vehicle_alarm',

    -- job = nível mínimo. Adiciona aqui todos os jobs autorizados.
    AllowedJobs = {
        mechanic = 0,
        -- mechanic2 = 0,
    },

    -- Nome da oficina apresentado nos logs STAFF.
    WorkshopLabels = {
        mechanic = 'Mecânicos',
        -- mechanic2 = 'Benny\'s',
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

BySteel.AlarmInstallationLocale = {
    NoPermission = 'O teu emprego não está autorizado a instalar alarmes.',
    NoItem = 'Não tens um alarme de viatura contigo.',
    AlreadyInstalled = 'Esta viatura já tem um alarme instalado.',
    NotOwned = 'Esta viatura não está registada em owned_vehicles.',
    InvalidVehicle = 'Não foi encontrada nenhuma viatura válida.',
    Cancelled = 'Cancelaste a instalação do alarme.',
    Success = 'Alarme instalado com sucesso.',
    Failed = 'Não foi possível instalar o alarme.',
}
