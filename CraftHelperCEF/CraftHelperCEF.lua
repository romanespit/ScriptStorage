------------------------ Main Variables
script_author("romanespit")
script_name("Craft Helper")
script_version("1.0.1")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version
SCRIPT_SHORTNAME = "CraftHelper"
MAIN_CMD = "acr"
COLOR_MAIN = "{408080}"
SCRIPT_COLOR = 0xFF408080
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
COLOR_WHITE = "{FFFFFF}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
-- Emojis
EDBG = ":u1f6e0:"
EOK = ":true:"
EERR = ":no_entry:"
EINFO = ":question:"
------------------------ 
local hook = require 'lib.samp.events'
local encoding = require('encoding')
encoding.default = 'cp1251'
u8 = encoding.UTF8
--local faicons = require('fAwesome6')
local dlstatus = require("moonloader").download_status
local io = require("io")

local json = require("cjson")
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Variables
local category = nil
local item = nil
local CraftProcess = false
local LastCraftTime = os.clock()
local NeedToCraft = -1
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
--[[function FileLog(text)
    local filepath = dirscr.."CraftLog.log"
    local file = io.open(filepath, "a+")
    if file then
        file:write(u8('\n['..os.date("%c")..'] '..text:gsub('{......}','')))
        file:close()
    end
end]]
function onSendPacket(id, bs)
    if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 18 then
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
            if text:find("selectItemInCategory|") then -- selectItemInCategory|{"category": 2, "index": 12}
                local data = json.decode(text:match("selectItemInCategory|(.+)"))
                if data.category ~= nil and data.index ~= nil then
                    category = data.category
                    item = data.index
                end
                if CraftProcess then
                    CraftProcess = false
                    NeedToCraft = -1
                    sms(EERR.."Автокрафт остановлен, так как вы выбрали другой предмет")
                    SaveItems()
                end
            end
            if text == "stopCraft" and CraftProcess then
                CraftProcess = false
                NeedToCraft = -1
                sms(EOK.."Автокрафт остановлен")
                SaveItems()
            end
        end
    end
end
function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            if text:find("event.inventory.craft") then
                local data = json.decode(text:match("`%[(.+)%]`"))
                if data.action ~= nil and tonumber(data.action) == 2 and CraftProcess then
                    if thread:status() == "dead" then
                        thread = lua_thread.create(function() 
                            wait(2000)
                            cefSend('updateCount|{"category": '..category..', "index": '..item..', "count": 2}')
                        end)                
                    end                    
                end
                
            end
        end
    end
end
function cefSend(text)
    local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 220)
	raknetBitStreamWriteInt8(bs, 18)
	raknetBitStreamWriteInt16(bs, string.len(text))
	raknetBitStreamWriteString(bs, text)
	raknetSendBitStreamEx(bs, 1, 7, 1)
	raknetDeleteBitStream(bs)
end
--[[function CheckAndDownloadFiles()
    needLoad = 0
    NeedToLoad = {}
    if not doesFileExist(dirml..'/rmnsptScripts/EagleSans-Regular.ttf') then table.insert(NeedToLoad, {'https://github.com/romanespit/ScriptStorage/blob/main/extraFiles/EagleSans-Regular.ttf?raw=true',dirml..'/rmnsptScripts/EagleSans-Regular.ttf'}) needLoad = needLoad+1 end
    if needLoad ~= 0 then
        Logger("Требуется загрузка "..needLoad.." файлов. Начинаю скачивание...")
        for k,v in ipairs(NeedToLoad) do
            downloadUrlToFile(v[1], v[2], function(id, status, p1, p2)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    lua_thread.create(function()
                        wait(1000)
                        if doesFileExist(v[2]) then
                            Logger("Успешная загрузка файла "..v[2]:match(".+(rmnsptScripts/.+)"))
                            needLoad = needLoad-1
                        end
                    end)
                end
            end)
        end
    end
    repeat wait(100) until needLoad == 0
    if #NeedToLoad > 0 then sms("Загрузки необходимых файлов завершены. Перезагружаемся...") reloaded = true scr:reload() end
end]]
------------------------ Script Directories
if not doesDirectoryExist(dirml.."/rmnsptScripts/") then
    createDirectory(dirml.."/rmnsptScripts/") 
    Logger("Директория rmnsptScripts не была найдена. Создаём...")
