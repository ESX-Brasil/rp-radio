fx_version "adamant"
game "gta5"

name "rp-radio"
description "Um rádio no jogo que utiliza a API de rádio mumble-voip para FiveM"
author "Renildo Marcio (renildomrc@gmail.com)"
version "1.0.2"

ui_page "index.html"

dependencies {
	"mumble-voip",
}

files {
	"index.html",
	"on.ogg",
	"off.ogg",
}

client_scripts {
	"config.lua",
	"client.lua",
}

server_scripts {
	"server.lua",
}
