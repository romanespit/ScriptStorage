-- Based on https://www.blast.hk/threads/216098/ script by Read1dno
------------------------ Main Variables
script_author("romanespit","Read1dno")
script_name("Property Checker")
script_version("1.0.0")
local scr = thisScript()
local SCRIPT_TITLE = scr.name.." v"..scr.version.." � "..table.concat(scr.authors, ", ")
SCRIPT_SHORTNAME = "PropertyChecker"
MAIN_CMD = "checkp"
COLOR_MAIN = "{9ACD32}"
SCRIPT_COLOR = 0xFF9ACD32
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
local effil_check, effil = pcall(require, 'effil')
local faicons = require('fAwesome6')
local imgui = require 'mimgui'
--local inicfg = require 'inicfg'
local https = require("ssl.https")
local ltn12 = require("ltn12")
local iconv = require("iconv")
local json = require("cjson")
local io = require("io")
local dlstatus = require("moonloader").download_status
local dirml = getWorkingDirectory() -- ���������� moonloader
local dirscr = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/"
local sx, sy = getScreenResolution() -- ���������� ������
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
------------------------ Another Variables
-- ������� �������� � �� IP-�������
local servers = {
    ["185.169.134.3"] = "1",
    ["185.169.134.4"] = "2",
    ["185.169.134.43"] = "3",
    ["185.169.134.44"] = "4",
    ["185.169.134.45"] = "5",
    ["185.169.134.5"] = "6",
    ["185.169.134.59"] = "7",
    ["185.169.134.61"] = "8",
    ["185.169.134.107"] = "9",
    ["185.169.134.109"] = "10",
    ["185.169.134.166"] = "11",
    ["185.169.134.171"] = "12",
    ["185.169.134.172"] = "13",
    ["185.169.134.173"] = "14",
    ["185.169.134.174"] = "15",
    ["80.66.82.191"] = "16",
    ["80.66.82.190"] = "17",
    ["80.66.82.188"] = "18",
    ["80.66.82.168"] = "19",
    ["80.66.82.159"] = "20",
    ["80.66.82.200"] = "21",
    ["80.66.82.144"] = "22",
    ["80.66.82.132"] = "23",
    ["80.66.82.128"] = "24",
    ["80.66.82.113"] = "25",
    ["80.66.82.82"] = "26",
    ["80.66.82.87"] = "27",
    ["80.66.82.54"] = "28",
    ["80.66.82.39"] = "29",
    ["80.66.82.33"] = "30",
}
local Error = false
local ErrorText = ""
local PropertyData = nil
local nickname = nil
local ActiveTab = 1
------------------------ Another Funcs
function sms(text)
    sampAddChatMessage(SCRIPT_PREFIX..text, SCRIPT_COLOR)
end
function Logger(text)
    print(COLOR_YES..text)
end
function CheckAndDownloadFiles()
    needLoad = 0
    NeedToLoad = {}
    if not doesFileExist(dirml..'/rmnsptScripts/EagleSans-Regular.ttf') then table.insert(NeedToLoad, {'https://github.com/romanespit/ScriptStorage/blob/main/extraFiles/EagleSans-Regular.ttf?raw=true',dirml..'/rmnsptScripts/EagleSans-Regular.ttf'}) needLoad = needLoad+1 end
    if needLoad ~= 0 then
        Logger("��������� �������� "..needLoad.." ������. ������� ����������...")
        for k,v in ipairs(NeedToLoad) do
            downloadUrlToFile(v[1], v[2], function(id, status, p1, p2)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    lua_thread.create(function()
                        wait(1000)
                        if doesFileExist(v[2]) then
                            Logger("�������� �������� ����� "..v[2]:match(".+(rmnsptScripts/.+)"))
                            needLoad = needLoad-1
                        end
                    end)
                end
            end)
        end
    end
    repeat wait(100) until needLoad == 0
    if #NeedToLoad > 0 then sms("�������� ����������� ������ ���������. ���������������...") reloaded = true scr:reload() end
end
------------------------ Script Directories
if not doesDirectoryExist(dirml.."/rmnsptScripts/") then
    createDirectory(dirml.."/rmnsptScripts/")
    Logger("���������� rmnsptScripts �� ���� �������. ������...")
