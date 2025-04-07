------------------------ Main Variables
script_author("romanespit")
script_name("Body Camera Overlay")
script_version("1.0.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." © "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "BodyCam"
MAIN_CMD = "bc"
COLOR_MAIN = "{FFD700}"
SCRIPT_COLOR = 0xFFFFD700
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
------------------------ 
local hook = require 'lib.samp.events'
local wm = require 'lib.windows.message'
local inicfg = require 'inicfg'
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
		
		void keybd_event(unsigned char bVk, unsigned char bScan, unsigned long dwFlags, unsigned long dwExtraInfo);

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
local faicons = require('fAwesome6')
local imgui = require 'mimgui'
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- Разрешение экрана
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Variables
local Recording = false
local RecordStartTime = nil
local ScreenProcess = false
local posedit = false

local VK_LWIN = 0x5B
local VK_LMENU = 0xA4
local VK_R = 0x52
local VK_F8 = 0x77
local KEYEVENTF_KEYUP = 0x2
local directIni = SCRIPT_SHORTNAME..'.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        enabled = false,
        posX = 40,
        posY = 665,
        id = math.random(100000, 999999),
        rod = 1,
        RP = true,
        logo = 0,
        myid = false,
        timer = true,
        winrecord = false
    }
}, directIni))
inicfg.save(ini, directIni)
------------------------ Script Directories
if not doesDirectoryExist(dirml.."/rmnsptScripts/") then
    createDirectory(dirml.."/rmnsptScripts/")
    Logger("Директория rmnsptScripts не была найдена. Успешное создание")
