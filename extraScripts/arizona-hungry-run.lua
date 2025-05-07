script_author("wojciech?")
script_name("Arizona Hungry Run")
script_version("1.0.0")
local ffi = require("ffi")

function main()
	local m_bLookingAtPlayer = ffi.cast("uint8_t*", 0xB6F028 + 0x2B)
	local m_pPlayerPed = ffi.cast("uintptr_t*", 0xB6F5F0)

	while true do
		if m_bLookingAtPlayer[0] == 1 then
			if not isCharSittingInAnyCar(PLAYER_PED) and isButtonPressed(PLAYER_HANDLE, 16) then
				local m_pPlayerData = ffi.cast("uintptr_t*", m_pPlayerPed[0] + 0x480)
				local m_fSprintEnergy = ffi.cast("float*", m_pPlayerData[0] + 0x1C)
				if m_fSprintEnergy[0] < 1 then
					m_fSprintEnergy[0] = 1
				end
			end
		end
		wait(0)
	end
end