--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
fAwesome6.lua - https://www.blast.hk/threads/111224/
mimgui - https://www.blast.hk/threads/66959/
]]
------------------------ J-CFG Minified
local a,b=pcall(require,'json')local c=getWorkingDirectory and getWorkingDirectory()or''local d={encode=encodeJson or(a and b.encode or nil),decode=decodeJson or(a and b.decode or nil)}assert(d.encode and d.decode,'error, cannot use json encode/decode functions. Install JSON cfg: https://github.com/rxi/json.lua')local function e(f)local g=io.open(f,'r')if g~=nil then io.close(g)end;return g~=nil end;function Json(h,i)if not h:find('(.+)%.json$')then h=h..'.json'end;local j,k,l={},false,'UNKNOWN_ERROR'local function m(n,o)local function p(q)local r=type(q)if r~='string'then q=tostring(q)end;local s=q:find('^(%d+)')or q:find('(%p)')or q:find('\\')or q:find('%-')return s==nil and q or('[%s]'):format(r=='string'and"'"..q.."'"or q)end;local t={'{'}local o=o or 0;for q,u in pairs(n)do table.insert(t,('%s%s = %s,'):format(string.rep("    ",o+1),p(q),type(u)=="table"and m(u,o+1)or(type(u)=='string'and"'"..u.."'"or tostring(u))))end;table.insert(t,string.rep('    ',o)..'}')return table.concat(t,'\n')end;local function v(i,w)local x=0;for y,z in pairs(i)do if w[y]==nil then if type(z)=='table'then w[y]={}_,subFilledCount=v(z,w[y])x=x+subFilledCount else w[y]=z;x=x+1 end elseif type(z)=='table'and type(w[y])=='table'then _,subFilledCount=v(z,w[y])x=x+subFilledCount end end;return w,x end;local function A(B)local C=io.open(h,'w')if C then local D,E=pcall(d.encode,B)if D and E then C:write(E)end;C:close()end end;local function F()local C=io.open(h,'r')if C then local G=C:read('*a')C:close()local H,I=pcall(d.decode,G)if H and I then j=I;k=true;local J,x=v(i,j)if x>0 then A(J)return J end;return I else l='JSON_DECODE_FAILED_'..I end else l='JSON_FILE_OPEN_FAILED'end;return{}end;if not e(h)then A(i)end;j=F()return k,setmetatable({},{__call=function(self,K)if type(K)=='table'then j=K;A(j)end end,__index=function(self,y)return y and j[y]or j end,__newindex=function(self,y,L)j[y]=L;A(j)end,__tostring=function(self)return m(j)end,__pairs=function()local y,z=next(j)return function()y,z=next(j,y)return y,z end end,__concat=function()return d.encode(j)end}),k and'ok'or l end
------------------------ Main Variables
script_author("romanespit")
script_name("Roulette Opener")
script_version("1.0.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." © "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "RouletteOpener"
MAIN_CMD = "ro"
COLOR_MAIN = "{A60FAA}"
SCRIPT_COLOR = 0xFFA60FAA
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
COLOR_WHITE = "{FFFFFF}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
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
local faicons = require('fAwesome6')
local imgui = require 'mimgui'
local dirml = getWorkingDirectory() -- Директория moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- Разрешение экрана
local reloaded = false
local thread = lua_thread.create(function() return end)
------------------------ Another Variables
local stage = "notready"
local started = false
local OpenCount = 0
local NeedToOpen = 0
local DropStats = {}
------------------------ Script Directories
if not doesDirectoryExist(dirml.."/rmnsptScripts/") then
    createDirectory(dirml.."/rmnsptScripts/")
    Logger("Директория rmnsptScripts не была найдена. Успешное создание")
end
------------------------ Default Config
local cfgstatus, cfg = Json(dirml..'\\rmnsptScripts\\'..SCRIPT_SHORTNAME..'-settings.json', { 
    Turned = true,
    HasCompass = false,
    Timer = 15
});
------------------------ MimGUI Variables
local new, str = imgui.new, ffi.string
local WinState = new.bool() 
local Turned = new.bool(cfg.Turned)
local HasCompass = new.bool(cfg.HasCompass)
local Timer = new.int(cfg.Timer)
local imNeedToOpen = new.char[256](u8(tostring(NeedToOpen)))
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        sms("Скрипт непредвиденно выключился! Проверьте консоль SAMPFUNCS.")
	end
end
function onSendPacket(id, bs)
    if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 18 then
            --local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
            --("[DBG] cef send | text="..text)
            if text:find("onActiveViewChanged|CrateRoulette") then
                if started and not WinState[0] then WinState[0] = true end
                stage = "readytoopen"
                --print("[DBG] Send OAVC CR | stage="..stage)
                if started then
                    thread = lua_thread.create(function()
                        wait(300)
                        cefSend("crate.roulette.open")
                        --print("[DBG] Send cef crate.roulette.open | "..stage)
                    end)
                end
            end
        end
    end
end
--[[addEventHandler('onReceivePacket', function (id, bs)
  if id == 220 then
    raknetBitStreamIgnoreBits(bs, 8)
    if (raknetBitStreamReadInt8(bs) == 17) then
      raknetBitStreamIgnoreBits(bs, 32)
      local length = raknetBitStreamReadInt16(bs)
      local encoded = raknetBitStreamReadInt8(bs)
      local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
      --print(str) -- строка из пакета
    end
  end
end)]]
--[[
window.executeEvent('event.call.InitializeCaller', `["Fidelio_Paradoxical"]`);
window.executeEvent('event.call.InitializeNumber', `["5999655"]`);
window.executeEvent('event.messenger.notification.update', `[{"title":"xkty","contactName":"Fidelio_Paradoxical (454)","user_id":702774,"message_id":54106,"timeoutMs":6500,"image":"https://pc-cdn-az-ins.dev.arizona.games/resource/frontend/inventory/skins/256/708.png"}]`);

]]
function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
			--local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
            --print("[DBG] cef received | text="..text)
            if text:find("event.setActiveView") and not text:find("CrateRoulette") then
                stage = "notready"
            elseif text:find("event.crate.roulette.onCrateOpen") then
                stage = "notready"
                if started then
                    thread = lua_thread.create(function()
                        if cfg.HasCompass == true then 
                            wait(700)                            
                            --print("[DBG] wait 700 | hasCompass=true | stage="..stage)
                        else
                            wait(cfg.Timer*1000)
                            --print("[DBG] wait ".. cfg.Timer*1000 .." | hasCompass=true | stage="..stage)
                        end                        
                        cefSend("crate.roulette.takePrize")
                        --print("[DBG] send takePrize")
                        cefSend("crate.roulette.exit") 
                        --print("[DBG] send exit")
                        if NeedToOpen > 0 then
                            NeedToOpen = NeedToOpen-1
                            if NeedToOpen == 0 then
                                started = false
                            end
                        end
                    end)
                end
            end
        end
    end
end
------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function Logger(text)
    print(COLOR_YES..text)
end
function AddDrop(name,count)
    
    --print("[DBG] AddDrop|"..name.."|"..count)
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
function cefSend(text)
    local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 220)
	raknetBitStreamWriteInt8(bs, 18)
	--raknetBitStreamWriteInt32(bs, string.len(text))
	raknetBitStreamWriteInt16(bs, string.len(text))
	raknetBitStreamWriteString(bs, text)
	raknetSendBitStreamEx(bs, 1, 7, 1)
	raknetDeleteBitStream(bs)
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
    while true do
		wait(0)
    end  
    wait(-1)
