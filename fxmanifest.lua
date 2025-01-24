fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Zowix'
description 'Sistema de Testigos Avanzado para Policia en RedM para VorpCore'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_scripts {
    'shared/config.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/script.js'
}
