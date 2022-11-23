//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//    ___  _           _
//   / __|| |_   __ _ | |_
//  | (__ | ' \ / _` ||  _|
//   \___||_||_|\__,_| \__|                  _      _
//   / __| ___  _ __   _ __   __ _  _ _   __| | ___(_)
//  | (__ / _ \| '  \ | '  \ / _` || ' \ / _` |(_-< _
//   \___|\___/|_|_|_||_|_|_|\__,_||_||_|\__,_|/__/(_)
//---------------------------------------------------
// Purpose: Enable commands through the chat box.
//---------------------------------------------------

// TODO:
// 1. Fix how we work out arguments for
//    players with spaces in their names
// 2. Implement vote CC

if (Config_UseChatCommands) {
    // This can only be enabled when the plugin is loaded fully
    if (PluginLoaded) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Adding chat callback for chat commands.")
        }
        AddChatCallback("ChatCommands")
    } else {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Can't add chat commands since no plugin is loaded!")
        }
        return
    }
} else {
    printl("(P2:MM): Config_UseChatCommands is false. Not adding chat callback for chat commands!")
    // If AddChatCallback() was called at one point during the session, the game will still check for chat callback even after map changes.
    // So, if someone doesn't want CC midgame, just redefine the function to do nothing.
    function ChatCommands(iUserIndex, rawText) {}
    return
}

// The whole filtering process for the chat commands
function ChatCommands(iUserIndex, rawText) {

    local Message = strip(RemoveDangerousChars(rawText))
    local Inputs = SplitBetween(Message, "!@", true)
    local AdminLevel = GetAdminLevel(UTIL_PlayerByIndex(iUserIndex))

    local Commands = []
    local Runners = []

    local GetCommandFromString = function(str) {
        foreach (cmd in CommandList) {
            if (StartsWith(str.tolower(), cmd.name)) {
                return cmd
            }
            if (StartsWith(str.tolower(), "playercolour")) {
                foreach (cmd in CommandList) {
                    if (cmd.name == "playercolor") {
                        return cmd
                    }
                }
            }
        }
        return null
    }

    //--------------------------------------------------

    // Be able to tell what is and isn't a chat command
    foreach (Input in Inputs) {
        if (!StartsWith(Input, "!") || Message.len() < 2) {
            return
        }
        if (Message.slice(0, 2) == "!!" || Message.slice(0, 2) == "! ") {
            return
        }
        if (Message.len() > 3) {
            if (Message.slice(0, 4) == "!SAR") {
                return // speedrun plugin events can interfere
            }
        }
        // The real chat command doesn't have the "!"
        Commands.push(Replace(Input, "!", ""))
    }

    // Register the activating player
    if (Runners.len() == 0) {
        Runners.push(UTIL_PlayerByIndex(iUserIndex))
    }

    foreach (Command in Commands) {
        // Split arguments
        Command = Strip(Command)

        local Args = SplitBetween(Command, " ", true)
        if (Args.len() > 0) {
            Args.remove(0)
        }

        Command = GetCommandFromString(Command)

        // Confirmed that it's a command, now try to run it
        foreach (CurPlayer in Runners) {
            // Does the exact command exist?
            if (Command == null) {
                return SendChatMessage("[ERROR] Command not found. Use !help to list some commands.", CurPlayer)
            }

            // Do we have the correct admin level for this command?
            if (!(Command.level <= AdminLevel)) {
                return SendChatMessage("[ERROR] You do not have permission to use this command.", CurPlayer)
            }

            RunChatCommand(Command, Args, CurPlayer)
        }
    }
}

//=======================================
// Import chat command content
//=======================================

CommandList <- []

// Include the scripts that will push each
// CC to the CommandList array

local IncludeScriptCC = function(script) {
    IncludeScript("multiplayermod/cc/" + script + ".nut")
}

IncludeScriptCC("adminmodify")
// IncludeScriptCC("ban") // INDEV By Orsell
IncludeScriptCC("changeteam")
IncludeScriptCC("help")
// IncludeScriptCC("kick") // INDEV By Orsell
IncludeScriptCC("kill")
IncludeScriptCC("mpcourse")
IncludeScriptCC("noclip")
IncludeScriptCC("playercolor")
IncludeScriptCC("rcon")
IncludeScriptCC("restartlevel")
IncludeScriptCC("rocket")
IncludeScriptCC("slap")
IncludeScriptCC("spchapter")
// IncludeScriptCC("spectate") // broken
IncludeScriptCC("speed")
IncludeScriptCC("teleport")
IncludeScriptCC("vote")

//--------------------------------------
// Chat command function dependencies
//
// Note: These aren't in functions.nut
// since there's no need to define them
// if the player chooses not to use CC
//--------------------------------------