end
------------------------ Samp Events Hook funcs
function hook.onShowDialog(id, style, title, button1, button2, text)
    if id == 0 and text:find("Поздравляем с получением") and started then 
        --print("[DBG] OSD Received")
        local prize,count = text:match("Поздравляем с получением: {......}(.+) %((%d+) шт%){......}")
        AddDrop(prize,count)
        sampSendDialogResponse(id, 1, 0, nil)
        sampCloseCurrentDialogWithButton(0)
        return false
    end
end
function hook.onServerMessage(color,text)
    if text:find("%[Подсказка%] {......}Вы получили %+%$.+%!") and started then
        --print("[DBG] OSM Received")
        AddDrop("Деньги",text:gsub("%p",""):match("(%d+)"))
    end
end
------------------------ 
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
    MimStyle()
end)
------------------------ MimGUI Frames
imgui.OnFrame(function() return WinState[0] end, -- Main Frame
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(faicons('gem').." "..u8(SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        if imgui.Checkbox(u8'Включить / Выключить скрипт', Turned) then
            cfg.Turned = Turned[0]
            cfg()
        end
        if Turned[0] and not started and stage == "readytoopen" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'Начать', imgui.ImVec2(200, 50)) then
                started = true
                cefSend("crate.roulette.open")
            end
        elseif Turned[0] and started then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'Остановить', imgui.ImVec2(200, 50)) then
                started = false
                if thread:status() ~= "dead" then thread:terminate() end
            end
        elseif Turned[0] and stage ~= "readytoopen" and not started then
            imgui.TextColoredRGB(COLOR_YES.."Выберите в инвентаре рулетку")
            imgui.TextColoredRGB(COLOR_YES.."И нажмите на ней Использовать")
        end
        if Turned[0] then
            if imgui.InputText(u8"Сколько открыть", imNeedToOpen, 256) then if u8:decode(ffi.string(imNeedToOpen)) ~= "" then NeedToOpen = tonumber(u8:decode(ffi.string(imNeedToOpen))) else NeedToOpen = 0 end end
            imgui.TextColoredRGB('Осталось открыть: '..COLOR_YES..(NeedToOpen ~= 0 and NeedToOpen or 'Пока не кончатся/остановится'))
            if imgui.Checkbox(u8'У меня есть рулеточный компас', HasCompass) then
                cfg.HasCompass = HasCompass[0]
                cfg()
            end
        end
        if not HasCompass[0] then
            if imgui.SliderInt(u8'Таймер открытия (сек)', Timer, 1, 15) then				
                cfg.Timer = Timer[0]
                cfg()
            end
            if Timer[0] < 15 then
                imgui.TextColoredRGB("{FF0000}ВНИМАНИЕ! Стандартное время открытия - 15 секунд")
                imgui.TextColoredRGB("{FF0000}Ставив время меньше 15 секунд, вы можете получить")
                imgui.TextColoredRGB("{FF0000}наказание от администрации сервера.")
                imgui.TextColoredRGB("{FF0000}Автор скрипта ответственности НЕ несёт!")
            end
        end
        if imgui.CollapsingHeader(u8"Статистика") then
            imgui.Text(u8"Статистика открытий:")
            imgui.Text(u8"Открыто рулеток: "..OpenCount)
            if #DropStats > 0 then
                for i,v in ipairs(DropStats) do
                    imgui.TextColoredRGB(DropStats[i].Name..COLOR_YES.." x"..DropStats[i].Count)
                end
            end 
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'Обнулить статистику', imgui.ImVec2(200, 20)) then
                OpenCount = 0
                DropStats = {}
                sms("Статистика сброшена")
            end
        end
        imgui.Link("https://romanespit.ru/",u8"© "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)






















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