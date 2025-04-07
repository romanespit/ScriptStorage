script_author("romanespit")
script_name("Case Opener")
script_version("1.1.2")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." � "..table.concat(scr.authors, ", ")
------------------------
local hook = require 'lib.samp.events'
local wm = require 'lib.windows.message'
local encoding = require('encoding')
local faicons = require('fAwesome6')
local imgui = require 'mimgui'
local inicfg = require 'inicfg'
local effil_check, effil = pcall(require, 'effil')
local memory = require "memory"
local ffi = require 'ffi'
encoding.default = 'cp1251'
u8 = encoding.UTF8
COLOR_MAIN = '{d8572a}'
SCRIPT_COLOR = 0xFFD8572A
COLOR_YES = '{36c500}'
COLOR_NO = '{FF6A57}'
COLOR_WHITE = '{ffffff}'
SCRIPT_PREFIX = '[ CASE OPENER ]{FFFFFF}: '
local myNick = ""
local sx, sy = getScreenResolution()
local settings = inicfg.load({
    main={
		DebugMode = true,
        KostStop = true,
        BlueprintStop = false,
        BlueprintNotifications = false       
	},
    DebugPos={
        x = 220,
        y = 570
    }
},'CaseOpener')
-- MimGUI
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local WinProcess = new.bool(settings.main.DebugMode)
local KostStop = new.bool(settings.main.KostStop)
local BlueprintNotifications = new.bool(settings.main.BlueprintNotifications)
local BlueprintStop = new.bool(settings.main.BlueprintStop)
local instructions = [[
��� ������ ������ ��� ����� ������� ��� ��������� (������� I ��� Y)
����� ������� ������ ������� ������.
����� ����� �� ������ � ����� ������ ������ � ���������.
������ �������� �� ������ � ������������ ������, ������ � ��������.
����� ������ ������ ������� ������ �������� ��� ������� ������
�� ����� �������� �� ���������� ���������!
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
local button = { -- ��������� ������ ���������
    Close = 65535, -- 2112
    Use = 2302,
    Page = {2107,2108,2109,2110,2111}
}
local changepos = false
local OpenCount = 0
local DropStats = {}
local actualPage = 1
local LastClickedTD = 0
local selectedItem = 0
local selectedModel = 0
local antiLagTimer = os.clock()
local stage = "off" -- ���� ������ �������
local openStage = "off" -- ���� � �������� ��������
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
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
    MimStyle()
end)
imgui.OnFrame(function() return WinState[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/3, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(faicons('gem')..u8(" "..SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse)
        imgui.Text(instructionsText)
        imgui.Separator()
        if stage == "off" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"������� ������", imgui.ImVec2(200, 50)) then
                local found = false
                for i,v in ipairs(inventoryItem) do
                    if sampTextdrawIsExists(inventoryItem[i]) then found = true break end
                end
                if found then stage = "select" else stage = "select" sampSendChat("/invent") end
            end
        end
        if stage == "select" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"��������", imgui.ImVec2(200, 50)) then
                stopOpening()
            end
        end
        if stage == "selected" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-200)
            if imgui.Button(u8"������ ��������", imgui.ImVec2(200, 50)) then
                stage = "opening"
                openStage = "select"
            end
            imgui.SameLine()
            if imgui.Button(u8"������� ������", imgui.ImVec2(200, 50)) then
                stage = "select"
                selectedItem = 0
            end
        end
        if stage == "opening" then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8"���������� ��������", imgui.ImVec2(200, 50)) then
                stopOpening()
            end
        end
        if imgui.CollapsingHeader(u8"���������") then      
            if imgui.Checkbox(u8'������������� ��� ����� �������� ', KostStop) then
                settings.main.KostStop = not settings.main.KostStop
                inicfg.save(settings, 'CaseOpener')
                sms("��� ��������� �������� �������� "..(settings.main.KostStop and COLOR_NO.."�����������" or COLOR_YES.."�����������"))
            end
            if imgui.Checkbox(u8'�������� ����������� � ����� ������� ', BlueprintNotifications) then
                settings.main.BlueprintNotifications = not settings.main.BlueprintNotifications
                inicfg.save(settings, 'CaseOpener')
                sms("�������� ����������� � ����� ������� "..(settings.main.BlueprintNotifications and COLOR_YES.."��������" or COLOR_NO.."���������"))
            end
            if imgui.Checkbox(u8'������������� ��������, ���� ����� ����� ', BlueprintStop) then
                settings.main.BlueprintStop = not settings.main.BlueprintStop
                inicfg.save(settings, 'CaseOpener')
                sms("��� ����� ������� �������� "..(settings.main.BlueprintStop and COLOR_NO.."�����������" or COLOR_YES.."�����������"))
            end
        end
        if imgui.CollapsingHeader(u8"����������") then
            imgui.Text(u8"���������� ��������:")
            imgui.Text(u8"������� ������: "..OpenCount)
            if #DropStats > 0 then
                for i,v in ipairs(DropStats) do
                    imgui.TextColoredRGB(DropStats[i].Name..COLOR_YES.." x"..DropStats[i].Count)
                end
            end 
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'�������� ����������', imgui.ImVec2(200, 20)) then
                OpenCount = 0
                DropStats = {}
                sms("���������� ��������")
            end
        end
        imgui.Separator()        
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
		if imgui.Button(u8'Debug', imgui.ImVec2(200, 20)) then
			settings.main.DebugMode = not settings.main.DebugMode
            inicfg.save(settings, 'CaseOpener')
            sms("����� ������� "..(settings.main.DebugMode and COLOR_YES.."�������" or COLOR_NO.."��������"))
		end
        if settings.main.DebugMode then
            imgui.SetCursorPosX(imgui.GetWindowWidth()/2-100)
            if imgui.Button(u8'�������� ������� ����', imgui.ImVec2(200, 20)) then
                changepos = true
                sms("�������� ������� ���� � ������� ���")
            end
        end
        imgui.Link("https://romanespit.ru/lua",u8"� "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)
