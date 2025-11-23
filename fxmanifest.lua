fx_version 'cerulean'
game 'gta5'

name 'clp_medic'
author 'OpenAI - Medic System'
description 'Standalone ESX medic system with ox_target and ox_inventory'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/animations.lua', -- NEW: shared animation helpers
    'client/main.lua',
    'client/garage.lua',
    -- Added: death screen NUI handling
    'client/deathscreen.lua',
    -- Added: carry logic
    'client/carry.lua',
    -- Added: defibrillator handling
    'client/defib.lua',
    -- NEW: dispatch tablet/client sync
    'client/dispatch.lua',
    -- NEW: hospital beds + locker logic
    'client/beds.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/medical.lua',
    -- Added: carry synchronization
    'server/carry.lua',
    -- NEW: dispatch state + routing
    'server/dispatch.lua',
    -- NEW: hospital beds + locker/billing helpers
    'server/beds.lua'
}

dependencies {
    'es_extended',
    'ox_target',
    'ox_inventory',
    'ox_lib'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
