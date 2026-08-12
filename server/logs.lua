Logs = {}

-- Este ficheiro é carregado apenas no servidor; o webhook não é enviado aos clientes.
local Config = {
    Enabled = true,
    Webhook = '', -- Coloca aqui o webhook Discord dos logs STAFF
    Username = 'DynamicRP - Carlock Logs',
    Avatar = 'https://r2.fivemanage.com/lECm2eIDwAngfgot9G1fg/DynamicRP_SemFundoSemTexto.png',
    Footer = {
        text = '🌆 𝗗𝘆𝗻𝗮𝗺𝗶𝗰𝗥𝗣 🌆 | 𝚊 𝚗𝚎𝚠 𝚠𝚘𝚛𝚕𝚍',
        icon_url = 'https://r2.fivemanage.com/lECm2eIDwAngfgot9G1fg/DynamicRP_SemFundoSemTexto.png'
    },
    Colors = {
        lockpick = 15105570,
        installation = 3066993,
    }
}

local function getPlayerDetails(source)
    local xPlayer = ESX and ESX.GetPlayerFromId(source)
    local name = GetPlayerName(source) or 'Desconhecido'
    local identifier = xPlayer and xPlayer.identifier or 'Desconhecido'
    local discord = 'Não associado'

    if xPlayer and xPlayer.getName then
        name = xPlayer.getName() or name
    end

    for _, playerIdentifier in ipairs(GetPlayerIdentifiers(source)) do
        local discordId = playerIdentifier:match('^discord:(.+)$')

        if discordId then
            discord = ('<@%s> (`%s`)'):format(discordId, discordId)
            break
        end
    end

    return {
        name = name,
        serverId = source,
        identifier = identifier,
        discord = discord,
        job = xPlayer and xPlayer.job or nil,
    }
end

local function sendLog(title, description, color, fields)
    if not Config.Enabled or Config.Webhook == '' then
        return
    end

    local payload = {
        username = Config.Username,
        avatar_url = Config.Avatar,
        embeds = {{
            color = color,
            title = title,
            description = description,
            fields = fields,
            footer = Config.Footer,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    }

    PerformHttpRequest(Config.Webhook, function(statusCode)
        if statusCode ~= 200 and statusCode ~= 204 then
            print(('[bysteel_carlock] Falha ao enviar log STAFF (HTTP %s).'):format(statusCode))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

function Logs.VehicleLockpicked(source, plate, hadAlarm)
    local player = getPlayerDetails(source)

    sendLog(
        '🔓 CARRO ASSALTADO COM LOCKPICK',
        ('**%s** concluiu o arrombamento de uma viatura.'):format(player.name),
        Config.Colors.lockpick,
        {
            {
                name = 'Jogador',
                value = ('%s | ID `%s`'):format(player.name, player.serverId),
                inline = true
            },
            {
                name = 'Matrícula',
                value = ('`%s`'):format(plate),
                inline = true
            },
            {
                name = 'Tinha alarme?',
                value = hadAlarm and '✅ Sim' or '❌ Não',
                inline = true
            },
            {
                name = 'Discord',
                value = player.discord,
                inline = false
            },
            {
                name = 'Identificador ESX',
                value = ('`%s`'):format(player.identifier),
                inline = false
            }
        }
    )
end

function Logs.AlarmInstalled(source, plate)
    local mechanic = getPlayerDetails(source)
    local job = mechanic.job or {}
    local installationCfg = BySteel and BySteel.AlarmInstallation or {}
    local workshopLabels = installationCfg.WorkshopLabels or {}
    local workshop = workshopLabels[job.name] or job.label or job.name or 'Desconhecida'
    local grade = job.grade_label or tostring(job.grade or 'Desconhecido')

    sendLog(
        '🛡️ ALARME INSTALADO NA VIATURA',
        ('**%s** instalou um sistema de alarme.'):format(mechanic.name),
        Config.Colors.installation,
        {
            {
                name = 'Mecânico',
                value = ('%s | ID `%s`'):format(mechanic.name, mechanic.serverId),
                inline = true
            },
            {
                name = 'Oficina',
                value = workshop,
                inline = true
            },
            {
                name = 'Cargo',
                value = grade,
                inline = true
            },
            {
                name = 'Matrícula',
                value = ('`%s`'):format(plate),
                inline = true
            },
            {
                name = 'Job interno',
                value = ('`%s`'):format(job.name or 'desconhecido'),
                inline = true
            },
            {
                name = 'Discord',
                value = mechanic.discord,
                inline = false
            },
            {
                name = 'Identificador ESX',
                value = ('`%s`'):format(mechanic.identifier),
                inline = false
            }
        }
    )
end
