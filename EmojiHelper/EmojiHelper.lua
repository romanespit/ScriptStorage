--[[ Requirements:
SAMP.lua - https://www.blast.hk/threads/14624/
fAwesome6.lua - https://www.blast.hk/threads/111224/
mimgui - https://www.blast.hk/threads/66959/
]]
------------------------ Main Variables
script_author("romanespit")
script_name("Emoji Helper")
script_version("1.0.0")
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
local wm = require 'lib.windows.message'
local ffi = require 'ffi'
local encoding = require('encoding')
encoding.default = 'cp1251'
u8 = encoding.UTF8
local effil_check, effil = pcall(require, 'effil')
local dlstatus = require("moonloader").download_status
local io = require("io")
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
    Logger("���������� rmnsptScripts �� ���� �������. ������...")
end
if not doesDirectoryExist(dirml.."/rmnsptScripts/"..SCRIPT_SHORTNAME.."/") then
    createDirectory(dirscr)
    Logger("���������� rmnsptScripts/"..SCRIPT_SHORTNAME.." �� ���� �������. ������...")
end

------------------------ 
function onScriptTerminate(scr, is_quit)
	if scr == thisScript() and not is_quit and not reloaded then
        sms("������ ������������� ����������! ��������� ������� SAMPFUNCS.")
	end
end
------------------------ Script Commands
function RegisterScriptCommands()
    sampRegisterChatCommand(MAIN_CMD, function() sms("����������� � ��������/���� ��������� {e:text 123}") sms("{e:text 123} {e:jopa} => "..Modify("{e:text 123}").." "..Modify("{e:jopa}")) end) -- ������� ���� �������
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
    RegisterScriptCommands() -- ����������� ����������� ������ �������
	sms("�������� �������� �������. �����������: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. �����: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- �������������� ���������
    updateCheck() -- �������� ����������
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
    text = text:lower() -- ������ ������
    text = text:match("{e:(.-)}") -- �������� ����� ��� ������
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