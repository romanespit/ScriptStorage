------------------------ Main Variables
script_author("romanespit")
script_name("Fast Podsel")
script_version("1.0.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." © "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "FastPodsel"
MAIN_CMD = "podsel"
COLOR_MAIN = "{0E7FB0}"
SCRIPT_COLOR = 0xFF0E7FB0
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
COLOR_WHITE = "{FFFFFF}"
EDBG = ":u1f6e0:"
EERR = ":no_entry:"
EINFO = ":question:"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF} "
------------------------ 
local hook = require 'lib.samp.events'
local wm = require 'lib.windows.message'
local ffi = require 'ffi'
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
local encoding = require('encoding')
encoding.default = 'cp1251'
u8 = encoding.UTF8
local effil_check, effil = pcall(require, 'effil')
local faicons = require('fAwesome6')
local dlstatus = require("moonloader").download_status
local imgui = require 'mimgui'
local json = require("cjson")
local io = require("io")
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- Разрешение экрана
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Updates
local newversion = ""
local newdate = ""
local needUpdate = false
local GitHub = {
    UpdateFile = "https://github.com/romanespit/ScriptStorage/blob/main/"..SCRIPT_SHORTNAME.."/info.upd?raw=true",
    ScriptFile = "https://github.com/romanespit/ScriptStorage/blob/main/"..SCRIPT_SHORTNAME.."/"..SCRIPT_SHORTNAME..".lua?raw=true"
}
local NeedToLoad = {}
local needLoad = 0
------------------------ Another Variables
PodselProcess = false
PodselID = 0
PodselPrice = 1000000
PodselTotalPrice = 1000000
PodselSrok = 1
PodselForm = PodselID..","..PodselPrice..","..PodselSrok

