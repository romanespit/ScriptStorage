script_author("romanespit")
script_name("Case Opener")
script_version("1.4.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." © "..table.concat(scr.authors, ", ")
------------------------
local hook = require 'lib.samp.events'
local wm = require 'lib.windows.message'
local encoding = require('encoding')
local faicons = require('fAwesome6')
local imgui = require 'mimgui'
--local inicfg = require 'inicfg'
local effil_check, effil = pcall(require, 'effil')
local memory = require "memory"
local ffi = require 'ffi'
local dlstatus = require("moonloader").download_status
local json = require("cjson")
local io = require("io")
encoding.default = 'cp1251'
ffi.cdef [[
		typedef int BOOL;
		typedef unsigned long HANDLE;
		typedef HANDLE HWND;
		typedef const char* LPCSTR;
		typedef unsigned UINT;
		
        void* __stdcall ShellExecuteA(void* hwnd, const char* op, const char* file, const char* params, const char* dir, int show_cmd);
        uint32_t __stdcall CoInitializeEx(void*, uint32_t);
		
		BOOL ShowWindow(HWND hWnd, int  nCmdShow);
		HWND GetActiveWindow();
		
		
		int MessageBoxA(
		  HWND   hWnd,
		  LPCSTR lpText,
		  LPCSTR lpCaption,
		  UINT   uType
		);
		
		short GetKeyState(int nVirtKey);
		bool GetKeyboardLayoutNameA(char* pwszKLID);
		int GetLocaleInfoA(int Locale, int LCType, char* lpLCData, int cchData);
  ]]

local shell32 = ffi.load 'Shell32'
local ole32 = ffi.load 'Ole32'
ole32.CoInitializeEx(nil, 2 + 4)
u8 = encoding.UTF8
SCRIPT_SHORTNAME = "CaseOpener"
MAIN_CMD = "co"
COLOR_MAIN = '{d8572a}'
SCRIPT_COLOR = 0xFFD8572A
COLOR_YES = '{36c500}'
COLOR_NO = '{FF6A57}'
COLOR_WHITE = '{ffffff}'
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
local reloaded = false
local myNick = ""
local sx, sy = getScreenResolution()

------------------------ Updates
local NeedToLoad = {}
local needLoad = 0

local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
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
------------------------ Default Config
local settings = { 
    main={
        KostStop = true,
        BlueprintStop = false,
        BlueprintNotifications = false       
	}
}
local ItemPrice = {
    ["Ларец организации"] = "120000",
    ["Подарок"] = "45000",
    ["Деньги"] = "1"
}
function SaveCFG()
    local filepath = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."-settings.json"
    local file = io.open(filepath, "w")
    if file then
        file:write(json.encode(settings))
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
        settings = json.decode(content)
    else
        Logger("Ошибка чтения файла настроек! Создаём...")
        SaveCFG()
    end
end
LoadCFG() -- Загрузка настроек
function LoadItemPrices()
    local filepath = dirml.."/rmnsptScripts/ItemPrices.json"
    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        ItemPrice = json.decode(content)
        for k,v in pairs(ItemPrice) do
            if ItemPrice[k] == 0 or tonumber(ItemPrice[k]) < 0 or tonumber(ItemPrice[k]) == nil then ItemPrice[k] = "0" end
        end
    else
        Logger("Ошибка чтения файла с ценами! Создаём...")
        SaveItemPrices()
    end
end
function SaveItemPrices()
    local filepath = dirml.."/rmnsptScripts/ItemPrices.json"
    local file = io.open(filepath, "w")
    if file then
        file:write(json.encode(ItemPrice))
        file:close()
    else
        Logger("Ошибка сохранения файла с ценами")
    end
end
function CheckAndDownloadFiles()
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
end
-- MimGUI
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local KostStop = new.bool(settings.main.KostStop)
local BlueprintNotifications = new.bool(settings.main.BlueprintNotifications)
local BlueprintStop = new.bool(settings.main.BlueprintStop)
local PriceState = new.bool()
local imPrice = new.char[10]()
local instructions = [[
Для начала работы вам нужно открыть ваш инвентарь (клавиша I или Y)
Затем нажмите кнопку Выбрать ячейку.
После этого вы войдёте в режим выбора ячейки в инвентаре.
Просто кликните на ячейку с интересующим ларцом, скрипт её запомнит.
После выбора ячейки нажмите Начать открытие или Выбрать заново
Во время открытия не закрывайте инвентарь!
]]
local instructionsText = new.char[1024](u8(instructions))

local inventoryItem = { -- id td inv
    2136,2137,2138,2139,2140,2141,2142,2143,2144,2145,2146,
    2147,2148,2149,2150,2151,2152,2153,2154,2155,2156,2157,
    2158,2159,2160,2161,2162,2163,2164,2165,2166,2167,2168,
    2169,2170,2171,2172,2173,2174,2175,2176,2177,2178,2179,
    2180,2181,2182,2183,2184,2185,2186,2187,2188,2189,2190,
    2191,2192,2193,2194,2195,2196,2197,2198,2199,2200,2201,
    2202,2203,2204,2205,2206,2207,2208,2209,2210,2211,2212
}
local button = { -- константы кнопок инвентаря
    Close = 65535, -- 2112
    Use = 2302,
    Page = {2107,2108,2109,2110,2111}
}
local OpenCount = 0
local DropStats = {}
local TotalDropPrice = 0
local PriceSetName = ""
local actualPage = 1
local LastClickedTD = 0
local selectedItem = 0
local selectedModel = 0
local antiLagTimer = os.clock()
local stage = "off" -- Этап работы скрипта
local openStage = "off" -- Этап в процессе открытия
function imgui.TextColoredRGB(string, max_float)
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local u8 = require 'encoding'.UTF8

	local function color_imvec4(color)
		if color:upper():sub(1, 6) == 'SSSSSS' then return imgui.ImVec4(colors[clr.Text].x, colors[clr.Text].y, colors[clr.Text].z, tonumber(color:sub(7, 8), 16) and tonumber(color:sub(7, 8), 16)/255 or colors[clr.Text].w) end
		local color = type(color) == 'number' and ('%X'):format(color):upper() or color:upper()
		local rgb = {}
		for i = 1, #color/2 do rgb[#rgb+1] = tonumber(color:sub(2*i-1, 2*i), 16) end
		return imgui.ImVec4(rgb[1]/255, rgb[2]/255, rgb[3]/255, rgb[4] and rgb[4]/255 or colors[clr.Text].w)
	end

	local function render_text(string)
		for w in string:gmatch('[^\r\n]+') do
			local text, color = {}, {}
			local render_text = 1
			local m = 1
			if w:sub(1, 8) == '[center]' then
				render_text = 2
				w = w:sub(9)
			elseif w:sub(1, 7) == '[right]' then
				render_text = 3
				w = w:sub(8)
			end
			w = w:gsub('{(......)}', '{%1FF}')
			while w:find('{........}') do
				local n, k = w:find('{........}')
				if tonumber(w:sub(n+1, k-1), 16) or (w:sub(n+1, k-3):upper() == 'SSSSSS' and tonumber(w:sub(k-2, k-1), 16) or w:sub(k-2, k-1):upper() == 'SS') then
					text[#text], text[#text+1] = w:sub(m, n-1), w:sub(k+1, #w)
					color[#color+1] = color_imvec4(w:sub(n+1, k-1))
					w = w:sub(1, n-1)..w:sub(k+1, #w)
					m = n
				else w = w:sub(1, n-1)..w:sub(n, k-3)..'}'..w:sub(k+1, #w) end
			end
			local length = imgui.CalcTextSize(u8(w))
			if render_text == 2 then
				imgui.NewLine()
				imgui.SameLine(max_float / 2 - ( length.x / 2 ))
			elseif render_text == 3 then
				imgui.NewLine()
				imgui.SameLine(max_float - length.x - 5 )
			end
			if text[0] then
				for i, k in pairs(text) do
					imgui.TextColored(color[i] or colors[clr.Text], u8(k))
					imgui.SameLine(nil, 0)
				end
				imgui.NewLine()
			else imgui.Text(u8(w)) end
		end
	end
	
	render_text(string)
end
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    --Font
    if doesFileExist(dirml..'/rmnsptScripts/EagleSans-Regular.ttf') then        
        imgui.GetIO().Fonts:Clear()
        imgui.GetIO().Fonts:AddFontFromFileTTF(u8(dirml..'/rmnsptScripts/EagleSans-Regular.ttf'), 15, nil, glyph_ranges)
    else Logger("Отсутствует файл EagleSans-Regular.ttf.") end
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 10, config, iconRanges)
    MimStyle()
end)
imgui.OnFrame(function() return WinState[0] and not PriceState[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(faicons('gem')..u8(" "..SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        imgui.Text(instructionsText)
        imgui.Separator()
        if stage == "off" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"Выбрать ячейку", imgui.ImVec2(200, 50)) then
                local found = false
                for i,v in ipairs(inventoryItem) do
                    if sampTextdrawIsExists(inventoryItem[i]) then found = true break end
                end
                if found then stage = "select" else stage = "select" sampSendChat("/invent") end
            end
        end
        if stage == "select" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"Отменить", imgui.ImVec2(200, 50)) then
                stopOpening()
            end
        end
        if stage == "selected" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-200)
            if imgui.Button(u8"Начать открытие", imgui.ImVec2(200, 50)) then
                stage = "opening"
                openStage = "select"
            end
            imgui.SameLine()
            if imgui.Button(u8"Выбрать заново", imgui.ImVec2(200, 50)) then
                stage = "select"
                selectedItem = 0
            end
        end
        if stage == "opening" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"Остановить открытие", imgui.ImVec2(200, 50)) then
                stopOpening()
            end
        end
        if imgui.CollapsingHeader(u8"Настройки") then      
            if imgui.Checkbox(u8'Останавливать при дропе косточек ', KostStop) then
                settings.main.KostStop = not settings.main.KostStop
                SaveCFG()
                sms("При получении косточки открытия "..(settings.main.KostStop and COLOR_NO.."прекратятся" or COLOR_YES.."продолжатся"))
            end
            if imgui.Checkbox(u8'Звуковые уведомления о дропе чертежа ', BlueprintNotifications) then
                settings.main.BlueprintNotifications = not settings.main.BlueprintNotifications
                SaveCFG()
                sms("Звуковые уведомления о дропе чертежа "..(settings.main.BlueprintNotifications and COLOR_YES.."включены" or COLOR_NO.."выключены"))
            end
            if imgui.Checkbox(u8'Останавливать открытие, если выбит чертёж ', BlueprintStop) then
                settings.main.BlueprintStop = not settings.main.BlueprintStop
                SaveCFG()
                sms("При дропе чертежа открытия "..(settings.main.BlueprintStop and COLOR_NO.."остановятся" or COLOR_YES.."продолжатся"))
            end            
            imgui.Separator()
        end
        if imgui.CollapsingHeader(u8"Статистика") then
            imgui.Text(u8"Статистика открытий:")
            imgui.TextColoredRGB("Открыто ларцов: "..COLOR_YES..OpenCount) 
            imgui.TextColoredRGB("Цена всего дропа: "..COLOR_YES.."$"..TotalDropPrice)
            imgui.Separator()
            if #DropStats > 0 then
                TotalDropPrice = 0
                for i,v in ipairs(DropStats) do
                    imgui.TextColoredRGB(DropStats[i].Name.."{FFFF00} x"..DropStats[i].Count..COLOR_YES..(ItemPrice[DropStats[i].Name] ~= "0" and " $"..ItemPrice[DropStats[i].Name] or " Цена неизвестна"))
                    TotalDropPrice = TotalDropPrice+(tonumber(ItemPrice[DropStats[i].Name])*DropStats[i].Count)
                    if DropStats[i].Name ~= "Деньги" then
                        imgui.SameLine()
                        imgui.Text(faicons.PEN_TO_SQUARE)
                        if imgui.IsItemHovered() then
                            imgui.BeginTooltip()
                            imgui.Text(u8'Нажмите, чтобы изменить цену')
                            imgui.EndTooltip()
                        end        
                        if imgui.IsItemClicked() then 
                            PriceState[0] = not PriceState[0]
                            PriceSetName = DropStats[i].Name
                            imgui.StrCopy(imPrice, u8(ItemPrice[DropStats[i].Name]))
                        end
                    end
                end
                imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
                if imgui.Button(u8'Сохранить в файл', imgui.ImVec2(200, 30)) then
                    local text = ""
                    local filepath = dirscr.."SavedDrop-"..os.date("%d%m%y-%H-%M-%S")..".log"
                    local file = io.open(filepath, "w")
                    if file then
                        TotalDropPrice = 0
                        for i,v in ipairs(DropStats) do
                            TotalDropPrice = TotalDropPrice+(tonumber(ItemPrice[DropStats[i].Name])*DropStats[i].Count)
                            text = text.."\n"..DropStats[i].Name.." - x"..DropStats[i].Count..". Средняя цена: "..(ItemPrice[DropStats[i].Name] ~= "0" and " $"..ItemPrice[DropStats[i].Name] or " Цена неизвестна")  
                        end
                        text = text.."\n\nОбщая цена дропа: $"..TotalDropPrice
                        file:write(u8(text))
                        file:close()
                    end
                    sms("Дроп сохранен в файл /moonloader/rmnsptScripts/"..SCRIPT_SHORTNAME.."/SavedDrop-"..os.date("%d%m%y-%H-%M-%S")..".log")
                end 
            end
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'Обнулить статистику', imgui.ImVec2(200, 30)) then
                OpenCount = 0
                DropStats = {}
                TotalDropPrice = 0
                sms("Статистика сброшена")
            end
        end
        imgui.Link("https://romanespit.ru/lua",u8"© "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)
imgui.OnFrame(function() return PriceState[0] end, -- Main Frame
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(u8("Настройки цен дропа"), PriceState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        imgui.TextColoredRGB("Введите цену для "..COLOR_YES..PriceSetName..COLOR_WHITE..":")
        imgui.SameLine()
        imgui.PushItemWidth(100)
        imgui.InputText("", imPrice, 10)
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100) 
        if imgui.Button(u8'Сохранить', imgui.ImVec2(200, 30)) then
            if u8:decode(ffi.string(imPrice)) == nil or
            u8:decode(ffi.string(imPrice)) == "" or
            tonumber(u8:decode(ffi.string(imPrice))) == nil or
            tonumber(u8:decode(ffi.string(imPrice))) < 0 then imgui.StrCopy(imPrice, u8("0")) end
            ItemPrice[PriceSetName] = u8:decode(ffi.string(imPrice))
            SaveItemPrices()
            PriceSetName = ""
            PriceState[0] = false
        end        
        imgui.End()
    end
)
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        tech_sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
function main()
	while not isSampAvailable() do wait(0) end
	thread = lua_thread.create(function() return end)
	repeat wait(100) until sampIsLocalPlayerSpawned()
    CheckAndDownloadFiles()
	RegisterScriptCommands() -- Регистрация объявленных команд скрипта
    LoadItemPrices()
	tech_sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    stopOpening()
	while true do
		wait(0)
        if not WinState[0] and stage == "opening" then
            stopOpening("Окно скрипта было закрыто, открытие остановлено #M-1")
        end
        if thread:status() == "dead" and ((stage == "opening" and openStage == "select") or (os.clock()-antiLagTimer > 0.37 and openStage == "pushUse")) then
			thread = lua_thread.create(function() 
                openStage = "checkModel"                
                selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem) 
                --if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("Ларцы в ячейке закончились #M-2") end
                openStage = "waiting" 
                sampSendClickTextdraw(selectedItem)
                openStage = "pushUse"
                antiLagTimer = os.clock()
			end)
		end
    end  
    wait(-1)
end
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function() WinState[0] = not WinState[0] end) -- Главное окно скрипта
    Logger("Успешная регистрация команд скрипта")