end
if not doesDirectoryExist(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/") then
    createDirectory(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/")
    Logger("Директория rmnsptScripts/"..SCRIPT_SHORTNAME.." не была найдена. Успешное создание")
end
if doesFileExist(dirscr..'alert.mp3') then
    audio = loadAudioStream(dirscr..'alert.mp3')
    setAudioStreamVolume(audio, 0.1)
end
------------------------ MimGUI Variables
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local imEnabled = new.bool(ini.main.enabled)
local imRP = new.bool(ini.main.RP)
local imShowRecordTime = new.bool(ini.main.timer)
local imWinRecord = new.bool(ini.main.winrecord)
local SetState = new.bool()
local imSexCombo = new.int(ini.main.rod)
local imSexList = {u8'Мужской', u8'Женский'}
local imSexItems = imgui.new['const char*'][#imSexList](imSexList)
local imCamID = new.char[256](u8(ini.main.id))
local imUseDynamicID = new.bool(ini.main.myid)
local POS = imgui.ImVec2(ini.main.posX, ini.main.posY)
local imLogoCombo = new.int(ini.main.logo)
local imLogoList = {u8'AXON BODY 4',u8'BODYCAM'}
local imLogoItems = imgui.new['const char*'][#imLogoList](imLogoList)
local Logo = {}
local LogoSize = {
    {45,45},
    {30,30}
}
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
    else Logger("Отсутствует файл EagleSans-Regular.ttf") end
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
	-- Img
	if doesFileExist(dirscr..'AxonLogo.png') then Logo[1] = imgui.CreateTextureFromFile(u8(dirscr..'AxonLogo.png')) else Logger("Отсутствует файл AxonLogo.png. Скрипт выгружен") scr:unload() end
	if doesFileExist(dirscr..'Camera.png') then Logo[2] = imgui.CreateTextureFromFile(u8(dirscr..'Camera.png')) else Logger("Отсутствует файл Camera.png. Скрипт выгружен") scr:unload() end
	if doesFileExist(dirscr..'blackdot.png') then BlackDot = imgui.CreateTextureFromFile(u8(dirscr..'blackdot.png')) else Logger("Отсутствует файл blackdot.png. Скрипт выгружен") scr:unload() end
    if doesFileExist(dirscr..'reddot.png') then RedDot = imgui.CreateTextureFromFile(u8(dirscr..'reddot.png')) else Logger("Отсутствует файл reddot.png. Скрипт выгружен") scr:unload() end
    if doesFileExist(dirscr..'engine.png') then Engine = imgui.CreateTextureFromFile(u8(dirscr..'engine.png')) else Logger("Отсутствует файл engine.png. Скрипт выгружен") scr:unload() end
    if doesFileExist(dirscr..'redengine.png') then NotEngine = imgui.CreateTextureFromFile(u8(dirscr..'redengine.png')) else Logger("Отсутствует файл redengine.png. Скрипт выгружен") scr:unload() end
    if doesFileExist(dirscr..'siren.png') then Siren = imgui.CreateTextureFromFile(u8(dirscr..'siren.png')) else Logger("Отсутствует файл siren.png. Скрипт выгружен") scr:unload() end
    if doesFileExist(dirscr..'onfoot.png') then Onfoot = imgui.CreateTextureFromFile(u8(dirscr..'onfoot.png')) else Logger("Отсутствует файл onfoot.png. Скрипт выгружен") scr:unload() end
    MimStyle()
end)
------------------------ MimGUI Frames
imgui.OnFrame(function() return WinState[0] end, -- Main Frame
    function(self)
        self.HideCursor = not posedit
        imgui.SetNextWindowPos(imgui.ImVec2(ini.main.posX, ini.main.posY), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
        imgui.Begin("##Mainwin", WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoTitleBar+(posedit and 0 or imgui.WindowFlags.NoMove + imgui.WindowFlags.NoBackground))
            POS = imgui.GetWindowPos()
            --imgui.SetCursorPos(imgui.ImVec2(20, 30))
            imgui.Image(Logo[ini.main.logo+1], imgui.ImVec2(LogoSize[ini.main.logo+1][1], LogoSize[ini.main.logo+1][2]))
            imgui.SetCursorPos(imgui.ImVec2(65, 5))
            if ScreenProcess then
                imgui.Image(RedDot, imgui.ImVec2(20, 20))
                imgui.SetCursorPos(imgui.ImVec2(85, 7))
                imgui.Text('SNAPSHOT CAPTURED', 2, imgui.ImVec4(1, 1, 1, 1), imgui.ImVec4(0, 0, 0, 1))
            elseif Recording then
                imgui.Image(RedDot, imgui.ImVec2(20, 20))
                imgui.SetCursorPos(imgui.ImVec2(85, 7))
                imgui.Text('RECORDING '..(ini.main.timer and os.date('%H:%M:%S', 75600 + (os.time()-RecordStartTime)) or ". . ."), 2, imgui.ImVec4(1, 1, 1, 1), imgui.ImVec4(0, 0, 0, 1))
            else
                imgui.Image(BlackDot, imgui.ImVec2(20, 20))
                imgui.SetCursorPos(imgui.ImVec2(85, 7))
                imgui.Text('RECORDING STOPPED', 2, imgui.ImVec4(1, 1, 1, 1), imgui.ImVec4(0, 0, 0, 1))
            end
            imgui.SetCursorPos(imgui.ImVec2(70, 21))
            imgui.Text(os.date('%Y-%m-%d %H:%M:%S')..'\n'.. imLogoList[ini.main.logo+1] ..' #'..(ini.main.myid and myid or ini.main.id), 2, imgui.ImVec4(1, 1, 1, 1), imgui.ImVec4(0, 0, 0, 1))
            if isCarSirenOn(storeCarCharIsInNoSave(PLAYER_PED)) then
                imgui.SetCursorPos(imgui.ImVec2(230, 7))
                imgui.Image(Siren, imgui.ImVec2(15, 15))
            end
            if isCharInAnyCar(PLAYER_PED) and isCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED)) then
                imgui.SetCursorPos(imgui.ImVec2(230, 35))
                imgui.Image(Engine, imgui.ImVec2(15, 15))
            elseif isCharInAnyCar(PLAYER_PED) and not isCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED)) then
                imgui.SetCursorPos(imgui.ImVec2(230, 35))
                imgui.Image(NotEngine, imgui.ImVec2(15, 15))
            end
            if not isCharInAnyCar(PLAYER_PED) then
                imgui.SetCursorPos(imgui.ImVec2(230, 35))
                imgui.Image(Onfoot, imgui.ImVec2(15, 15))
            end
        imgui.End()
    end
)
imgui.OnFrame(function() return SetState[0] end, -- Settings Frame
    function(self)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/2, sy/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
        imgui.Begin(u8(SCRIPT_TITLE), SetState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
            if imgui.Checkbox(u8'Включить', imEnabled) then
                WinState[0] = imEnabled[0]
                ini.main.enabled = imEnabled[0]
                inicfg.save(ini, directIni)
            end
            if imgui.Checkbox(u8'RP отыгровки камеры', imRP) then
                ini.main.RP = imRP[0]
                inicfg.save(ini, directIni)
            end
            if ini.main.RP then
                if imgui.Combo(u8'Пол',imSexCombo,imSexItems, #imSexList) then
                    ini.main.rod = imSexCombo[0]				
                    inicfg.save(ini, directIni)
                end
            end
            if imgui.Checkbox(u8'Время записи', imShowRecordTime) then
                ini.main.timer = imShowRecordTime[0]
                inicfg.save(ini, directIni)
            end
            if imgui.Checkbox(u8'Использовать запись Windows (WIN+ALT+R)', imWinRecord) then
                ini.main.winrecord = imWinRecord[0]
                inicfg.save(ini, directIni)
            end
            if imgui.Combo(u8'Логотип',imLogoCombo,imLogoItems, #imLogoList) then
				ini.main.logo = imLogoCombo[0]				
                inicfg.save(ini, directIni)
			end
            if imgui.InputTextWithHint(u8'Camera ID', u8'Введите ID вашей камеры', imCamID, 256) then
                ini.main.id = u8:decode(ffi.string(imCamID))                				
                inicfg.save(ini, directIni)
            end
            if imgui.Checkbox(u8'Использовать внутриигровой ID', imUseDynamicID) then
                ini.main.myid = imUseDynamicID[0]
                inicfg.save(ini, directIni)
            end
            if not posedit then
                if imgui.Button(u8'Изменить положение окна') then
                    posedit = true
                    sms("Переместите окно в нужное место и сохраните настройки")
                end
            else
                if imgui.Button(u8'Сохранить положение окна') then
                    sms('Позиция '..POS.x..', '..POS.y..' сохранена!')
                    ini.main.posX, ini.main.posY = POS.x, POS.y
                    inicfg.save(ini, directIni)
                    posedit = false
                end
            end
            imgui.Link("https://romanespit.ru/lua",u8"© "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function() SwitchRecording() end)
    sampRegisterChatCommand(MAIN_CMD.."set", function() SetState[0] = not SetState[0] end)
    sampRegisterChatCommand(MAIN_CMD.."status", function() 
    --[[Recording os.date('%H:%M:%S', 75600 + (os.time()-RecordStartTime))]]
        if ini.main.RP then
            if thread:status() ~= "dead" then thread:terminate() end
            thread = lua_thread.create(function ()
                sampSendChat("/me быстро проверил"..rod("","а").." статус бодикамеры")
                wait(1200)
                sampSendChat("/do Бодикамера "..(Recording and "включена и ведет запись уже "..os.date('%H:%M:%S', 75600 + (os.time()-RecordStartTime)) or "выключена и запись не ведётся")..".")
            end)
        else sms("Бодикамера "..(Recording and "включена и ведет запись уже "..os.date('%H:%M:%S', 75600 + (os.time()-RecordStartTime)) or "выключена и запись не ведётся"))
        end
    end)
    sampRegisterChatCommand("sc", function()
        if thread:status() ~= "dead" then thread:terminate() end
        thread = lua_thread.create(function ()
            if ini.main.RP then
                sampSendChat("/me нажал"..rod("","а").." кнопку на бодикамере, закрепленной на одежде")
                wait(1200)
                sampSendChat("/do Бодикамера сделала фотографию происходящего и загрузила фото на облачный сервер.")
            else sms("Бодикамера выключена!") end
            ScreenProcess = true
            PlayAlert()
            wait(500)
            sampSendChat("/id "..myid)
            wait(500)
            sampSendChat("/time")
            wait(700)
            ffi.C.keybd_event(VK_F8, 0, 0, 0)
            wait(20)
            ffi.C.keybd_event(VK_F8, 0, KEYEVENTF_KEYUP, 0)
            wait(2000)
            ScreenProcess = false
        end)
    end)
    
    sampRegisterChatCommand(MAIN_CMD.."rl", function() sms("Перезагружаемся...") reloaded = true scr:reload() end) -- Перезагрузка скрипта
    sampRegisterChatCommand(MAIN_CMD.."help", function() sms("Команды скрипта "..COLOR_MAIN..SCRIPT_SHORTNAME) sms(COLOR_YES.."/bc{FFFFFF} - Вкл/Выкл запись бодикамеры") sms(COLOR_YES.."/sc{FFFFFF} - Сделать скриншот") sms(COLOR_YES.."/bcstatus{FFFFFF} - Статус бодикамеры") sms(COLOR_YES.."/bcset{FFFFFF} - Настройки скрипта") end)
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
	sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/bchelp{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    RegisterScriptCommands() -- Регистрация объявленных команд скрипта
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    WinState[0] = ini.main.enabled
    while true do
		wait(0)
    end  
    wait(-1)
end
------------------------ Samp Events Hooks
function hook.onSendSpawn()
	_, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	myNick = sampGetPlayerNickname(myid)
end
------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function Logger(text)
    print(COLOR_YES..text)
end
function PlayAlert()
    if doesFileExist(dirscr..'alert.mp3') then setAudioStreamState(audio, 1) end
end
function rod(m,f)
    return (ini.main.rod == 0 and m or f)
end
function SwitchRecording()
    if ini.main.enabled then
        if thread:status() ~= "dead" then thread:terminate() end
        if Recording then           
            thread = lua_thread.create(function () 
                if ini.main.RP then
                    sampSendChat("/me нажал"..rod("","а").." кнопку на бодикамере, закрепленной на одежде")
                    wait(1200)
                    sampSendChat("/do Бодикамера выключена, запись сохранена на облачном сервере.")
                else sms("Бодикамера выключена!") end
                Recording = false
                RecordStartTime = nil
                PlayAlert()
                wait(500)
                sampSendChat("/id "..myid)
                wait(500)
                sampSendChat("/time")
                if ini.main.winrecord then
                    wait(1000)
                    -- Press keys
                    ffi.C.keybd_event(VK_LWIN, 0, 0, 0)
                    wait(20)
                    ffi.C.keybd_event(VK_LMENU, 0, 0, 0)
                    wait(20)
                    ffi.C.keybd_event(VK_R, 0, 0, 0)
                    wait(100)
                    -- Release keys
                    ffi.C.keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0)
                    ffi.C.keybd_event(VK_LMENU, 0, KEYEVENTF_KEYUP, 0)
                    ffi.C.keybd_event(VK_R, 0, KEYEVENTF_KEYUP, 0)
                end
            end)
        else            
            thread = lua_thread.create(function () 
                if ini.main.winrecord then
                    -- Press keys
                    ffi.C.keybd_event(VK_LWIN, 0, 0, 0)
                    wait(20)
                    ffi.C.keybd_event(VK_LMENU, 0, 0, 0)
                    wait(20)
                    ffi.C.keybd_event(VK_R, 0, 0, 0)
                    wait(100)
                    -- Release keys
                    ffi.C.keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0)
                    ffi.C.keybd_event(VK_LMENU, 0, KEYEVENTF_KEYUP, 0)
                    ffi.C.keybd_event(VK_R, 0, KEYEVENTF_KEYUP, 0)
                end
                if ini.main.RP then
                    sampSendChat("/me нажал"..rod("","а").." кнопку на бодикамере, закрепленной на одежде")
                    wait(1200)
                    sampSendChat("/do Бодикамера включена, запись транслируется на облачный сервер.")
                    else sms("Бодикамера включена!") end
                Recording = true
                RecordStartTime = os.time()
                PlayAlert()
                -- 0x5B-win 0xA4-lalt 0x52-R
            end)
        end
    else
        sms("Сначала включите отображение камеры - "..COLOR_MAIN.."/bcset")
    end
end
























------------------------ External imgui funcs
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
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.20, 0.20, 0.20, 0.50);
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
		if SetState[0] then
			if msg == wm.WM_KEYDOWN then
				consumeWindowMessage(true, false)
			end
			if msg == wm.WM_KEYUP then
                if posedit then
                    sms('Позиция '..POS.x..', '..POS.y..' сохранена!')
                    ini.main.posX, ini.main.posY = POS.x, POS.y
                    inicfg.save(ini, directIni)
                    posedit = false
                end
				SetState[0] = false
			end
		end
	end
end)