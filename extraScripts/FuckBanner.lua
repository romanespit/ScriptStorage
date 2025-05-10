script_author("romanespit")
script_name("Fuck Event Banner")
script_version("1.1.0")
local hook = require 'lib.samp.events'
local closed = false

function onReceivePacket(id, bs)
	if id == 220 then
		raknetBitStreamIgnoreBits(bs, 8)
		if raknetBitStreamReadInt8(bs) == 17 then
			raknetBitStreamIgnoreBits(bs, 32)
            local length = raknetBitStreamReadInt16(bs)
            local encoded = raknetBitStreamReadInt8(bs)
            local text = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or raknetBitStreamReadString(bs, length)
            if text:find("setActiveView") and text:find("RewardsNewYear") and not closed then
                local bs = raknetNewBitStream()
                raknetBitStreamWriteInt8(bs, 220)
                raknetBitStreamWriteInt8(bs, 18)
                raknetBitStreamWriteInt16(bs, string.len("rewardsNewYear.exit"))
                raknetBitStreamWriteString(bs, "rewardsNewYear.exit")
                raknetSendBitStreamEx(bs, 1, 7, 1)
                raknetDeleteBitStream(bs)
                closed = true
            end
            
        end
    end
end
function hook.onSendClientJoin(version, mod, nickname, challengeResponse, joinAuthKey, clientVer, unknown) closed = false end
function main()
	while not isSampAvailable() do wait(0) end
	while true do
		wait(0)
    end
end