end
function AddDrop(name,count)
    if ItemPrice[name] == nil then ItemPrice[name] = "0" SaveItemPrices() end
    local found = false
    OpenCount = OpenCount + 1
    if #DropStats > 0 then
        for i,v in ipairs(DropStats) do
            if DropStats[i].Name == name then 
                DropStats[i].Count = DropStats[i].Count+count
                found = true
                break
            end
        end
    end 
    if not found then
        table.insert(DropStats, {Name=name,Count=count})
    end
end
function hook.onServerMessage(color,text)
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    if stage == "opening" then
        --Con_Serve испытал удачу при открытии 'Super Car Box' и выиграл транспорт: Сертификат Daewoo Lanox 6x6
        if text:find("([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) испытал удачу при открытии '([^']*)' и выиграл транспорт: (.+)") and text:find(myNick) then
            stopOpening("Транспорт успешно выбит, открытие остановлено #OSM-1")
        end
        if text:find("Удача улыбнулась игроку ([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) при открытии '([^']*)' и он выиграл предмет: (.+)") and text:find(myNick) and settings.main.BlueprintStop then
            stage = "selected"
            openStage = "off"
            if thread:status() ~= "dead" then thread:terminate() end
            sms("Вы выбили чертёж! Открытие приостановлено, можете его возобновить #OSM-2")
        end
        if text:find("Вы успешно разделили предмет") then
            stopOpening("Кажется вы выбрали ячейку не с ларцом, открытие остановлено #OSM-3")
        end
        if (text:find("Косточка сливового дерева") or text:find("Косточка кокосового дерева") or text:find("Косточка яблочного дерева")) and settings.main.KostStop then
            stage = "selected"
            openStage = "off"
            if thread:status() ~= "dead" then thread:terminate() end
            sms("Выбита косточка, открытие приостановлено, его можно возобновить #OSM-4")
        end
        if text:find("%[Ошибка%] {FFFFFF}Подождите немного") then
            selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem) 
            if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("Ларцы в ячейке закончились #OSM-6") end
        end
    end
    if text:find("Вы использовали {cccccc}'(.+)'{ffff00}! Ваш приз: {cccccc}(.+)") then
        local larec,prize,count = text:match("Вы использовали {cccccc}'(.+)'{ffff00}! Ваш приз: {cccccc}(.+) %(количество: (%d+)шт.%)")
        AddDrop(prize,count)        
        if text:find("Осколок") then stopOpening("Осколок успешно выбит, открытие остановлено #OSM-5") end
    end
    if text:find("%[Информация%] {......}Вам начислено") then
        if text:find("очков опыта") then AddDrop("Опыт",text:match("(%d+)")) end
        if text:find("%$") then AddDrop("Деньги",text:gsub("%p",""):match("(%d+)")) end
    end
    if text:find("Вам был добавлен предмет 'Талон: %+1 EXP %(Передаваемые%)'") then AddDrop("Талон: +1 EXP (Передаваемые)",1) OpenCount = OpenCount - 1 end
    if text:find("Вам был добавлен предмет 'Талон для охранника: %+1 EXP'") then AddDrop("Талон для охранника: +1 EXP",1) OpenCount = OpenCount - 1 end
    if text:find("Удача улыбнулась игроку ([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) при открытии '([^']*)' и он выиграл предмет: (.+)") and not text:find(myNick) and settings.main.BlueprintNotifications then
        sms("Кто-то выбил чертёж, можно доесть :yum:")
        local staps = 0
        lua_thread.create(function()
            repeat wait(200)
                addOneOffSound(0, 0, 0, 1057)
                staps = staps + 1
                until staps > 10
        end)
    end