end
if not doesDirectoryExist(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/") then
    createDirectory(dirscr)
    Logger("���������� rmnsptScripts/"..SCRIPT_SHORTNAME.." �� ���� �������. ������...")
end
if doesFileExist(dirml.."/rmnsptScripts/Alert.mp3") then
    audio = loadAudioStream(dirml.."/rmnsptScripts/Alert.mp3")
    setAudioStreamVolume(audio, 0.1)
end
------------------------ MimGUI Variables
local WHeight = 120
local new, str = imgui.new, ffi.string
local WinState = new.bool()
local imSearchFilter = new.char[256]()
local Slider = new.int()
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
    end
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 14, config, iconRanges)
    MimStyle()
end)
--------

-- ������� ��� ��������� ������ �������
local function getServerName()
    while not isSampAvailable() do
        wait(100)
    end

    local address = sampGetCurrentServerAddress()
    if address then
        return servers[address] or "Unknown Server"
    else
        return "Unknown Server"
    end
end
-- ������� ��� �������� � ���������� JSON ������������
local function loadAndSaveConfig()
    local serverName = getServerName()
    local url = "https://n-api.arizona-rp.com/api/map/" .. serverName
    local response_body = {}

    local res, code = https.request{
        url = url,
        sink = ltn12.sink.table(response_body),
        headers = {
            ["Referer"] = "https://arizona-rp.com/"
        },
        protocol = "tlsv1_2"
    }

    if code == 200 then
        local response_str = table.concat(response_body)
        local converter = iconv.new("CP1251", "UTF-8")
        local response_cp1251, conversion_error = converter:iconv(response_str)

        if not conversion_error then
            local data = json.decode(response_cp1251)
            local filepath = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME..".json"
            local file = io.open(filepath, "w")
            if file then
                file:write(json.encode(data))
                file:close()
                return data
            else
                return nil
            end
        else
            return nil
        end
    else
        sms("�� ������� �������� ������. HTTP ���: " .. tostring(code), 0xFF0000)
        return nil
    end
end

