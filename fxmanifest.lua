fx_version "cerulean"
game "gta5"

author "Yecoyz - Yecoyz Resources"
version "1.2.0"
lua54 "yes"

client_scripts {
    "client/cl_player.lua",
    "client/cl_main.lua",
    "client/cl_funcs.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/sv_player.lua",
    "server/sv_funcs.lua",
    "server/sv_main.lua",
    "server/database.lua"
}

shared_scripts {
    "@yecoyz_core/import.lua",
    "shared/config.lua",
    '@ox_lib/init.lua',
}

dependencies {
    "yecoyz_core",
}

-- ui_page "nui_source/reload.html" -- Dev only

ui_page "dist/index.html"

files {
    -- "nui_source/reload.html",
    "dist/*.html",
    "dist/assets/*.js",
    "dist/assets/*.css",

    "locales/*.json"
}