end
-- 
-- 

function hook.onSendClickTextDraw(id)
    LastClickedTD = id
    if id == 2112 or id == button.Close then
        if stage ~= "off" then
            stopOpening("Инвентарь был закрыт, открытие остановлено #OSCTD-0")
        end
        actualPage = 1
    end
    if id == button.Page[1] then actualPage = 1 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-1") end end
    if id == button.Page[2] then actualPage = 2 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-2") end end
    if id == button.Page[3] then actualPage = 3 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-3") end end
    if id == button.Page[4] then actualPage = 4 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-4") end end
    if id == button.Page[5] then actualPage = 5 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-5") end end
    if id == button.Page[6] then actualPage = 6 if stage ~= "off" and stage ~= "select" then stopOpening("Страница была изменена, открытие остановлено #OSCTD-6") end end
    if id ~= selectedItem and stage == "opening" then
        stopOpening("Был нажат другой TextDraw, открытие остановлено #OSCTD-7")
        return false
    end
    if stage == "select" then
        for i,v in ipairs(inventoryItem) do
            if inventoryItem[i] == id then 
                selectedModel = sampTextdrawGetModelRotationZoomVehColor(id)
                selectedItem = id
                if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then sms("Кажется в ячейке пусто, выберите другую") selectedItem = 0
                else stage = "selected" sms("Ячейка была успешно выбрана - tdID:"..id.." | Model: "..selectedModel) end
                return false
            end
        end
    end
