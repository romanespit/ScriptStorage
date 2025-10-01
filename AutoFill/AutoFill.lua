-- Original by JustFedot (https://www.blast.hk/members/321348/)
-- Rest in peace, legend.
------------------------ Main Variables
script_author("JustFedot","romanespit")
script_name("Gas Station AutoFill")
script_version("1.0.1")
local scr = thisScript()
SCRIPT_SHORTNAME = "AutoFill"
MAIN_CMD = "af"
COLOR_MAIN = "{4682B4}"
SCRIPT_COLOR = 0xFF4682B4
COLOR_YES = "{36C500}"
COLOR_NO = "{FF6A57}"
SCRIPT_PREFIX = COLOR_MAIN.."[ "..SCRIPT_SHORTNAME.." ]{FFFFFF}: "
local dirml = getWorkingDirectory()
------------------------ Another Variables
WORK = true
local max = 0
local current = 0
local fuelId = 0
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
------------------------ Main Function
function main()
	while not isSampAvailable() do wait(0) end
	repeat wait(100) until sampIsLocalPlayerSpawned()
    sampRegisterChatCommand(MAIN_CMD, function() WORK = not WORK sms("Автозаправка "..(WORK and COLOR_YES.."включена" or COLOR_NO.."выключена")) end)
	tech_sms("Успешная загрузка скрипта. Используйте: ".. COLOR_MAIN .."/"..MAIN_CMD.."{FFFFFF}. Авторы: "..COLOR_MAIN..table.concat(scr.authors, ", ")) -- Приветственное сообщение
    while true do
		wait(0)
    end  
    wait(-1)
end
function onSendPacket(id, bs)
    if id == 220 and WORK then
		raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 18 then
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
            if text:find('onActiveViewChanged|GasStation') then
                lua_thread.create(function() 
                    wait(1300)
                    cefSend(('purchaseFuel|%s|%s'):format(fuelId, max-current))
                end)
                
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
function onReceivePacket(id, bs)
	if id == 220 and WORK then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            if text:find('event.gasstation.initializeMaxLiters',1,true) then
                max = tonumber(text:match('`%[(%d+)%]`'))
            elseif text:find('event.gasstation.initializeCurrentLiters',1,true) then
                current = tonumber(text:match('`%[(%d+)%]`'))
            elseif text:find('event.gasstation.initializeFuelTypes',1,true) then
                local js = text:match('`%[(.+)%]`')
                if js then
                    js = decodeJson(js)
                    for k,v in pairs(js) do
                        if v.available == 1 then
                            fuelId = v.id
                        end
                    end
                end
            end
        end
    end
end