imgui.OnFrame(function() return WinState[0] and settings.main.DebugMode end, function()
    imgui.SetNextWindowPos(imgui.ImVec2(settings.DebugPos.x, settings.DebugPos.y), imgui.Cond.Always, imgui.ImVec2(1, 1))
    --imgui.SetNextWindowSize(imgui.ImVec2(300, 250), imgui.Cond.Always)
    imgui.Begin('Debug', WinProcess, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoMove+imgui.WindowFlags.NoTitleBar)
    imgui.Text(u8"��������: "..actualPage)
    imgui.Text(u8"��������� ����: "..LastClickedTD)
    imgui.Text(u8"����: "..stage)
    imgui.Text(u8"���� ��������: "..openStage)
    imgui.Text(u8"��������� tdId: "..selectedItem)
    imgui.Text(u8"������ �� TD: "..selectedModel)
    
    imgui.End()
end).HideCursor = true

function onScriptTerminate(scr, is_quit)
	if scr == thisScript() then
	end
end
function main()
	while not isSampAvailable() do wait(0) end
	thread = lua_thread.create(function() return end)
	repeat wait(100) until sampIsLocalPlayerSpawned()
	sms("�������� �������� �������. �����������: ".. COLOR_MAIN .."/co{FFFFFF}. �����: "..COLOR_MAIN.."romanespit")
	sampRegisterChatCommand('co', function() WinState[0] = not WinState[0] end)
    if not doesFileExist('moonloader/config/CaseOpener.ini') then inicfg.save(settings, 'CaseOpener') end
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    myNick = sampGetPlayerNickname(myid)
    stopOpening()
	while true do
		wait(0)
        if changepos then 
            settings.DebugPos.x, settings.DebugPos.y = getCursorPos() 
            if isKeyJustPressed(1) then
                changepos = false
                inicfg.save(settings, 'CaseOpener')
                sms("������� ���������")
            end
        end
        if not WinState[0] and stage == "opening" then
            stopOpening("���� ������� ���� �������, �������� ����������� #M-1")
        end
        if thread:status() == "dead" and ((stage == "opening" and openStage == "select") or (os.clock()-antiLagTimer > 0.37 and openStage == "pushUse")) then
			thread = lua_thread.create(function() 
                openStage = "checkModel"                
                selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem) 
                --if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("����� � ������ ����������� #M-2") end
                openStage = "waiting" 
                sampSendClickTextdraw(selectedItem)
                openStage = "pushUse"
                antiLagTimer = os.clock()
			end)
		end
    end  
    wait(-1)
end