end
function hook.onTextDrawSetString(id,text)
    if stage == "opening" and id ~= button.Use and id ~= selectedItem and sampTextdrawGetModelRotationZoomVehColor(id) ~= selectedModel then return false end
end
function hook.onTextDrawHide(id)
    if stage == "opening" and id ~= button.Use and id ~= selectedItem and sampTextdrawGetModelRotationZoomVehColor(id) ~= selectedModel then return false end -- посл условие для теста, мб убрать
end
function hook.onShowTextDraw(id,data)     
    if stage == "opening" and id ~= button.Use and id ~= selectedItem and sampTextdrawGetModelRotationZoomVehColor(id) ~= selectedModel then return false end
    if openStage == "pushUse" and id == button.Use then
        openStage = "useButtonReceived"
        selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem)
        if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("Ларцы в ячейке закончились #OSTD-1") return false
        else sampSendClickTextdraw(id) openStage = "select" end        
    end
end
function stopOpening(reason)
    stage = "off"
    openStage = "off"
    selectedItem = 0
    if thread:status() ~= "dead" then thread:terminate() end
    if reason ~= nil then sms(reason) end
end

function imgui.Link(link, text)
    text = text or link
    local tSize = imgui.CalcTextSize(text)
    local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
    local col = { 0xFFFF7700, 0xFFFF9900 }
    if imgui.InvisibleButton("##" .. link, tSize) then print(shell32.ShellExecuteA(nil, 'open', link, nil, nil, 1)) end
    local color = imgui.IsItemHovered() and col[1] or col[2]
    DL:AddText(p, color, text)
    DL:AddLine(imgui.ImVec2(p.x, p.y + tSize.y), imgui.ImVec2(p.x + tSize.x, p.y + tSize.y), color)