-- ������� ��� �������� JSON ������������ �� �����
local function loadConfigFromFile()
    local filepath = dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME..".json"
    local file = io.open(filepath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return json.decode(content)
    else
        return nil
    end
end

-- ������� ��� ������ ����� �� ���������
local function findHousesByOwner(data, ownerName)
    local result = {}

    -- ����� ����� � ����������
    for _, house in ipairs(data.houses.hasOwner) do
        if house.owner == ownerName then
            table.insert(result, { id = house.id - 1, posx = house.lx, posy = house.ly })
        end
    end

    -- ����� ����� �� ��������
    for _, house in ipairs(data.houses.onAuction) do
        if house.owner == ownerName then
            table.insert(result, { id = house.id - 1, posx = house.lx, posy = house.ly })
        end
    end

    return result
end

-- ������� ��� ������ �������� �� ���������
local function findBusinessesByOwner(data, ownerName)
    local result = {}

    -- ����� �������� � ��������� onAuction
    for _, business in ipairs(data.businesses.onAuction) do
        if business.owner == ownerName then
            table.insert(result, { id = business.id - 1, name = business.name, posx = business.lx, posy = business.ly })
        end
    end

    -- ����� �������� � ��������� noAuction
    for _, category in pairs(data.businesses.noAuction) do
        for _, business in ipairs(category) do
            if business.owner == ownerName then
                table.insert(result, { id = business.id - 1, name = business.name, posx = business.lx, posy = business.ly })
            end
        end
    end

    return result
end

-- ������� ��� ��������� ���� �� ID
local function getNicknameById(id)
    if tonumber(id) == myid then return myNick
    elseif sampIsPlayerConnected(tonumber(id)) then return sampGetPlayerNickname(id)
    else return nil end
end
------------------------ MimGUI Frames
imgui.OnFrame(function() return WinState[0] end, -- Main Frame
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sx/2, sy/3), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, WHeight), imgui.Cond.Always)
        imgui.Begin(faicons('gem').." "..u8(SCRIPT_TITLE), WinState, imgui.WindowFlags.AlwaysAutoResize+imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoScrollbar)      
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-122.5)
        imgui.PushItemWidth(200)
        imgui.InputTextWithHint('##search', u8'������� ID ��� ������� ������', imSearchFilter, 256)
        imgui.PopItemWidth()
        imgui.SameLine()
        if imgui.Button(faicons.TRASH_CAN, imgui.ImVec2(40, 25)) then imgui.StrCopy(imSearchFilter, '') end
        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-122.5)
        if imgui.Button(u8'�����', imgui.ImVec2(245, 30)) then
            Error = false
            ErrorText = ""
            local nicknameOrId = u8:decode(ffi.string(imSearchFilter))
            if tonumber(nicknameOrId) then
                nickname = getNicknameById(nicknameOrId)
                if not nickname then
                    Error = true
                    ErrorText = "����� � ID " .. nicknameOrId .. " �� ������"
                    WHeight = 140
                end
            else
                nickname = nicknameOrId
            end
            if nickname then imgui.StrCopy(imSearchFilter, u8(nickname)) end
            PropertyData = loadConfigFromFile()
        end
        if PropertyData and not Error then
            local houses = findHousesByOwner(PropertyData, nickname)
            local businesses = findBusinessesByOwner(PropertyData, nickname)          
            if #houses == 0 and #businesses == 0 then WHeight = 140 Error = true ErrorText = "����� "..nickname.." �� ������� �������������"
            else
                if ActiveTab == 1 then WHeight = 175+(#houses*32.9) else WHeight = 175+(#businesses*32.9) end
                if imgui.BeginTabBar('Tabs') then
                    if #houses > 0 then
                        if imgui.BeginTabItem(u8'����') then -- ����� �������� ������ ������� 
                            ActiveTab = 1
                            Error = false
                            ErrorText = ""
                            imgui.Columns(3)
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/5)
                            imgui.NextColumn()
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/2.5)
                            imgui.NextColumn()
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/2.5)
                            imgui.Columns(1)
                            imgui.Separator()
                            for _, house in ipairs(houses) do
                                imgui.Columns(3)
                                if imgui.Button(u8'#'..house.id, imgui.ImVec2(imgui.GetWindowWidth()/5-10, 25)) then sampSendChat("/findihouse "..house.id) end imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/5)
                                imgui.NextColumn()
                                imgui.Text(u8(calculateCity(house.posx, house.posy))) imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/2.5)
                                imgui.NextColumn()
                                imgui.Text(u8(calculateZoneRu(house.posx, house.posy))) imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/2.5)
                                imgui.Columns(1)
                                imgui.Separator()
                            end
                            imgui.EndTabItem()
                        end
                    end
                    if #businesses > 0 then
                        if imgui.BeginTabItem(u8'�������') then -- ����� �������� ������ �������
                            ActiveTab = 2
                            Error = false
                            ErrorText = ""
                            imgui.Columns(4)
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.15)
                            imgui.NextColumn()
                            imgui.Text(u8'���') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.325)
                            imgui.NextColumn()
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/5)
                            imgui.NextColumn()
                            imgui.Text(u8'�����') imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.325)
                            imgui.Columns(1)
                            imgui.Separator()
                            for _, business in ipairs(businesses) do
                                imgui.Columns(4)
                                if imgui.Button(u8'#'..business.id, imgui.ImVec2(imgui.GetWindowWidth()*0.15-10, 25)) then sampSendChat("/findibiz "..business.id) end imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.15)
                                imgui.NextColumn()
                                imgui.Text(u8(business.name)) imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.325)
                                imgui.NextColumn()
                                imgui.Text(u8(calculateCity(business.posx, business.posy))) imgui.SetColumnWidth(-1, imgui.GetWindowWidth()/5)
                                imgui.NextColumn()
                                imgui.Text(u8(calculateZoneRu(business.posx, business.posy))) imgui.SetColumnWidth(-1, imgui.GetWindowWidth()*0.325)
                                imgui.Columns(1)
                                imgui.Separator()
                            end
                            imgui.EndTabItem()
                        end
                    end
                    imgui.EndTabBar()
                end
            end
        end
        if Error then
            imgui.Text(u8(ErrorText))
        end
		--end
        imgui.Link("https://romanespit.ru/lua",u8"� "..table.concat(scr.authors, ", "))
        imgui.End()
    end
)
------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        sms("������ ������������� ����������! ��������� ������� SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function(par)        
        if par:find("(.+)") then
            Error = false
            ErrorText = ""
            local nicknameOrId = par
            if tonumber(nicknameOrId) then
                nickname = getNicknameById(nicknameOrId)
                if not nickname then
                    sms("����� � ID " .. nicknameOrId .. " �� ������")
                    Error = true
                    ErrorText = "����� � ID " .. nicknameOrId .. " �� ������"
                    WHeight = 140
                end
            else
                nickname = nicknameOrId
            end
            if nickname then imgui.StrCopy(imSearchFilter, u8(nickname)) WinState[0] = true end
            PropertyData = loadConfigFromFile()
        else
            WinState[0] = not WinState[0]
        end
    end) -- ������� ���� �������
    sampRegisterChatCommand(MAIN_CMD.."rl", function() sms("���������������...") reloaded = true scr:reload() end) -- ������������ �������
    sampRegisterChatCommand(MAIN_CMD.."upd", function() -- ���������� �������
        if needUpdate then
            updateScript()
        else sms("�� ����������� ���������� ������") end
    end)
    Logger("�������� ����������� ������ �������")