function AddDrop(name,count)
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
        --Con_Serve ������� ����� ��� �������� 'Super Car Box' � ������� ���������: ���������� Daewoo Lanox 6x6
        if text:find("([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) ������� ����� ��� �������� '([^']*)' � ������� ���������: (.+)") and text:find(myNick) then
            stopOpening("��������� ������� �����, �������� ����������� #OSM-1")
        end
        if text:find("����� ���������� ������ ([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) ��� �������� '([^']*)' � �� ������� �������: (.+)") and text:find(myNick) and settings.main.BlueprintStop then
            stage = "selected"
            openStage = "off"
            if thread:status() ~= "dead" then thread:terminate() end
            sms("�� ������ �����! �������� ��������������, ������ ��� ����������� #OSM-2")
        end
        if text:find("�� ������� ��������� �������") then
            stopOpening("������� �� ������� ������ �� � ������, �������� ����������� #OSM-3")
        end
        if (text:find("�������� ��������� ������") or text:find("�������� ���������� ������") or text:find("�������� ��������� ������")) and settings.main.KostStop then
            stage = "selected"
            openStage = "off"
            if thread:status() ~= "dead" then thread:terminate() end
            sms("������ ��������, �������� ��������������, ��� ����� ����������� #OSM-4")
        end
        if text:find("%[������%] {FFFFFF}��������� �������") then
            selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem) 
            if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("����� � ������ ����������� #OSM-6") end
        end
    end
    if text:find("�� ������������ {cccccc}'(.+)'{ffff00}! ��� ����: {cccccc}(.+)") then
        local larec,prize,count = text:match("�� ������������ {cccccc}'(.+)'{ffff00}! ��� ����: {cccccc}(.+) %(����������: (%d+)��.%)")
        AddDrop(prize,count)        
        if text:find("�������") then stopOpening("������� ������� �����, �������� ����������� #OSM-5") end
    end
    if text:find("%[����������%] {......}��� ���������") then
        if text:find("����� �����") then AddDrop("����",text:match("(%d+)")) end
        if text:find("%$") then AddDrop("������",text:gsub("%p",""):match("(%d+)")) end
    end
    if text:find("��� ��� �������� ������� '�����: %+1 EXP %(������������%)'") then AddDrop("�����: +1 EXP",1) OpenCount = OpenCount - 1 end
    if text:find("��� ��� �������� ������� '����� ��� ���������: %+1 EXP'") then AddDrop("����� ��� ���������: +1 EXP",1) OpenCount = OpenCount - 1 end
    if text:find("����� ���������� ������ ([A-Za-z0-9%a]+_[A-Za-z0-9%a]+) ��� �������� '([^']*)' � �� ������� �������: (.+)") and not text:find(myNick) and settings.main.BlueprintNotifications then
        sms("���-�� ����� �����, ����� ������ :yum:")
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
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function hook.onSendClickTextDraw(id)
    LastClickedTD = id
    if id == 2112 or id == button.Close then
        if stage ~= "off" then
            stopOpening("��������� ��� ������, �������� ����������� #OSCTD-0")
        end
        actualPage = 1
    end
    if id == button.Page[1] then actualPage = 1 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-1") end end
    if id == button.Page[2] then actualPage = 2 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-2") end end
    if id == button.Page[3] then actualPage = 3 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-3") end end
    if id == button.Page[4] then actualPage = 4 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-4") end end
    if id == button.Page[5] then actualPage = 5 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-5") end end
    if id == button.Page[6] then actualPage = 6 if stage ~= "off" and stage ~= "select" then stopOpening("�������� ���� ��������, �������� ����������� #OSCTD-6") end end
    if id ~= selectedItem and stage == "opening" then
        stopOpening("��� ����� ������ TextDraw, �������� ����������� #OSCTD-7")
        return false
    end
    if stage == "select" then
        for i,v in ipairs(inventoryItem) do
            if inventoryItem[i] == id then 
                selectedModel = sampTextdrawGetModelRotationZoomVehColor(id)
                selectedItem = id
                if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then sms("������� � ������ �����, �������� ������") selectedItem = 0
                else stage = "selected" sms("������ ���� ������� ������� - tdID:"..id.." | Model: "..selectedModel) end
                return false
            end
        end
    end
end
function hook.onTextDrawSetString(id,text)
    if stage == "opening" and id ~= button.Use and id ~= selectedItem and sampTextdrawGetModelRotationZoomVehColor(id) ~= selectedModel then return false end
end
function hook.onTextDrawHide(id)
    if stage == "opening" and id ~= button.Use and id ~= selectedItem then return false end
end
function hook.onShowTextDraw(id,data)    
    if stage == "opening" and id ~= button.Use and id ~= selectedItem and sampTextdrawGetModelRotationZoomVehColor(id) ~= selectedModel then return false end
    if openStage == "pushUse" and id == button.Use then
        openStage = "useButtonReceived"
        selectedModel = sampTextdrawGetModelRotationZoomVehColor(selectedItem)
        if selectedModel == 0 or selectedModel == 1649 or selectedModel == 13 then stopOpening("����� � ������ ����������� #OSTD-1") return false
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