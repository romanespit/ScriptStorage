--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
fAwesome6.lua - https://www.blast.hk/threads/111224/
mimgui - https://www.blast.hk/threads/66959/
]]
------------------------ Main Variables
script_author("romanespit")
script_name("Emoji Helper")
script_version("1.1.0")
local scr = thisScript()
SCRIPT_SHORTNAME = "EmojiHelper"
MAIN_CMD = "ehelp"
COLOR_MAIN = "{6495ED}"
SCRIPT_COLOR = 0xFF6495ED
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
COLOR_WHITE = "{FFFFFF}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
------------------------ 
local hook = require 'lib.samp.events'
local wm = require 'lib.windows.message'
local ffi = require 'ffi'
local encoding = require('encoding')
encoding.default = 'cp1251'
u8 = encoding.UTF8
local effil_check, effil = pcall(require, 'effil')
local dlstatus = require("moonloader").download_status
local io = require("io")
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- Разрешение экрана
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Variables

------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function tech_sms(text)
    if not doesFileExist(dirml..'/NespitManager.lua') and not doesFileExist(dirml..'/NespitManager.luac') then sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR) end
end
function Logger(text)
    print(COLOR_YES..text)
end
------------------------ Script Directories
if not doesDirectoryExist(dirml.."/rmnsptScripts/") then
    createDirectory(dirml.."/rmnsptScripts/")
    Logger("Директория rmnsptScripts не была найдена. Создаём...")
end
if not doesDirectoryExist(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/") then
    createDirectory(dirscr)
    Logger("Директория rmnsptScripts/"..SCRIPT_SHORTNAME.." не была найдена. Создаём...")
end

------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        tech_sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function() sms("Используйте в командах/чате структуру {e:text 123}") sms("{e:text 123} {e:jopa} => "..Modify("{e:text 123}").." "..Modify("{e:jopa}")) end) -- Главное окно скрипта
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
    RegisterScriptCommands() -- Регистрация объявленных команд скрипта
	tech_sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    while true do
		wait(0)
    end  
    wait(-1)
end
------------------------ Samp Events Hook funcs
local numtochar = {
    ["0"] = 'a', ["1"] = 'b', ["2"] = 'c', ["3"] = 'd', ["4"] = 'e', ["5"] = 'f', ["6"] = 'g', ["7"] = 'h', ["8"] = 'i', ["9"] = 'j'
}
function Modify(w)
    local text = w or ""
    text = text:lower() -- Делаем нижний
    text = text:match("{e:(.-)}") -- Получаем текст для замены
    text = text:gsub("%a",":l%1:")
    for n in string.gmatch(text, "%d") do
        local mod = n
        mod = ":n"..numtochar[n]..":"
        text = text:gsub(n,mod)
    end
    return text
end
function hook.onSendCommand(text)
    if text:find("{e:(.-)}") then
        for w in string.gmatch(text, "{e:.-}") do
            text = text:gsub(w,Modify(w))
        end
        return {text}
    end
end
function hook.onSendChat(text)
    if text:find("{e:(.-)}") then
        for w in string.gmatch(text, "{e:.-}") do
            text = text:gsub(w,Modify(w))
        end
        return {text}
    end
end
