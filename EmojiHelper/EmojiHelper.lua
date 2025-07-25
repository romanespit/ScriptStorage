--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
]]
------------------------ Main Variables
script_author("romanespit ([07]Con_Serve)")
script_name("Emoji Helper")
script_version("1.2.0")
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
local dirml = getWorkingDirectory() -- Директория moonloader
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function tech_sms(text)
    if not doesFileExist(dirml..'/NespitManager.lua') and not doesFileExist(dirml..'/NespitManager.luac') then sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR) end
end
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        tech_sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
local family = {"20a","20b","20c","20d","20e","20f","200","201","202","203","204","205","206","207","208","209","21a","21b","21c","21d","21e","21f","210","211","212","213","214","215","216","217","218","219", "220","221","222","223","224","225","226","227"}
local prem = {"250", "251", "252", "253", "254", "255", "256", "257", "258", "259"}
local guns = {"30a","30b","30c","30d","30e","30f","300","301","302","303","304","305","306","307","308","309","31a","31b","31c","31d","31e","31f","310","311","312","313","314","315","316","317","318","319","32a","32b","32c","32d","32e","32f","320","321","322","323","324","325","326","327","329","330","331","332"}
local unknown = {"uf25b","u1fc1e","bk","bh","sell","trade","rent","buy","lavka123"}
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function() sms("Список скрытых эмодзи: "..COLOR_YES.."/elist") sms("Используйте в командах/чате структуру "..COLOR_YES.."{e:text 123}") sms("{e:text 123} {e:jopa} => "..Modify("{e:text 123}").." "..Modify("{e:jopa}")) end) -- Главное окно скрипта
    

	sampRegisterChatCommand("elist", function()
        local stack = 7
        local text = ""
        stack = 7
        sms("Флаги семей:")						
        for i,v in ipairs(family) do
            text = text..":uf"..v..":=uf"..v
            stack = stack-1
            if stack == 0 or i==#family then sms(text) text = "" stack = 7 end
        end
        stack = 5
        sms("Эмодзи уровня премиум:")
        for i,v in ipairs(prem) do
            text = text..":uf"..v..":=uf"..v
            stack = stack-1
            if stack == 0 or i==#prem then sms(text) text = "" stack = 5 end
        end
        stack = 10
        sms("Эмодзи оружия (цвет зависит от цвета сообщения):")
        for i,v in ipairs(guns) do
            text = text..COLOR_YES..":uf"..v..":{FFFFFF}=uf"..v
            stack = stack-1
            if stack == 0 or i==#guns then sms(text) text = "" stack = 10 end
        end
        sms("Остальные эмодзи:")
        for i,v in ipairs(unknown) do
            text = text..":"..v..":="..v
        end
        sms(text)
    end)
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
