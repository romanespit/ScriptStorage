script_author("Freym")
script_name("Arizona Anti TD Lag")
script_version("1.0.0")
local lag = true
local sampev = require 'samp.events'
function main()
    while not isSampAvailable() do wait(222) end
    AFKMessage('AntiLag-TextDraw By Freym Loaded.')
	wait(-1)
end



function sampev.onShowTextDraw(id,data)
    --AFKMessage((data.backgroundColor~=nil and data.backgroundColor or "nil").." | "..(data.boxColor~=nil and data.boxColor or "nil"))
    --[[if id >= 2136 and id <= 2212 then
        data.backgroundColor = 1
    end]]
    if data.modelId == 0 and data.zoom ~= 1 and lag == true then
        data.modelId = 1649
    end
    return {id, data}
end

AFKMessage = function(text) 
	sampAddChatMessage('[Freym-tech] {ffffff}'..tostring(text),0xFF4141) 
end