end
if not doesDirectoryExist(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/") then
    createDirectory(dirscr)
    Logger("Директория rmnsptScripts/"..SCRIPT_SHORTNAME.." не была найдена. Создаём...")
end
------------------------ JSON Config
local Stats = {
    ["Аптечка"] = {Chance = 100, Crafted = 0, Attempts = 0}
}
function LoadItems()
    local filepath = dirscr.."Items.json"
    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        Stats = json.decode(content)
    else
        Logger("Ошибка чтения файла с предметами! Создаём...")
        SaveItems()
    end
end
function SaveItems()
    local filepath = dirscr.."Items.json"
    local file = io.open(filepath, "w")
    if file then
        file:write(json.encode(Stats))
        file:close()
    else
        Logger("Ошибка сохранения файла с предметами")
    end
end
--[[function SaveCFG()
    local filepath = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."-settings.json"
    local file = io.open(filepath, "w")
    if file then
        file:write(json.encode(config))
        file:close()
    else
        Logger("Ошибка сохранения файла настроек")
    end
end
function LoadCFG()
    local filepath = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."-settings.json"
    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        config = json.decode(content)
    else
        Logger("Ошибка чтения файла настроек! Создаём...")
        SaveCFG()
    end
end]]
do -- Custom string's methods
	local mt = getmetatable("")
	local lower = string.lower
	function mt.__index:lower() -- Patch string.lower() for working with Cyrillic
		for i = 192, 223 do
			self = self:gsub(string.char(i), string.char(i + 32))
		end
		self = self:gsub(string.char(168), string.char(184))
		return lower(self)
	end
	function mt.__index:split(sep, plain) -- Splits a string by separator
		result, pos = {}, 1
		repeat
			local s, f = self:find(sep or " ", pos, plain)
			result[#result + 1] = self:sub(pos, s and s - 1)
			pos = f and f + 1
		until pos == nil
		return result
	end
end
--LoadCFG() -- Загрузка настроек
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        tech_sms(EERR.."Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function(par)
        if not CraftProcess then
            if category ~= nil and item ~= nil then
                if par == nil or par == "" then sms(EINFO.."Вы можете ввести "..COLOR_YES.."/"..MAIN_CMD.." [кол-во попыток]"..COLOR_WHITE..", для крафта определенного количества")
                else
                    if tonumber(par) > 0 and tonumber(par) < 30000 then
                        NeedToCraft = tonumber(par)-1
                    else sms(EDBG.."Используйте: "..COLOR_YES.."/"..MAIN_CMD.." [кол-во попыток]"..COLOR_WHITE.." (количество попыток от 1 до 30000)") return end
                end
                CraftProcess = true
                if thread:status() == "dead" then
                    thread = lua_thread.create(function()
                        LastCraftTime = os.clock()
                        cefSend('updateCount|{"category": '..category..', "index": '..item..', "count": 2}')
                        wait(300)
                        cefSend('startCraft|{"amount": 10, "category": '..category..', "color":0, "index": '..item..', "count": 2}')
                    end)                
                end
                sms(EOK.."Автокрафт запущен. Категория №"..tonumber(category)+1 ..", Предмет №"..tonumber(item)+1 ..(NeedToCraft > -1 and ", Количество: "..tonumber(par) or ""))
            else sms(EERR.."Зайдите в меню крафта и выберите предмет") end
        else
            cefSend("stopCraft")
            CraftProcess = false
            NeedToCraft = -1
            sms(EOK.."Автокрафт остановлен")
            SaveItems()
        end
    end)
    sampRegisterChatCommand("crstats", function(arg)
		if string.find(arg, "^[%s%c]*$") then
			return sms(EDBG.."Используйте: "..COLOR_YES.."/crstats [Название предмета]")
		end

		local results = {}
		arg = string.lower(arg)
		for item, v in pairs(Stats) do
			if string.find(string.lower(item), arg) then
				table.insert(results, {
                    name = item,
					chance = v.Chance,
					crafted = v.Crafted,
                    attempts = v.Attempts
				})
			end
		end

		if #results == 0 then
			sms(EERR.."Предмета с таким названием в ваших крафтах не найдено")
		else
			if #results > 5 then
				sms("Выведено 5 наиболее похожих предметов:")
			end
			for i, v in ipairs(results) do
				sms("["..COLOR_YES..v.name..COLOR_WHITE.."] Шанс: "..COLOR_YES..v.chance..COLOR_WHITE.." | Крафтов: "..COLOR_YES..v.crafted..COLOR_WHITE.." успешных из "..COLOR_YES..v.attempts..COLOR_WHITE.." попыток. Ваш реальный шанс: "..COLOR_YES..string.format("%.2f", (tonumber(v.crafted)/tonumber(v.attempts))*100))
				if i >= 5 then break end
			end
		end
	end)
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
    --CheckAndDownloadFiles()
    RegisterScriptCommands() -- Регистрация объявленных команд скрипта
	tech_sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}, "..COLOR_MAIN.."/crstats{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    LoadItems()
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    while true do
		wait(0)
        if os.clock()-LastCraftTime > 13 and CraftProcess then 
            if thread:status() == "dead" then
                thread = lua_thread.create(function()
                    LastCraftTime = os.clock()
                    sms(EDBG.."Процесс залагал. Перезапускаем...")
                    cefSend('updateCount|{"category": '..category..', "index": '..item..', "count": 2}')
                    wait(300)
                    cefSend('startCraft|{"amount": 10, "category": '..category..', "color":0, "index": '..item..', "count": 2}')
                end)                
            end
        end
    end  
    wait(-1)
end
------------------------ Samp Events Hook funcs
function hook.onSendSpawn()
	_, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myid)
end
function hook.onServerMessage(color, text)
    if text:find("Вы успешно создали предмет '(.-)' %(шанс изготовления (%d+) процент%(ов%)%)") then
        local name,proc = text:match("Вы успешно создали предмет '(.-)' %(шанс изготовления (%d+) процент%(ов%)%)")
        if Stats[name] == nil then
            Stats[name] = {Chance = proc, Crafted = 1, Attempts = 1}
        else
            Stats[name].Chance = proc
            Stats[name].Crafted = Stats[name].Crafted+1
            Stats[name].Attempts = Stats[name].Attempts+1
        end
        SaveItems()
        sms(EOK..COLOR_YES.."Успешный крафт"..COLOR_WHITE.." - "..name.." | Шанс "..proc.."проц. | Успехов: "..Stats[name].Crafted.." из "..Stats[name].Attempts.." попыток ("..string.format("%.2f", (tonumber(Stats[name].Crafted)/tonumber(Stats[name].Attempts))*100) .."проц.)")
        LastCraftTime = os.clock()
        if NeedToCraft > -1 then
            if NeedToCraft == 0 then 
                cefSend("stopCraft")
                CraftProcess = false
                sms(EOK.."Автокрафт остановлен, нужное количество попыток достигнуто")
                SaveItems()
            end
            NeedToCraft = NeedToCraft-1
        end
        return false
    end
    if text:find("Создание предмета '(.-)' не удалось %(шанс изготовления (%d+) процент%(ов%)%)") then
        local name,proc = text:match("Создание предмета '(.-)' не удалось %(шанс изготовления (%d+) процент%(ов%)%)")
        if Stats[name] == nil then
            Stats[name] = {Chance = proc, Crafted = 0, Attempts = 1}
        else
            Stats[name].Chance = proc
            Stats[name].Attempts = Stats[name].Attempts+1
        end
        SaveItems()
        sms(EERR..COLOR_NO.."Неуспешный крафт"..COLOR_WHITE.." - "..name.." | Шанс "..proc.."проц. | Успехов: "..Stats[name].Crafted.." из "..Stats[name].Attempts.." попыток ("..string.format("%.2f", (tonumber(Stats[name].Crafted)/tonumber(Stats[name].Attempts))*100) .."проц.)")
        LastCraftTime = os.clock()
        if NeedToCraft > -1 then
            if NeedToCraft == 0 then 
                cefSend("stopCraft")
                CraftProcess = false
                sms(EOK.."Автокрафт остановлен, нужное количество попыток достигнуто")
                SaveItems()
            end
            NeedToCraft = NeedToCraft-1
        end
        return false
    end
    if text:find("Вы прервали процесс создания предмета") and CraftProcess then 
        cefSend("stopCraft")
        CraftProcess = false
        NeedToCraft = -1
        sms(EERR.."Автокрафт остановлен, так как вы прервали процесс создания предмета")
        SaveItems()
        return false
    end
    if text:find("%[Ошибка%] {......}У вас недостаточно ресурсов или возможно предмет в аренде") then  
        cefSend("stopCraft")
        CraftProcess = false
        NeedToCraft = -1
        sms(EERR.."Автокрафт остановлен, так как у вас недостаточно ресурсов или возможно предмет в аренде")
        SaveItems()
        return false
    end
end