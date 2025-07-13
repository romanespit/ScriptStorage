script_author("Ѕеzлики…")
script_name("Unload Shenanigans")
script_version("1.0.0")
local mem = require "memory"

function main()
    
	if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(0)
    end

    -- https://gtamods.com/wiki/Memory_Addresses_(SA)#Misc
    -- читаем расположение указател€ на функцию опкода 01c3 (markCarAsNoLongerNeeded)
    local patch_index = mem.read( 0x47DFE0 + 51, 1, false)

    print(" - mister gravitos, da chto vi sebe pozvolyaete")
    print(" - lomayu igru naxer")

    -- нопаем функцию опкода 01c3, эффективно нейтрализу€ его к ху€м. мне кажетс€, что € что-то не то нопаю, но это работает, так что похер
    mem.fill(0x47DF58 + 4*patch_index, 0x90, 4, true)
end