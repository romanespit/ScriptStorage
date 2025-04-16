--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
fAwesome6.lua - https://www.blast.hk/threads/111224/
mimgui - https://www.blast.hk/threads/66959/
]]
------------------------ Main Variables
script_author("romanespit")
script_name("Telegram Phone Notifier")
script_version("1.0.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." © "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "PhoneNotifier"
MAIN_CMD = "pn"
COLOR_MAIN = "{0BFF98}"
SCRIPT_COLOR = 0xFF0BFF98
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
COLOR_WHITE = "{FFFFFF}"
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
local effil_check, effil = pcall(require, 'effil')
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- Разрешение экрана
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Variables
local LastCaller = "None"
local LastCallerNumber = "None"
local LastSMSSender = "None"
local LastSMSText = "None"
local LastCallTime = os.clock()
local OutcomingCall = 0
------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function Logger(text)
    print(COLOR_YES..text)
end
------------------------ Default Config
local directIni = SCRIPT_SHORTNAME..".ini"
local settings = inicfg.load(inicfg.load({
    main = {
        TgChatID = "",
        TgToken = "",
        SMSNotifications = true,
        CallNotifications = true
    }
}, directIni))
function cfg()
    inicfg.save(settings, directIni)
end
cfg()
------------------------ MimGUI Variables
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local imTelegramChat = new.char[256](u8(settings.main.TgChatID))
local imTelegramToken = new.char[256](u8(settings.main.TgToken))
local imSMSNotifications = new.bool(settings.main.SMSNotifications)
local imCallNotifications = new.bool(settings.main.CallNotifications)
------------------------ 
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    --Font
	imgui.GetIO().Fonts:Clear()
    if doesFileExist(dirml..'/rmnsptScripts/EagleSans-Regular.ttf') then imgui.GetIO().Fonts:AddFontFromFileTTF(u8(dirml..'/rmnsptScripts/EagleSans-Regular.ttf'), 15, nil, glyph_ranges) else Logger("Отсутствует файл EagleSans-Regular.ttf. Скрипт выгружен") scr:unload() end
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
    MimStyle()
end)
------------------------ MimGUI Frames
imgui.OnFrame(function() return WinState[0] end, -- Main Frame
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(faicons('phone').." "..u8(SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        if imgui.Checkbox(u8'Уведомления об СМС', imSMSNotifications) then
            settings.main.SMSNotifications = imSMSNotifications[0]
            cfg()
            Logger("Уведомления в Telegram о СМС "..(settings.main.SMSNotifications and COLOR_YES.."включены" or COLOR_NO.."выключены"))
        end
        if imgui.Checkbox(u8'Уведомления о звонках', imCallNotifications) then
            settings.main.CallNotifications = imCallNotifications[0]
            cfg()
            Logger("Уведомления в Telegram о звонках "..(settings.main.CallNotifications and COLOR_YES.."включены" or COLOR_NO.."выключены"))
        end
        if imgui.InputTextWithHint(u8'Токен бота', u8'Введите токен вашего бота', imTelegramToken, 256) then
            settings.main.TgToken = u8:decode(ffi.string(imTelegramToken))
            cfg()
        end
        if imgui.InputTextWithHint(u8'ID чата в Telegram', u8'Введите ваш TG User ID', imTelegramChat, 256) then
            settings.main.TgChatID = u8:decode(ffi.string(imTelegramChat))
            cfg()
        end
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
        if imgui.Button(u8'Тестовое сообщение', imgui.ImVec2(200, 30)) then
            sendTelegram(true,"Это тестовое сообщение от скрипта `"..SCRIPT_SHORTNAME.."`, отправленное для проверки корректности введенных данных\\n\\n%C2%A9 https://romanespit.ru/lua")
            sms("Тестовое сообщение в Telegram было отправлено!")
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
    sampRegisterChatCommand(MAIN_CMD, function() WinState[0] = not WinState[0] end) -- Главное окно скрипта
    sampRegisterChatCommand(MAIN_CMD.."rl", function() sms("Перезагружаемся...") reloaded = true scr:reload() end) -- Перезагрузка скрипта
    Logger("Успешная регистрация команд скрипта")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
	sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Автор: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
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
function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            --Logger(text)
            if text:find("event.call.InitializeCaller") and settings.main.CallNotifications then
                LastCaller = text:match("`%[%\"(.+)%\"%]`")
                --Logger("LastCaller: "..LastCaller)
                if OutcomingCall ~= 0 then OutcomingCall = 1 end
            end
			if text:find("event.call.InitializeNumber") and settings.main.CallNotifications then
                LastCallerNumber = text:match("`%[%\"(.+)%\"%]`")                
                if LastCallTime+11 <= os.clock() then
                    if OutcomingCall == 0 then
                        local msg = string.format("[`".. os.date("%X") .."`] `%s` звонил(а) вам\\nПерезвонить: `/call %s`",LastCaller,LastCallerNumber)
                        sendTelegram(true,msg)                        
                        --Logger("LastCallerNumber: "..LastCallerNumber)
                        --Logger("LastCallTime: "..LastCallTime)
                    end
                    LastCallTime = os.clock()
                    if OutcomingCall == 2 then OutcomingCall = 0 end
                    if OutcomingCall == 1 then OutcomingCall = 2 end
                    
                end
                LastCaller = "None"
                LastCallerNumber = "None"
            end
            if text:find("event.messenger.notification.update") and settings.main.SMSNotifications then
                LastSMSText = text:match("%\"title%\":%\"(.+)%\",%\"contactName%\"")
                LastSMSSender = text:match("%\"contactName%\":%\"(.+)%s%(%d+%)%\"")
                --Logger("LastSMSText: "..LastSMSText)
                --Logger("LastSMSSender: "..LastSMSSender)
                local msg = string.format("[`".. os.date("%X") .."`] `%s` написал(а) вам: _%s_",LastSMSSender,LastSMSText)
                sendTelegram(true,msg)
                LastSMSText = "None"
                LastSMSSender = "None"
            end
        end
    end
end
function hook.onSendCommand(cmd)
	if cmd:find("/call ") then
		OutcomingCall = 1
	end
end
function sendTelegram(notification,msg)
	if settings.main.TgChatID ~= "" and settings.main.TgToken ~= "" then
		local msg = tostring(msg):gsub('{......}', '')
		msg = tostring(msg):gsub(' ', '%+')
		msg = tostring(msg):gsub(':......:', '%%F0%%9F%%98%%B6')
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
		local url = 'https://api.telegram.org/bot'.. settings.main.TgToken ..'/sendMessage?chat_id='.. settings.main.TgChatID .. params ..'&text=' .. u8(msg)
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