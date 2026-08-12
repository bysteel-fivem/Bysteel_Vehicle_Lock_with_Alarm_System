fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'BySteel>>>'
description 'BySteel Carlock - ESX Legacy / ox_target / ox_lib'
version '1.3.1'
license 'GPL-3.0-or-later'

shared_scripts {
    '@ox_lib/init.lua',
    'configs/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'fx_notify',
    'dynamic_dispatch'
}
