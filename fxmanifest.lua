fx_version 'cerulean'
game 'gta5'

name 'clp_medic'
author 'OpenAI - Medic System'
description 'Standalone ESX medic system with ox_target and ox_inventory'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/garage.lua',
    'client/medical.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/medical.lua'
}

dependencies {
    'es_extended',
    'ox_target',
    'ox_inventory',
    'ox_lib'
}
