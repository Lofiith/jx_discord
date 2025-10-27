fx_version 'cerulean'
game 'gta5'

name 'jx_discord'
author 'Lofi'
description 'Lightweight FiveM Discord API Integration'
version '1.0.0'

server_scripts {
    'config.lua',
    'server/server.lua',
    'server/version.lua'
}

dependencies {
    'yarn',
    'webpack'
}

lua54 'yes'
