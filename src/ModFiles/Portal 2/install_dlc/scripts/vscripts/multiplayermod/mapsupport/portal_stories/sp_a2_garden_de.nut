//  ██████╗██████╗             █████╗ ██████╗             ██████╗  █████╗ ██████╗ ██████╗ ███████╗███╗  ██╗           ██████╗ ███████╗
// ██╔════╝██╔══██╗           ██╔══██╗╚════██╗           ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗ ██║           ██╔══██╗██╔════╝
// ╚█████╗ ██████╔╝           ███████║  ███╔═╝           ██║  ██╗ ███████║██████╔╝██║  ██║█████╗  ██╔██╗██║           ██║  ██║█████╗
//  ╚═══██╗██╔═══╝            ██╔══██║██╔══╝             ██║  ╚██╗██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚████║           ██║  ██║██╔══╝
// ██████╔╝██║     ██████████╗██║  ██║███████╗██████████╗╚██████╔╝██║  ██║██║  ██║██████╔╝███████╗██║ ╚███║██████████╗██████╔╝███████╗
// ╚═════╝ ╚═╝     ╚═════════╝╚═╝  ╚═╝╚══════╝╚═════════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚══╝╚═════════╝╚═════╝ ╚══════╝

function MapSupport(MSInstantRun, MSLoop, MSPostPlayerSpawn, MSPostMapSpawn, MSOnPlayerJoin, MSOnDeath, MSOnRespawn) {
    if (MSInstantRun) {
        // Remove Portal Gun
        UTIL_Team.Spawn_PortalGun(false)

        // Enable pinging and disable taunting
        UTIL_Team.Pinging(true)
        UTIL_Team.Taunting(false)

        // delete box spawn
        Entities.FindByClassnameNearest("info_player_start", Vector(1648, 2552, 1828), 999).Destroy()
        playerpoint <- Entities.FindByClassname(null, "info_player_start")

        // Melgun Cutscene
        Entities.FindByName(null, "viewcontrol_melgun").Destroy()
        melgunC <- Entities.CreateByClassname("point_viewcontrol_multiplayer")
        melgunC.__KeyValueFromString("origin",  "2882.56 1667.98 97.4864")
        melgunC.__KeyValueFromString("wait", "10")
        melgunC.__KeyValueFromString("targetname", "viewcontrol_melgun")
        EntFire("viewcontrol_melgun", "SetParent", "melgun")
        melgunC.__KeyValueFromString("fov_rate", "1")
        melgunC.__KeyValueFromString("fov", "70")
        melgunC.__KeyValueFromString("deceleration", "500")
        melgunC.__KeyValueFromString("angles", "0 210 0")
        melgunC.__KeyValueFromString("acceleration", "500")
        melgunC.__KeyValueFromString("spawnflags", "140")
        EntFire("viewcontrol_melgun", "SetParentAttachment", "camera_attach")
        EntFire("relay_melgun", "AddOutput", "OnTrigger !self:RunScriptCode:playerdrawdisable()")
        EntFire("relay_melgun", "AddOutput", "OnTrigger melgun_glass:EnableDraw") // not sure why this breaks in mp. valv moment

        // prevent doors from closing        
        Entities.FindByName(null, "sleep_lab_real_door").__KeyValueFromString("targetname", "sleep_lab_real_dooroverride")
        Entities.FindByClassnameNearest("trigger_once", Vector(-2952, 5088, 144), 32).Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(-3520.16, 5104, 120), 32).Destroy()
        EntFire("AutoInstance1-office_door_button1", "AddOutput", "OnPressed sphere_ptex:TurnOn")
        Entities.FindByName(null, "ap_sleepy_room").__KeyValueFromString("targetname", "ap_sleepy_room_p2mmoverride")
        Entities.FindByName(null, "cs_virgil_1").__KeyValueFromString("targetname", "cs_virgil_1_p2mmoverride")

        // delay unlocking the vault levers to prevent a cosmetic bug when turning the power on and opening vault at the same time
        Entities.FindByName(null, "hatch_control_on_rl").__KeyValueFromString("targetname", "hatch_control_on_rl_p2mmoverride")
        EntFire("power_on_rl", "AddOutput", "OnTrigger hatch_control_on_rl_p2mmoverride:Trigger::2.1:-1")
        EntFire("vault_manager", "AddOutput", "OnChangeToAllTrue hatch_control_on_rl_p2mmoverride:Kill")

        // fixing a vanilla bug that allows a lever to be pressed again even after vault scene is triggered
        // also the parent gets cleared too fast so levers look weird in general when scene plays
        while (Entities.FindByName(null, "Lever_Model")) {
            Entities.FindByName(null, "Lever_Model").__KeyValueFromString("targetname", "Lever_Model_p2mmoverride")
        }
        EntFire("vault_manager", "AddOutput", "OnChangeToAllTrue Lever_Model_p2mmoverride:ClearParent::0.85")
        EntFire("vault_manager", "AddOutput", "OnChangeToAllTrue hatch_door1:Kill::0.9")
        EntFire("vault_manager", "AddOutput", "OnChangeToAllTrue hatch_door:Kill::0.9")

        // remove death fade
        Entities.FindByName(null, "AutoInstance1-fade2death1").Destroy()
        Entities.FindByName(null, "death_fade-fade_to_death").Destroy()

        // checkpoints
        EntFireByHandle(Entities.FindByClassnameNearest("trigger_once", Vector(1056, 2176, 36), 128), "AddOutput", "OnTrigger !self:RunScriptCode:Checkpoint(1)", 0, null, null)
        EntFire("vault_manager", "AddOutput", "OnChangeToAllTrue !self:RunScriptCode:Checkpoint(2)")
        EntFire("AutoInstance1-office_door_button2", "AddOutput", "OnPressed !self:RunScriptCode:Checkpoint(3)")

        Entities.FindByClassname(null, "info_player_start").SetOrigin(Vector(3800, 1880, -1000))
        // Make changing levels work
        EntFire("InstanceAuto2-exit_lift_train", "AddOutput", "OnStart end_fade:Fade::2", 0, null)
        if (GetMapName().find("sp_") != null) {
            EntFire("InstanceAuto2-exit_lift_train", "AddOutput", "OnStart p2mm_servercommand:Command:changelevel sp_a2_underbounce:3.5", 0, null)
        } else EntFire("InstanceAuto2-exit_lift_train", "AddOutput", "OnStart p2mm_servercommand:Command:changelevel st_a2_underbounce:3.5", 0, null)
        // exit elevator stuff
        Entities.FindByName(null, "end_command").Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(-6312, 4456, -312), 32).Destroy()

    }
    
    if (MSPostPlayerSpawn) {
        EntFire("cs_virgil_1_p2mmoverride", "Start")
        EntFire("blackin_p2mmoverride", "SetAnimation", "exit1")
    }

    if (MSLoop) {
        foreach (player in CreateTrigger("player", -10128, 1408, -840, -3472, 8064, -3400)) {
            if (player.GetClassname() == "player") {
                EntFireByHandle(player, "sethealth", "\"-10000\"", 0, null, null)
            }
        }
    }
}

