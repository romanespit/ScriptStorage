--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
]]
------------------------ Main Variables
script_author("romanespit")
script_name("Fast Report Command")
script_version("1.1.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." © "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "FastReport"
MAIN_CMD = "rep"
COLOR_MAIN = "{3B66C5}"
SCRIPT_COLOR = 0xFF3B66C5
COLOR_YES = "{36C500}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
------------------------ 
local hook = require 'lib.samp.events'
local encoding = require('encoding')
encoding.default = 'cp1251'
------------------------ Another Variables
local ReportText = nil
local ReportProcess = false
local DIALOG_REPORT = 32
local DIALOG_REPORT_RESPONSE = 1333
local DIALOG_REPORT_FEEDBACK = 1332
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
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        tech_sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function(par)
        if par:find(".+") then
            ReportText = par:match(".+")
            ReportProcess = true
            sampSendChat("/rep")
        else ReportProcess = false sms("Для быстрого репорта: "..COLOR_YES.."/rep [текст репорта]") sampSendChat("/rep") end
    end) -- Главное окно скрипта
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main() 
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
	tech_sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    RegisterScriptCommands() -- Регистрация объявленных команд скрипта
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    while true do
		wait(0)
    end  
    wait(-1)
end
------------------------ Samp Events Hook funcs
function hook.onSendSpawn()
	_, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myid)
end
function hook.onShowDialog(id, style, title, button1, button2, text)
    if id == DIALOG_REPORT and ReportProcess and ReportText ~= nil then
        sampSendDialogResponse(id, 1, 0, ReportText)
        ReportProcess = false
        ReportText = nil
        sampCloseCurrentDialogWithButton(0)
        return false
    end
end
function hook.onServerMessage(_,text)
	if  text:find("Если вы хотите отблагодарить администратора, используйте") or
        text:find("Если за вами необходимо срочно проследить, администрация сделает это вне очереди")
    then return false end
    if text:find("На ваш вопрос обязательно ответит администрация! Вы (%d+) в очереди!") and not text:find(".+_.+%[%d+%]") then
        local queue = text:match("На ваш вопрос обязательно ответит администрация! Вы (%d+) в очереди!")
        sms("Очередь репорта: "..COLOR_YES..queue)
        return false
    end
    if text:find("Вы отправили жалобу:") and not text:find(".+_.+%[%d+%]") then
        local text = text:match("Вы отправили жалобу: (.+)")
        sms("Репорт: "..COLOR_YES..text)
        return false
    end
end