function SendChatMessage(message, pActivatorAndCaller = null) {
    // Try to use server command in the case of dedicated servers
    local pEntity = Entities.FindByName(null, "p2mm_servercommand")
    if (pActivatorAndCaller != null) {
        // Send messages from a specific client
        pEntity = p2mm_clientcommand
    }
    EntFireByHandle(pEntity, "command", "say " + message, 0, pActivatorAndCaller, pActivatorAndCaller)
}

function RunChatCommand(cmd, args, plr) {
    printl("(P2:MM): Running chat command: " + cmd.name)
    printl("(P2:MM): Player: " + FindPlayerClass(plr).username)
    cmd.CC(plr, args)
}

function UTIL_PlayerByIndex(index) {
    for (local player; player = Entities.FindByClassname(player, "player");) {
        if (player.entindex() == index) {
            return player
        }
    }
    return null
}

function RemoveDangerousChars(str) {
    str = Replace(str, "%n", "") // Can cause crashes!
    if (StartsWith(str, "^")) {
        return ""
    }
    return str
}

function StrToList(str) {
    local list = []
    local i = 0
    while (i < Len(str)) {
        list.push( Slice(str, i, i + 1) )
        i = i + 1
    }
    return list
}

// preserve = true : means that the symbol at the beginning of the string will be included in the first part
function SplitBetween(str, keysymbols, preserve = false) {
    local keys = StrToList(keysymbols)
    local lst = StrToList(str)

    local contin = false
    foreach (key in keys) {
        if (Contains(str, key)) {
            contin = true
            break
        }
    }

    if (!contin) {
        return []
    }


    // FOUND SOMETHING

    local split = []
    local curslice = ""

    foreach (indx, letter in lst) {
        local contains = false
        foreach (key in keys) {
            if (letter == key) {
                contains = key
                if (indx == 0 && preserve) {
                    curslice = curslice + letter
                }
            }
        }

        if (contains != false) {
            if (Len(curslice) > 0 && indx > 0) {
                split.push(curslice)
                if (preserve) {
                    curslice = contains
                } else {
                    curslice = ""
                }
            }
        } else {
            curslice = curslice + letter
        }
    }

    if (Len(curslice) > 0) {
        split.push(curslice)
    }

    return split
}

function FindPlayerByName(name) {
    name = name.tolower()
    local best = null
    local bestnamelen = 99999
    local bestfullname = ""

    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        local username = FindPlayerClass(p).username
        username = username.tolower()

        if (username == name) {
            return p
        }

        if (Len(Replace(username, name, "")) < Len(username) && Len(Replace(username, name, "")) < bestnamelen) {
            best = p
            bestnamelen = Len(Replace(username, name, ""))
            bestfullname = username
        } else if (Len(Replace(username, name, "")) < Len(username) && Len(Replace(username, name, "")) == bestnamelen) {
            if (Find(username, name) < Find(bestfullname, name)) {
                best = p
                bestnamelen = Len(Replace(username, name, ""))
                bestfullname = username
            }
        }
    }
    return best
}

function GetAdminLevel(plr) {
    foreach (admin in Admins) {
        // Separate the SteamID and the admin level
        local level = split(admin, "[]")[0]
        local SteamID = split(admin, "]")[1]

        if (SteamID == FindPlayerClass(plr).steamid.tostring()) {
            if (SteamID == GetSteamID(1).tostring()) {
                // Host always has max perms even if defined lower
                if (level.tointeger() < 6) {
                    return 6
                }
                // In case we add more admin levels, return values defined higher than 6
                return level.tointeger()
            } else {
                // Use defined value for others
                return level.tointeger()
            }
        }
    }

    // For people who were not defined, check if it's the host
    if (FindPlayerClass(plr).steamid.tostring() == GetSteamID(1).tostring()) {
        // It is, so we automatically give the host max perms
        Admins.push("[6]" + FindPlayerClass(plr).steamid)
        SendChatMessage("Added max permissions for " + FindPlayerClass(plr).username + " as server operator.", plr)
        return 6
    } else {
        // Not in Admins array nor are they the host
        return 0
    }
}

function SetAdminLevel(NewLevel, iPlayerIndex) {
    if (iPlayerIndex == 1) {
        SendChatMessage("[ERROR] Cannot change admin level of server operator!")
        return
    }
    Admins.push("[" + NewLevel + "]" + FindPlayerClass(UTIL_PlayerByIndex(iPlayerIndex)).steamid)
    SendChatMessage("Set " + FindPlayerClass(UTIL_PlayerByIndex(iPlayerIndex)).username + "'s admin level to " + NewLevel + ".")
}