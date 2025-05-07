script_author("XRLM")
script_name("Fix 3D Texts")
script_version("1.0.0")
local sampev = require('lib.samp.events')
function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)    
    sampCreate3dTextEx(id, text, color, position.x, position.y, position.z, distance, testLOS, attachedPlayerId, attachedVehicleId)
end
function sampev.onRemove3DTextLabel(textLabelId)
    sampDestroy3dText(textLabelId)
end

