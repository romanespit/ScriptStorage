

script_author("romanespit")
script_name("Lavka Nespit")
script_version("1.1.0")
local active = false
local mylavka = 0
font = renderCreateFont("Trebuchet MS", 12, 5)
local hook = require 'lib.samp.events'
local keys = require "vkeys"
main = function()
	while not isSampAvailable() do wait(0) end
	sampRegisterChatCommand('rlavka',function() active = not active end)
	sampRegisterChatCommand('mylavka',function() if mylavka ~= 0 then sampSendChat("/findilavka "..mylavka) end end)
	userscreenX, userscreenY = getScreenResolution()
	while true do wait(0)
		if active then	        
			local canPlaceMarket = true
			local x, y, z = getCharCoordinates(PLAYER_PED)
			for IDTEXT = 0, 2048 do
				if sampIs3dTextDefined(IDTEXT) then
					local text, color, posX, posY, posZ = sampGet3dTextInfoById(IDTEXT)
					if getDistanceBetweenCoords3d(x,y,z,posX,posY,posZ) < 35 then
						if text:find("Управления товарами") and not isCentralMarket(posX, posY) then
							circleColor = 0xFFFFFFFF
							if getDistanceBetweenCoords3d(x,y,z,posX,posY,posZ) < 5 then canPlaceMarket = false circleColor = 0xFFFF0000 end					
							drawCircleIn3d(posX,posY,posZ-1.3,5,36,1.5,circleColor)
						elseif text:find("Номер бизнеса") then
							circleColor = 0xFF0000FF		
							if getDistanceBetweenCoords3d(x,y,z,posX,posY,posZ) < 25 then canPlaceMarket = false circleColor = 0xFFFF0000 end
							drawCircleIn3d(posX,posY,posZ-1.3,25,36,1.5,circleColor)
						elseif text:find("Номер дома") then
							circleColor = 0xFF0000FF		
							if getDistanceBetweenCoords3d(x,y,z,posX,posY,posZ) < 25 then canPlaceMarket = false circleColor = 0xFFFF0000 end
							drawCircleIn3d(posX,posY,posZ-1.3,25,36,1.5,circleColor)
						end
					end
				end
			end
			if isCentralMarket(x, y) then canPlaceMarket = false end
			if canPlaceMarket then renderFontDrawText(font, "Можно поставить лавку [Q]", userscreenX/3 + 30, (userscreenY - 60), 0xFF228B22)
			else renderFontDrawText(font, "Нельзя поставить лавку", userscreenX/3 + 30, (userscreenY - 60), 0xFFFF0000) end
			if isKeyJustPressed(keys.VK_Q) then
				sampSendChat("/lavka")
			end
	    end
	end
end
drawCircleIn3d = function(x, y, z, radius, polygons,width,color)
    local step = math.floor(360 / (polygons or 36))
    local sX_old, sY_old
    for angle = 0, 360, step do
        local lX = radius * math.cos(math.rad(angle)) + x
        local lY = radius * math.sin(math.rad(angle)) + y
        local lZ = z
        local _, sX, sY, sZ, _, _ = convert3DCoordsToScreenEx(lX, lY, lZ)
        if sZ > 1 then
            if sX_old and sY_old then
                renderDrawLine(sX, sY, sX_old, sY_old, width, color)
            end
            sX_old, sY_old = sX, sY
        end
    end
end
isCentralMarket = function(x, y)
	return (x > 1090 and x < 1180 and y > -1550 and y < -1429)
end
function hook.onShowDialog(id, style, title, button1, button2, text)
	if id == 3040 then
		if active then active = not active end
		mylavka = title:match("№(%d+)")
	end
end
function hook.onCreate3DText(id,color,position,distance,testLOS,attachedPlayerId,attachedVehicleId,textt)
    sampCreate3dTextEx(id, textt, color, position.x, position.y, position.z, distance, testLOS, attachedPlayerId, attachedVehicleId)
end
function hook.onRemove3DTextLabel(id)
    sampDestroy3dText(textLabelId)
end
