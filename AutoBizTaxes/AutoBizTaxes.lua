script_author("romanespit")
script_name("AutoBizTaxesQuest")
script_version("1.1.0")
local dialogprocess = false
function onSendPacket(id, bs)
    if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
        if raknetBitStreamReadInt8(bs) == 18 then
            local text = raknetBitStreamReadString(bs, raknetBitStreamReadInt16(bs))
			if text == "onActiveViewChanged|FindGame" then
                lua_thread.create(function()
                    cefSend("findGame.finish")
                    wait(200)
                    cefSend("sendResponse|0|0|1|")
                end)
            end
            if text == "onActiveViewChanged|NpcDialog" and dialogprocess then
                lua_thread.create(function()
                    wait(250)
                    cefSend("answer.npcDialog|1")
                    dialogprocess = false
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
            if text:find("event.npcDialog.initializeDialog") and text:find("Вы хотите провести бухгалтерский учёт") then
                if text:find("Вы хотите провести бухгалтерский учёт") 
                or text:find("Вы хотите выполнить задания для бизнеса") then dialogprocess = true end
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