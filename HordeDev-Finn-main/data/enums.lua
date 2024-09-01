local enums = {
    quests = {
        pit_ongoing = 1815152,
        pit_started = 1922713
    },
    portal_names = {
        horde_portal = "Portal_Dungeon_Generic"
    },
    misc = {
        obelisk = "TWN_Kehj_IronWolves_PitKey_Crafter",
        blacksmith = "TWN_Scos_Cerrigar_Crafter_Blacksmith",
        jeweler = "TWN_Scos_Cerrigar_Vendor_Weapons",
        portal = "TownPortal"
    },
    positions = {
        obelisk_position = vec3:new(-1659.1735839844, -613.06573486328, 37.2822265625),
        blacksmith_position = vec3:new(-1685.5394287109, -596.86566162109, 37.6484375),
        jeweler_position = vec3:new(-1658.699219, -620.020508, 37.888672), 
        portal_position = vec3:new(-1656.7141113281, -598.21716308594, 36.28515625) 
        
        
    },
    chest_types = {
        [0] = { key = "GEAR", value = "BSK_UniqueOpChest_Gear" },
        [1] = { key = "MATERIALS", value = "BSK_UniqueOpChest_Materials" },
        [2] = { key = "GOLD", value = "BSK_UniqueOpChest_Gold" },
        [3] = { key = "GREATER_AFFIX", value = "BSK_UniqueOpChest_GreaterAffix" }
    },
}

return enums