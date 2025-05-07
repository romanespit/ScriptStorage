script_author("romanespit")
script_name("Fuck Event Banner")
script_version("1.0.0")

function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            if text:find("setActiveView") and text:find("RewardBanner") then
                local bs = raknetNewBitStream()
                raknetBitStreamWriteInt8(bs, 220)
                raknetBitStreamWriteInt8(bs, 18)
                raknetBitStreamWriteInt16(bs, string.len("rewardBanner.close"))
                raknetBitStreamWriteString(bs, "rewardBanner.close")
                raknetSendBitStreamEx(bs, 1, 7, 1)
                raknetDeleteBitStream(bs)
            end
            
        end
    end
end

function main()
	while not isSampAvailable() do wait(0) end
	while true do
		wait(0)
    end
end