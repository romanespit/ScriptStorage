script_author("��z�����")
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
    -- ������ ������������ ��������� �� ������� ������ 01c3 (markCarAsNoLongerNeeded)
    local patch_index = mem.read( 0x47DFE0 + 51, 1, false)

    print(" - mister gravitos, da chto vi sebe pozvolyaete")
    print(" - lomayu igru naxer")

    -- ������ ������� ������ 01c3, ���������� ����������� ��� � ����. ��� �������, ��� � ���-�� �� �� �����, �� ��� ��������, ��� ��� �����
    mem.fill(0x47DF58 + 4*patch_index, 0x90, 4, true)
end