end
------------------------ MimGUI Style
function MimStyle()
    local style = imgui.GetStyle();
    local colors = style.Colors;
    style.Alpha = 1;
    style.WindowPadding = imgui.ImVec2(8.00, 8.00);
    style.WindowRounding = 12;
    style.WindowBorderSize = 0;
    style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
    style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50);
    style.ChildRounding = 6;
    style.ChildBorderSize = 0;
    style.PopupRounding = 12;
    style.PopupBorderSize = 0;
    style.FramePadding = imgui.ImVec2(10.00, 5.00);
    style.FrameRounding = 7;
    style.FrameBorderSize = 0;
    style.ItemSpacing = imgui.ImVec2(5.00, 4.00);
    style.ItemInnerSpacing = imgui.ImVec2(10.00, 4.00);
    style.IndentSpacing = 20;
    style.ScrollbarSize = 10;
    style.ScrollbarRounding = 12;
    style.GrabMinSize = 8;
    style.GrabRounding = 12;
    style.TabRounding = 7;
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
    style.SelectableTextAlign = imgui.ImVec2(0.50, 0.50);
    colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00);
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.20, 0.20, 0.20, 0.94);
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.20, 0.20, 0.20, 0.94);
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.20, 0.20, 0.20, 0.94);
    colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.00, 0.26, 0.64, 0.54);
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.26, 0.59, 0.98, 0.40);
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.26, 0.59, 0.98, 0.67);
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.16, 0.29, 0.48, 0.79);
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.16, 0.29, 0.48, 1.00);
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.16, 0.29, 0.48, 0.70);
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.16, 0.29, 0.48, 0.78);
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.59);
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.34, 0.34, 0.34, 1.00);
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.23, 0.42, 0.70, 1.00);
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.16, 0.29, 0.48, 1.00);
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.22, 0.39, 0.64, 1.00);
    colors[imgui.Col.Button] = imgui.ImVec4(0.18, 0.35, 0.58, 0.86);
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.16, 0.29, 0.48, 1.00);
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.21, 0.38, 0.61, 1.00);
    colors[imgui.Col.Header] = imgui.ImVec4(0.72, 0.72, 0.72, 0.31);
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.18, 0.35, 0.58, 0.74);
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.18, 0.35, 0.58, 0.86);
    colors[imgui.Col.Separator] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.10, 0.40, 0.75, 0.78);
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.10, 0.40, 0.75, 1.00);
    colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.66, 0.66, 0.66, 0.31);
    colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.77, 0.77, 0.77, 0.67);
    colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.18, 0.35, 0.58, 0.86);
    colors[imgui.Col.Tab] = imgui.ImVec4(0.18, 0.35, 0.58, 0.51);
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.18, 0.35, 0.58, 1.00);
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.24, 0.45, 0.75, 0.86);
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.07, 0.10, 0.15, 0.97);
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.14, 0.26, 0.42, 1.00);
    colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.26, 0.59, 0.98, 0.35);
    colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
    colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.18, 0.35, 0.58, 0.86);
    colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
    Logger("Стили mimgui успешно применены")
end
addEventHandler('onWindowMessage', function(msg, wparam, lparam)
	if wparam == 27 then
		if WinState[0] then
			if msg == wm.WM_KEYDOWN then
				consumeWindowMessage(true, false)
			end
			if msg == wm.WM_KEYUP then
				WinState[0] = false
			end
		end
	end
end)