end
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
    CheckAndDownloadFiles()
    RegisterScriptCommands() -- ����������� ����������� ������ �������
    loadAndSaveConfig() -- �������� � ���������� ������������ ��� ������
	sms("�������� �������� �������. �����������: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. �����: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- �������������� ���������
    updateCheck() -- �������� ����������
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

function calculateZoneRu(x, y) -- JusticeHelper MTG MODS
    local streets = {
        {"���� ������", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
        {"��������", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
        {"���� ������", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
        {"��������", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
        {"������", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
        {"�����-�����", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
        {"��������� ��", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
        {"�������� ����", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
        {"����������� ��������", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
        {"���� ������", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
        {"�����", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
        {"������� �����", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
        {"�������� ���� ��", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
        {"���-������", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
        {"������", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
        {"�������� �����-���", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
        {"������� �����", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
        {"��������� ���������", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
        {"������� ������", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
        {"������� ������", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
        {"����������� ����������", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
        {"���� ��������", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
        {"������� ������-����", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
        {"������� �����", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
        {"����������", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
        {"����������", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
        {"���� ������", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
        {"����������", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
        {"��������� �����", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
        {"����������", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
        {"�������� �����", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
        {"�����", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
        {"������� ���������", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
        {"������� �����", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
        {"�������� ��������", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
        {"��������� �������", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
        {"����������� ��������", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
        {"��������", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
        {"�����-����", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
        {"�����", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
        {"������", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
        {"������� �����", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
        {"�����-����", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
        {"������� �����", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
        {"����������� ��������", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
        {"��������� �����", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
        {"����������", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
        {"������ ������", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
        {"������� ��������", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
        {"��������", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
        {"����������", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
        {"���� ��� ������", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
        {"�����", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
        {"����������", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
        {"����������", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
        {"������-��������", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
        {"���-�������", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
        {"���-�������", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
        {"������", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
        {"�������� ����", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
        {"�������� �����", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
        {"����������", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
        {"�������� �����", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
        {"�����", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
        {"��������� �������", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
        {"�����", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
        {"��������", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
        {"������", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
        {"�����", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
        {"��������� ��", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
        {"���������� �����", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
        {"����������", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
        {"���-�������", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
        {"���������� �����", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
        {"�����", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
        {"���-������", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
        {"���������� �����", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
        {"�����", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
        {"�������", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
        {"�����", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
        {"�������� �����", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
        {"������� �����", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
        {"�����", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
        {"����������", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
        {"�������-�����", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
        {"�����", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
        {"���� �������", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
        {"���� ������", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
        {"������������ �����", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
        {"����������", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
        {"�����", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
        {"����������", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
        {"����������", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
        {"����� �����", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
        {"�������", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
        {"��������� ����", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
        {"������������ �����", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
        {"�������� �����", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
        {"�����", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
        {"���� ����", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
        {"�������� �����-���", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
        {"���� ������", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
        {"�����", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
        {"����������", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
        {"����� ������", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
        {"��������", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
        {"�������", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
        {"��������� ���������", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
        {"������� �����", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
        {"���� ����", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
        {"�����", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
        {"������� �������", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
        {"����������", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
        {"���� ����", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
        {"���-�������", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
        {"����������", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
        {"�������� �����", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
        {"������������ �����", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
        {"�����", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
        {"����-���������", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
        {"�����", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
        {"����������� �����", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
        {"���-�������", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
        {"����������", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
        {"�����", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
        {"��������� ��������", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
        {"������� �����", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
        {"��������� �����", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
        {"������", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
        {"�����-�����", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
        {"������� ���������", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
        {"���� ����", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
        {"�������� ����", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
        {"��������-���", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
        {"���� ������", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
        {"��������� ��", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
        {"������ ��������", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
        {"�������", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
        {"��������", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
        {"�������", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
        {"�����", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
        {"������� �����", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
        {"������������ �����", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
        {"��������� ��", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
        {"����� ������", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
        {"������", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
        {"�������", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
        {"��������� ��", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
        {"�����", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
        {"��������� �������", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
        {"�����", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
        {"��������� ��������", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
        {"������", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
        {"�������", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
        {"����������� ����������", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
        {"����������", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
        {"�����", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
        {"�����-����", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
        {"��������", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
        {"���� ������", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
        {"���� ������", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
        {"���� �������", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
        {"���� �������", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
        {"���� ������", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
        {"������������", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
        {"���� �������", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
        {"���� �������", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
        {"������������ �����", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
        {"����������� �����", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
        {"�������� ������", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
        {"�������� �����", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
        {"��������� ����", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
        {"���� ������", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
        {"����������", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
        {"���������", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
        {"��������� ������", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
        {"��������� ����", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
        {"�������� �����-���", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
        {"������ �����", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
        {"�����-�����", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
        {"������", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
        {"�������� ��������", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
        {"������", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
        {"������", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
        {"��������� ����", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
        {"����������", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
        {"������� �����", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
        {"������� �����", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
        {"���� ������", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
        {"����� �����", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
        {"��������� ��", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
        {"������� ���������", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
        {"���-�������", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
        {"����������", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
        {"��������� ����", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
        {"��������� ��", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
        {"������", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
        {"���� ������", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
        {"����������", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
        {"�������� ���������", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
        {"������ ���-������", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
        {"��������� ����", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
        {"������", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
        {"��������-������", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
        {"�����", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
        {"���-������", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
        {"������� ��������", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
        {"������� ������", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
        {"�������� �����", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
        {"���-������", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
        {"������ �����", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
        {"�����-����", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
        {"���� ������", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
        {"����������� ������", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
        {"������-����", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
        {"��������� ����", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
        {"����������", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
        {"�����", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
        {"������������ �����", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
        {"����������", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
        {"����� ������", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
        {"�������-�����", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
        {"������ 4 �������", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
        {"��������", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
        {"�������� �����", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
        {"���� ��� ������", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
        {"�������", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
        {"�������� ��������", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
        {"������", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
        {"����� �������", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
        {"���-���������", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
        {"������ ������", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
        {"���� ����", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
        {"���� ������", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
        {"�����", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
        {"�������", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
        {"��������", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
        {"�������-�������", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
        {"�������������", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
        {"���-������", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
        {"������� �����", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
        {"������ ������", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
        {"���-��������", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
        {"������ ���������", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
        {"����������� ��������", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
        {"������", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
        {"�������� �����-���", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
        {"��������� ��������", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
        {"��������� ���������", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
        {"������ ��������", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
        {"������ �����", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
        {"������", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
        {"������", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
        {"����������", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
        {"������� �����", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
        {"�����-�����-�����", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
        {"������� ����� �������", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
        {"����� �����-����", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
        {"������� �������", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
        {"��������� ����", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
        {"������", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
        {"��������� ���������", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
        {"��������� ����", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
        {"�����-�����", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
        {"��������", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
        {"������� ������", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
        {"���� ����", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
        {"������� �����", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
        {"�������� ��������", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
        {"������", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
        {"���� ����", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
        {"��� Probe Inn", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
        {"����������� �����", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
        {"���-�������", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
        {"������-����-����", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
        {"���������� ������", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
        {"��������� ������", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
        {"�����-�����", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
        {"�����-����-������", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
        {"����������� �����", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
        {"�����", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
        {"����������� ������", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
        {"��������", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
        {"��������", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
        {"��������", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
        {"������� ���", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
        {"��������", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
        {"���-��������", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
        {"�������� ���������", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
        {"�������� �����-���", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
        {"�������� ������", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
        {"����������", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
        {"��������� ����", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
        {"���-������� �����", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
        {"�������� �����", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
        {"����������� �����", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
        {"�������� ������", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
        {"�����-����", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
        {"����� �����", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
        {"����-������", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
        {"�������� ����", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
        {"�����-����", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
        {"��������", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
        {"��������� ������", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
        {"������� �����", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
        {"��������� ������", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
        {"����� ���-������", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
        {"��������", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
        {"������", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
        {"���-��������-�����", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
        {"��������-����", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
        {"��������-������", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
        {"����-���������", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
        {"���������� �����", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
        {"���� ������", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
        {"������ ������", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
        {"����-����-�����", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
        {"������� ������", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
        {"�����", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
        {"����� �������", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
        {"�������� ���������", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
        {"���������� �����", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
        {"������", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
        {"����������", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
        {"����", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
        {"��������", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
        {"���� �����-�����", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
        {"����������� ����������", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
        {"�������-����", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
        {"¸�����-������", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
        {"�����-�������", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
        {"������ ���-�-���", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
        {"�������� ��������", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
        {"���� �����-�����", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
        {"������������", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
        {"��������", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
        {"����� �����", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
        {"������������", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
        {"�������� ����", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
        {"��������� ����", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
        {"�������� �����-���", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
        {"�������-�������", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
        {"������-�����", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
        {"����� �����", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
        {"����� ��", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
        {"������", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
        {"���� ������", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
        {"����-������", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
        {"������ ������", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
        {"�����-�����", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
        {"����-����", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
        {"�������", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
        {"��������", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
        {"�������� ��������", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
        {"���������", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
        {"����-���", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
        {"������ ������", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
        {"��������", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
        {"���������-����", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
        {"����� ��", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
        {"��������� ����", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
        {"���� ������", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
        {"���� ������", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
        {"�������� �����-���", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
        {"����������", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
        {"�������� �����", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
        {"���-�-������", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
        {"���� ������", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
        {"������ ������", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
        {"����� �����", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
        {"��������", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
        {"��������� �����", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
        {"������ ������", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
        {"���������� ��", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
        {"���������� ��", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
        {"�������� �����", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
        {"���������� ��", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}
    }
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (x <= v[5]) and (y <= v[6]) then
            return v[1]
        end
    end
    return '����������'
end
function calculateCity(x, y)
    local CityName = {
        { "Las Venturas", 863.9375, 608, 2999.9375, 3000 },
        { "Bone County", -613.09375, 461, 863.90625, 3000 },
        { "Tierra Robada", -3000, 1793, -612, 3000 },
        { "Tierra Robada", -1759.10400390625, 1627, -613.10400390625, 1793 },
        { "Tierra Robada", -1241.1040649414062, 626.9999542236328, -613.1040649414062, 1626.9999542236328 },
        { "Red County", 863.9375, 461, 2999.9375, 608 },
        { "Red County", -986.015625, -332, 3000, 461 },
        { "Red County", -251.015625, -740.984375, 2999.984375, -331.984375 },
        { "Los Santos", 48.96875, -2999.96875, 3000.03125, -740.96875 },
        { "San Fierro", -3000, 1626, -1759, 1793 },
        { "San Fierro", -3000, -700.9921875, -1241, 1626.0078125 },
        { "San Fierro", -1241.125, -331, -987.125, 627 },
        { "Tierra Robada", -986.09375, 460, -613.09375, 627 },
        { "San Fierro", -1241, -398, -993, -331 },
        { "San Fierro", -1241, -482.00018310546875, -1132, -398.00018310546875 },
        { "San Fierro", -1241, -560.0001831054688, -1157, -482.00018310546875 },
        { "San Fierro", -1241, -701.0001831054688, -1197, -560.0001831054688 },
        { "San Fierro", -3000, -889.984375, -1783, -700.984375 },
        { "San Fierro", -2235, -1010.9765625, -1783, -889.9765625 },
        { "San Fierro", -2193, -1081.9609375, -1783, -1010.9609375 },
        { "San Fierro", -2129.0078125, -1156.95703125, -1783.0078125, -1081.95703125 },
        { "San Fierro", -2083.0234375, -1232.953125, -1783.0234375, -1156.953125 },
        { "San Fierro", -2043.02734375, -1298.953125, -1783.02734375, -1232.953125 },
        { "San Fierro", -1999.00390625, -1345.94921875, -1783.00390625, -1298.94921875 },
        { "Flint County", -993.0250244140625, -741.0001525878906, -251.0250244140625, -332.0001525878906 },
        { "Flint County", -1132.0000305175781, -482.0001525878906, -993.0000305175781, -398.0001525878906 },
        { "Flint County", -1157, -560, -993, -482 },
        { "Flint County", -1197, -701, -993, -560 },
        { "Flint County", -1783, -1486.984375, -993, -700.984375 },
        { "San Fierro", -1966.6364135742188, -1387.94873046875, -1783.6364135742188, -1345.94873046875 },
        { "San Fierro", -1924.3333129882812, -1426.9479217529297, -1783.3333129882812, -1387.9479217529297 },
        { "San Fierro", -1882.9999389648438, -1486.9479370117188, -1782.9999389648438, -1426.9479370117188 },
        { "Flint County", -1211.28125, -2999.9765625, 48.71875, -1486.9765625 },
        { "Flint County", -993.03125, -1487, 48.96875, -741 },
        { "Flint County", -1768.73583984375, -1557.9797668457031, -1211.73583984375, -1486.9797668457031 },
        { "Flint County", -1689.2926635742188, -1673.9741516113281, -1211.2926635742188, -1557.9741516113281 },
        { "Flint County", -1372.7301635742188, -1739.9685668945312, -1211.7301635742188, -1673.9685668945312 },
        { "Flint County", -1322.2926635742188, -1839.962890625, -1211.2926635742188, -1739.962890625 },
        { "Whetstone", -3000, -3000.015625, -2235, -889.984375 },
        { "Whetstone", -2235, -2999.96875, -2193, -1010.96875 },
        { "Whetstone", -2192.9999389648438, -3000.0179290771484, -2128.9999389648438, -1081.9554290771484 },
        { "Whetstone", -2129.03125, -3000, -2083.03125, -1156.9375 },
        { "Whetstone", -2083.0450859069824, -3000.0037536621094, -1966.0450859069824, -1345.9412536621094 },
        { "Whetstone", -2083.031219482422, -1346.947998046875, -2042.0312194824219, -1232.947998046875 },
        { "Whetstone", -2042.03125, -1346.953125, -1998.03125, -1298.953125 },
        { "Whetstone", -1966.640625, -3000.0107421875, -1923.640625, -1387.9482421875 },
        { "Whetstone", -1924.3333282470703, -2999.9479217529297, -1883.3333282470703, -1426.9479217529297 },
        { "Whetstone", -1883, -3000.0157470703125, -1768, -1486.9844970703125 },
        { "Whetstone", -1768, -3000, -1212, -1839.953125 },
        { "Whetstone", -1768, -1839.96875, -1373, -1673.96875 },
        { "Whetstone", -1372.7395629882812, -1839.95849609375, -1322.7395629882812, -1739.95849609375 },
        { "Whetstone", -1768.7374877929688, -1674.9748992919922, -1688.7374877929688, -1557.9748992919922 }
    }
    for i, v in ipairs(CityName) do
        if (x >= v[2]) and (y >= v[3]) and (x <= v[4]) and (y <= v[5]) then
            return v[1]
        end
    end
    return '����������'
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
    Logger("����� mimgui ������� ���������")
end
function updateScript()
	sms("������������ ���������� ����� ������ �������...")
	local dir = dirml.."/"..SCRIPT_SHORTNAME..".lua"
	local updates = nil
	downloadUrlToFile(GitHub.ScriptFile, dir, function(id, status, p1, p2)
		if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if updates == nil then 
				Logger("������ ��� ������� ����������.") 
				addOneOffSound(0, 0, 0, 31202)
				sms("��������� ������ ��� ���������� ����������. ���������� �������...")
			end
		end
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updates = true
			Logger("�������� ���������")
			sms("���������� ���������� ���������, ������������ �������...")
            addOneOffSound(0, 0, 0, 31205)
			showCursor(false)
            reloaded = true
			scr:reload()
		end
	end)
end
function updateCheck()
	sms("��������� ������� ����������...")
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
                            sms("�� ����������� ���������� ������ ������� - v"..scr.version.." �� "..newdate)
                        else
                            sms("������� ���������� �� ������ v"..newversion.." �� "..newdate.."! "..COLOR_YES.."/"..MAIN_CMD.."upd")
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
		asyncHttpRequest('POST', url, nil, function(result) end, function(err) print('������ ��� �������� � Telegram!') end)		
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