------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
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
------------------------ MimGUI Variables
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local imTotalPrice = new.int(PodselTotalPrice)
local imPriceByHour = new.int(PodselPrice)
local imTime = new.int(PodselSrok)
local imPeriodCombo = new.int(0)
local imPlayerID = new.int(PodselID)
local imPeriodList = {u8'часы', u8'дни', u8'недели', u8'месяц'}
local imPeriodItems = imgui.new['const char*'][#imPeriodList](imPeriodList)
local imFreePodsel = new.bool(false)

local ActivePrice = 1
------------------------ 
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
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
    MimStyle()
end)
------------------------ MimGUI Frames
imgui.OnFrame(function() return WinState[0] end, -- Main Frame
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(faicons('gem').." "..u8(SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-25)
        imgui.PushItemWidth(50)
        imgui.InputInt("##id",imPlayerID,0,0)
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text(u8'Введите ID игрока')
            imgui.EndTooltip()
        end
        if not imgui.IsItemActive() then
            PodselID = imPlayerID[0]
            if PodselID == nil or PodselID < 0 or PodselID > 999 then --[[imgui.StrCopy(imPlayerID, u8("0"))]]PodselID = 0 imPlayerID[0] = PodselID end
        end
        if getNearestID() ~= nil and PodselID ~= getNearestID() then
            imgui.SameLine()
            imgui.Text(faicons.CIRCLE_USER)
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(u8'Нажмите, чтобы вставить ID ближайшего игрока:')
                imgui.TextColoredRGB(COLOR_YES..getNicknameById(getNearestID())..'{FFFF00}['..getNearestID()..']')
                imgui.EndTooltip()
            end
            if imgui.IsItemClicked() then 
                imPlayerID[0] = getNearestID()
                PodselID = getNearestID()
            end
        end     
        imgui.PopItemWidth()
        if getNicknameById(PodselID) ~= nil then
            imgui.CenterText(getNicknameById(PodselID)..'['..PodselID..']')
        else imgui.CenterText('Игрок для подселения не найден') end
        imgui.Checkbox(u8'Бесплатное подселение', imFreePodsel)
        if not imFreePodsel[0] then            
            imgui.PushItemWidth(90)
            if imgui.InputInt(u8'Цена за час [10к-1кк]', imPriceByHour,0,0) then ActivePrice = 1 end
            if not imgui.IsItemActive() and ActivePrice == 1 then
                PodselPrice = imPriceByHour[0]
                if PodselPrice == nil or PodselPrice < 10000 or PodselPrice > 1000000 then imPriceByHour[0] = 10000 PodselPrice = 10000 end
                PodselTotalPrice = PodselPrice*PodselSrok
                imTotalPrice[0] = PodselTotalPrice
            end
            if imgui.InputInt(u8'Общая цена подселения', imTotalPrice,0,0) then ActivePrice = 2 end
            if not imgui.IsItemActive() and ActivePrice == 2 then
                PodselTotalPrice = imTotalPrice[0]
                if PodselTotalPrice == nil then imTotalPrice[0] = 1000000 PodselTotalPrice = 1000000 end
                local pricebyhour = math.floor(PodselTotalPrice/PodselSrok)
                PodselPrice = pricebyhour
                if PodselPrice == nil or PodselPrice < 10000 or PodselPrice > 1000000 then
                    PodselPrice = 10000
                    PodselTotalPrice = PodselPrice*PodselSrok
                    imTotalPrice[0] = PodselTotalPrice
                end
                imPriceByHour[0] = PodselPrice
            end
            imgui.PopItemWidth()
            imgui.Separator()           
            imgui.PushItemWidth(50)
            imgui.InputInt(u8'##srok', imTime,0,0)
            if not imgui.IsItemActive() then
                local time = imTime[0]
                if time == nil or time < 1 or time > 720 then imTime[0] = 1 time = 1 end
                local multiplier = 1
                if imPeriodCombo[0] == 0 then multiplier = 1
                elseif imPeriodCombo[0] == 1 then multiplier = 24
                elseif imPeriodCombo[0] == 2 then multiplier = 168
                elseif imPeriodCombo[0] == 3 then multiplier = 720 end
                PodselSrok = time*multiplier
                if PodselSrok > 720 then imTime[0] = math.floor(720/multiplier) PodselSrok = imTime[0]*multiplier end
                if ActivePrice == 1 then -- главная цена - почасовая
                    imTotalPrice[0] = PodselPrice*PodselSrok
                    PodselTotalPrice = PodselPrice*PodselSrok
                else -- главная цена - общая   
                    PodselPrice = math.floor(PodselTotalPrice/PodselSrok)
                    if PodselPrice == nil or PodselPrice < 10000 or PodselPrice > 1000000 then
                        PodselPrice = 10000
                        PodselTotalPrice = PodselPrice*PodselSrok
                        imTotalPrice[0] = PodselTotalPrice
                    end 
                    imPriceByHour[0] = PodselPrice                
                end
            end
            imgui.PopItemWidth() 
            imgui.SameLine()     
            imgui.PushItemWidth(80)
            if imgui.Combo('##period',imPeriodCombo,imPeriodItems, #imPeriodList) then
                local multiplier = 1
                if imPeriodCombo[0] == 0 then multiplier = 1
                elseif imPeriodCombo[0] == 1 then multiplier = 24
                elseif imPeriodCombo[0] == 2 then multiplier = 168
                elseif imPeriodCombo[0] == 3 then multiplier = 720 end
                PodselSrok = imTime[0]*multiplier
                if PodselSrok > 720 then imTime[0] = math.floor(720/multiplier) PodselSrok = imTime[0]*multiplier end
                if ActivePrice == 1 then -- главная цена - почасовая 
                    imTotalPrice[0] = PodselPrice*PodselSrok
                    PodselTotalPrice = PodselPrice*PodselSrok
                else -- главная цена - общая   
                    PodselPrice = math.floor(PodselTotalPrice/PodselSrok)
                    if PodselPrice == nil or PodselPrice < 10000 or PodselPrice > 1000000 then
                        PodselPrice = 10000
                        PodselTotalPrice = PodselPrice*PodselSrok
                        imTotalPrice[0] = PodselTotalPrice
                    end     
                    imPriceByHour[0] = PodselPrice                
                end
            end            
            imgui.PopItemWidth()  
        end
		     
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
        if imgui.Button(u8('Отправить'), imgui.ImVec2(200, 30)) then
            local id = PodselID
            local price = PodselPrice
            local hours = PodselSrok
            PodselForm = id..","..price..","..hours
            PodselProcess = true
            sampSendChat("/houseold")
        end
        imgui.Link("https://romanespit.ru/lua",u8"© "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)

------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        sms(EERR.."Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function(par) 
        if par:find("%d+") then
            if sampIsPlayerConnected(par) then
                PodselID = tonumber(par)
                imPlayerID[0] = PodselID
                WinState[0] = true
            else sms(EERR.."Игрок не в сети") end
        else WinState[0] = not WinState[0] end
    end) -- Главное окно скрипта
    sampRegisterChatCommand(MAIN_CMD.."rl", function() sms(EDBG.."Перезагружаемся...") reloaded = true scr:reload() end) -- Перезагрузка скрипта
    sampRegisterChatCommand(MAIN_CMD.."upd", function() -- Обновление скрипта
        if needUpdate then
            updateScript()
        else sms(EINFO.."Вы используете актуальную версию") end
    end)
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
    RegisterScriptCommands() -- Регистрация объявленных команд скрипта
	sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    updateCheck() -- Проверка обновлений
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
    if id == 7238 and PodselProcess then
        local count = 0
        local found = false
        for line in text:gmatch('[^\r\n]+') do
            if line:find("%[X%]") then found = true break end
            count = count+1
        end
        if found then sampSendDialogResponse(id, 1, count-1)
        else 
            sampSendDialogResponse(id, 0, 0)            
		    sampCloseCurrentDialogWithButton(0)
            sms(EERR.."Вы находитесь не внутри дома")
            PodselProcess = false
            return false
        end
    end
    if id == 174 and PodselProcess then sampSendDialogResponse(id, 1, 8) end
    if id == 27129 and PodselProcess then
        if not imFreePodsel[0] then sampSendDialogResponse(id, 1, 1)
        else sampSendDialogResponse(id, 1, 0) end
    end
    if id == 198 and PodselProcess then 
        sampSendDialogResponse(id, 1, 0, PodselForm)
        if not imFreePodsel[0] then sampSendDialogResponse(id, 1, 0, PodselForm)
        else
            sampSendDialogResponse(id, 1, 0, tostring(PodselID))
            sampCloseCurrentDialogWithButton(0)
            sampSendChat("/b @"..sampGetPlayerNickname(PodselID)..", примите предложение через /offer")
            PodselProcess = false
            return false
        end
    end
    if id == 27130 and PodselProcess then 
        sampSendDialogResponse(id, 1, 0)
		sampCloseCurrentDialogWithButton(0)
        sampSendChat("/b @"..sampGetPlayerNickname(PodselID)..", примите предложение через /offer")
        PodselProcess = false
		return false
    end
end
function getNicknameById(id)
    if tonumber(id) == myid then return myNick
    elseif sampIsPlayerConnected(tonumber(id)) then return sampGetPlayerNickname(id)
    else return nil end
end
function getNearestID()
    local chars = getAllChars()
    local mx, my, mz = getCharCoordinates(PLAYER_PED)
    local nearId, dist = nil, 7
    for i,v in ipairs(chars) do
        if doesCharExist(v) and v ~= PLAYER_PED then
            local vx, vy, vz = getCharCoordinates(v)
            local cDist = getDistanceBetweenCoords3d(mx, my, mz, vx, vy, vz)
            local r, id = sampGetPlayerIdByCharHandle(v)
            if r and cDist < dist then
                dist = cDist
                nearId = id
            end
        end
    end
    return nearId
end























------------------------ External imgui funcs
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end
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
function updateScript()
	sms("Производится скачивание новой версии скрипта...")
	local dir = dirml.."/"..SCRIPT_SHORTNAME..".lua"
	local updates = nil
	downloadUrlToFile(GitHub.ScriptFile, dir, function(id, status, p1, p2)
		if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if updates == nil then 
				Logger("Ошибка при попытке обновиться.") 
				addOneOffSound(0, 0, 0, 31202)
				sms("Произошла ошибка при скачивании обновления. Попробуйте позднее...")
			end
		end
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updates = true
			Logger("Загрузка закончена")
			sms("Скачивание обновления завершено, перезагрузка скрипта...")
            addOneOffSound(0, 0, 0, 31205)
			showCursor(false)
            reloaded = true
			scr:reload()
		end
	end)
end
function updateCheck()
	sms("Проверяем наличие обновлений...")
		local dir = dirscr.."info.upd"
		downloadUrlToFile(GitHub.UpdateFile, dir, function(id, status, p1, p2)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				lua_thread.create(function()
					wait(1000)
					if doesFileExist(dirscr.."info.upd") then
						local f = io.open(dirscr.."info.upd", "r")
						local upd = decodeJson(f:read("*a"))
						f:close()
						if type(upd) == "table" then
							newversion = upd.version
							newdate = upd.release_date
							if upd.version == scr.version then
								--sms("Вы используете актуальную версию скрипта - v"..scr.version.." от "..newdate)
							else
								sms("Имеется обновление до версии v"..newversion.." от "..newdate.."! "..COLOR_YES.."/"..MAIN_CMD.."upd")
                                needUpdate = true
							end
						end
					end
				end)
			end
		end)
end
function sendTelegram(notification,msg)
	if telegram.id ~= "" and telegram.token ~= "" then
		local msg = tostring(msg):gsub('{......}', '')
		msg = tostring(msg):gsub(' ', '%+')
		msg = tostring(msg):gsub(':......:', '%%F0%%9F%%98%%B6') -- smile
		msg = tostring(msg):gsub('\\n', '%%0A')
		msg = tostring(msg):gsub('#',"\\%%23")
		msg = tostring(msg):gsub('%[',"\\%%5B")
		msg = tostring(msg):gsub('%]',"\\%%5D")
		msg = tostring(msg):gsub('@',"\\%%40")
		msg = tostring(msg):gsub('%.',"\\%%2E")
		msg = tostring(msg):gsub('-',"\\%%2D")
		msg = tostring(msg):gsub(':',"\\%%3A")
		msg = tostring(msg):gsub('/',"\\%%2F")
		msg = tostring(msg):gsub('%(',"\\%%28")
		msg = tostring(msg):gsub('%)',"\\%%29")
		msg = tostring(msg):gsub('!',"\\%%21")
		local params = "&parse_mode=MarkdownV2"
		if not notification then params = params.."&disable_notification=true" end
		local url = 'https://api.telegram.org/bot'.. telegram.token ..'/sendMessage?chat_id='.. telegram.id .. params ..'&text=' .. u8(msg)
		asyncHttpRequest('POST', url, nil, function(result) end, function(err) print('Ошибка при отправке в Telegram!') end)		
	end
end
function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
		 	local requests = require('requests')
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   end)
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