function equipPortalGun() {
    Entities.FindByClassname(null, "trigger_weapon_strip").Destroy()
    UTIL_Team.Spawn_PortalGun(true)
    EntFireByHandle(melgunC, "TeleportToView", "", 0, null, null)
    EntFireByHandle(melgunC, "Disable", "", 0, null, null)
    // Force all players to receive portal gun
    GamePlayerEquip <- Entities.CreateByClassname("game_player_equip")
    GamePlayerEquip.__KeyValueFromString("weapon_portalgun", "1")
    for (local p = null; p = Entities.FindByClassname(p, "player");) {
        EntFireByHandle(GamePlayerEquip, "use", "", 0, p, p)
        EntFireByHandle(p, "enabledraw", "", 0, p, p)
        p.SetOrigin(Vector(2865.38, 1665.63, 35.03))
        p.SetAngles(0.62, -147.8, 0)
    }
    GamePlayerEquip.Destroy()
    // Enable secondary fire for all guns
    EntFire("weapon_portalgun", "AddOutput", "CanFirePortal2 1", 0, null)
}

function playerdrawdisable() {
    for (local p = null; p = Entities.FindByClassname(p, "player");) {
        EntFireByHandle(p, "disabledraw", "", 0, p, p)
    }
    EntFire("!self", "RunScriptCode", "equipPortalGun()", 13.2, null)
}

function Checkpoint(point) {
    switch(point) {
        case 1:
            Entities.FindByClassname(null, "info_player_start").SetOrigin(Vector(752, 2160, 77))
            Entities.FindByClassname(null, "info_player_start").SetAngles(0, 180, 0)
            return
        case 2:
            Entities.FindByClassname(null, "info_player_start").SetOrigin(Vector(-1040, 4192, 165))
            Entities.FindByClassname(null, "info_player_start").SetAngles(0, 180, 0)
            return
        case 3:
            Entities.FindByClassname(null, "info_player_start").SetOrigin(Vector(-3565, 5088, 93))
            Entities.FindByClassname(null, "info_player_start").SetAngles(0, 270, 0)
            return
    }
}
