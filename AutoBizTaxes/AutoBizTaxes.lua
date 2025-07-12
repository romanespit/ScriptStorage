script_author("romanespit")
script_name("AutoBizTaxesQuest")
script_version("1.3.0")
local dialogprocess = false
local fakeerror = false
local docsort = false
function onSendPacket(id, bs)
    if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 18 then
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
			if text == "onActiveViewChanged|FindGame" then
                lua_thread.create(function()
                    cefSend("findGame.finish")
                    wait(300)
                    cefSend("sendResponse|0|0|1|")
                end)
            end
            if text == "onActiveViewChanged|NpcDialog" and dialogprocess then
                cefSend("answer.npcDialog|1")
                dialogprocess = false
            end
            if text == "onActiveViewChanged|NpcDialog" and fakeerror then
                cefSend("answer.npcDialog|0")
                fakeerror = false
            end
            if text == "onActiveViewChanged|DocumentsSortGame" then 
                lua_thread.create(function()
                    wait(1000)
                    for i = 1, 50 do wait(50) cefSend("sortBaseGame.correctMove") end
                    wait(300)
                    cefSend("sendResponse|0|0|1|")
                end)
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
            if text:find("event.npcDialog.initializeDialog") then
                if text:find("Вы хотите провести бухгалтерский учёт") 
                or text:find("Вы хотите выполнить задания для бизнеса") then dialogprocess = true end
            end
            if text:find("К сожалению Вы допустили %d ошибки при проверке документов") then fakeerror = true end
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