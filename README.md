# NovaHQ Heartbeat DLL for JOP / DFX / DFX2
Since 2001, [Novahq.net](https://novahq.net) has provided players with news, resources and forums for the Delta Force / Joint Operations series of games. Around 2015, Novahq.net created its own lobby system to provide a backup public lobby for DF1, DF2, LW, TFD and BHD.  

In 2017 Novahq.net expanded its list of games covered by the lobby to include: `Armored Fist 3`, `Comanche 3 Gold`, `Comanche 4`, `F-16 Multirole Fighter`, `F-22 Raptor`, `MiG-29 Fulcrum`, `F-22 Lightning 3` and `Tachyon: The Fringe`. 

Now, after many years and a lot of research, Novahq.net is finally able to provide a public lobby for the remaining three games: `Joint Operations`, `Delta Force Xtreme` & `Delta Force Xtreme 2`. 

## Supported games

> **Notice:** This project is intended for use with legitimately owned copies of the supported game(s) to enable continued online play through community-operated lobby servers. It is not intended to be used with illegally obtained copies of the game.

> **Note:** For maximum compatibility, it's recommended to use this DLL with the **stock, unmodified exe** distributed with the game or mod.

The proxy dll has been built and tested against the game versions and distributions listed below. Patched or cracked executables are not supported, and support for them will not be added. There are plenty of legitimate ways to obtain a retail or digital copy. 

- **Joint Operations: Typhoon Rising** (V1.6.9.2, Retail CDROM, Compatible with Advanced Warfare 2)
- **Joint Operations: Typhoon Rising** (V1.7.1.9, Retail CDROM, Compatible with Advanced Warfare 2)
- **Joint Operations: Typhoon Rising w/ Escalation Expansion Pack** (V1.7.5.7, Retail CDROM)
- **Joint Operations: Combined Arms Gold** (V1.7.5.7, Retail CDROM, NovaLogic Digital and Steam)
- **Delta Force: Xtreme** (V1.6.9.3, Retail CDROM, NovaLogic Digital, GOG and Steam)
- **Delta Force: Xtreme** (V1.7.1.9, NovaLogic Digital Patch)
- **Delta Force: Xtreme 2** (V1.7.5.7, Retail CDROM, NovaLogic Digital and Steam)

## What It Does

These games rely on **NovaWorld** for online play. NovaWorld no longer allows account creation, so it's impossible for new players to play online. Players with accounts cannot even log in to Delta Force Xtreme or Delta Force Xtreme 2 any longer as NovaWorld responds with an error along the lines of "The database you are attempting to use is currently not available. (Code NWNODB01)". This project is a `dinput8.dll` proxy that loads alongside the game, intercepting and answering NWU protocol calls locally within the DLL itself to add custom lobby support and LAN mode (DFX/DFX2) without needing to contact NovaWorld.

### 1. NWU Bypass
Intercepts the NovaWorld authentication flow (gate server handshake, NWU auth) and discards it, returning permissive responses so the game believes it authenticated successfully. The game never connects to NovaWorld while the bypass runs, so no NovaWorld account is needed to host or play online.

### 2. NovaHQ Lobby Heartbeat
When hosting, sends a periodic heartbeat to the NovaHQ lobby with server info such as server name, map, game mode, player list, player count, etc. This allows the server to appear in the NovaHQ lobby allowing players to join. Works with both lobbies and only sends the heartbeat while hosting, not while playing. A server hosted from **NovaWorld** is listed on both lobbies.

- **Player Validation:** When an active hosting session is detected, NWU player validation will be disabled. The game originally calls home to NovaWorld for each connecting player, ensuring that the player is logged into NovaWorld. This removes that check and allows players who do not have an account to join.

### 3. LAN Mode (DFX/DFX2 Only)
Enables direct LAN play without any internet connection for DFX and DFX2 (JOP already has native support). Players can host and join games over a local network using the LAN browser built into the game. The DLL handles all the network state management, button wiring, and validation bypasses needed for LAN discovery and joining to work. You must use the provided `mp.mnu` and `main.mnu` templates for LAN Mode to work.

> **Do not install the LAN Mode files AFTER installing a MOD.** 

### 4. Networking Improvements
When hosting, and `SendRate` is set to 32, 64 or 125 the game will send updates to your players more often, so movement, events and AI behavior look smoother. Players do not need to change anything and will automatically benefit from the increased update rate if the host has it enabled. The recommended setting is 64Hz for most hosts, balancing smooth gameplay with reasonable bandwidth usage for cross-region play. 

The DLL also attempts to recover clients that fall behind after lag spikes or packet loss. Lost packets can carry shots, reloads, kills and respawns, so the DLL attempts to recover them instead of discarding them. It also requests twice as many lost packets at once, and fixes a stock bug that could leave a client stuck behind the server with a frozen game world. This helps high ping players stay synchronized with the host for smoother gameplay.

### 5. Large PFF Archives
The stock game cannot read a `.pff` archive larger than 2 GB. The DLL lets every supported game read archives up to 4 GB, the largest size the archive format can address.

### 6. More Game Memory (Heap / Fastmem)
The game reserves one fixed block of memory at startup, which it calls Fastmem: 192 MB in the V1.7.5.7 games and 136 MB in the older ones. A mission that nearly fills this block fails to load with "Mission is too large". The DLL sets the block to 256 MB in every supported game, so heavy mods and large missions have room to spare.

Tests with every mod, with various configurations and mission sizes, never went past the stock size, and only extreme cases came close. The DLL stops at 256 MB because the whole block comes out of the 2 GB of memory the game can use, and graphics, sound and mission objects need the rest. No test needed LAA (Large Address Aware).

### 7. Larger Mission Support
The stock game caps each mission at 256 organics (players and AI), 1,200 items, 1,200 decorations and 768 markers. After several months of hosting and sysdump analysis, the majority of my server crashes came from exceeding the organic limit. There are many missions that push the organic limit close to it's maximum and don't leave enough room for actual players to join. If a player joins a mission with no available player slots, they will crash the host simply by joining. The DLL solves the organic limit issue by raising it to 2,048 and places players first in the allocation, so player slots filled before AI slots. The item, decoration and marker limits are increased to 2,400 items, 2,400 decorations and 2,048 markers. 

> **Note:** The increased mission limits are always on and cannot be disabled. Players need the updated DLL to join servers running missions that **exceed the stock limits**. However, missions that stay within the stock limits **will still work for all players, even for vanilla clients without the DLL.** The NovaHQ Lobby will show a message to clients attempting to join servers that exceed the stock limits if they do not have the updated DLL.

## How It Works

The game automatically loads `dinput8.dll` at startup for DirectInput. By placing a proxy DLL with the same name in the game directory, it loads alongside the game and:

1. Loads the real `dinput8.dll` from the system directory (if needed) and forwards calls to the original dll. Input is unaffected.
2. Auto-detects the game version from the PE header (SizeOfImage) and loads the appropriate address/offset tables.
3. Hooks Winsock and IAT functions to intercept network traffic originally destined for NovaWorld. Replaces the internal functions with permissive responses.
4. Injects the NovaHQ Lobby URL into the gate server response, directing your game to load lobby information from NovaHQ.
5. While hosting, sends a periodic heartbeat packet and a single UDP packet every 30 seconds to the NovaHQ Lobby. The UDP packet enables the NovaHQ Lobby to determine your game server port when behind a NAT router.

> **Note:** Core gameplay, input, and rendering are unaffected. The DLL intercepts lobby and authentication traffic, adds optional crash guards that protect against known engine issues during map cycling, and changes how the game sends and recovers network packets (see Networking Improvements). If you are crashing in game, sending the last sysdump.txt and a description of the crash would help me determine the cause.

## Installation

> **Note:** If your game is installed in `Program Files (x86)`, consider reinstalling it to your home directory or another drive (e.g. `C:\Users\<YOUR_USERNAME>\Games\Joint Operations` or `D:\Games\Joint Operations`). There is no need to run these older games with admin privileges when they are installed in a folder where you already have write access. I will not troubleshoot issues caused by a `Program Files` install - it is the root cause of 99% of user issues with these games.

1. Download from the GitHub releases page (to the right) or find it on [Novahq.net](https://novahq.net) in the downloads section.
2. Copy `dinput8.dll` from this project into the game directory
3. Copy `NHQHeartbeat.ini` into the game directory. The default config will cover 99% of users.
4. ***Optional:*** For LAN mode (DFX/DFX2): run `lanmode/MOD_Install.bat` to install the custom menu files (`main.mnu`, `mp.mnu`) into the game's `localres.pff`. The installer will prompt you to select your game folder and uses the game's `pack.exe` to pack the menu files into the PFF archive. A backup of `localres.pff` is offered before any changes are made, but you should make your own backup.

## Configuring (NHQHeartbeat.ini)

### `LobbyHost` *(default: nw10.novalobby.net)*
The lobby server hostname or IP address. This is the lobby server the game connects to instead of NovaWorld: always in DFX and DFX2, and in JO when you pick NOVAHQ on the main menu. The heartbeat is sent to it as well. The LobbyHost must have a web implementation that mimics the NovaWorld lobby for hosting and joining to work.

### `RequireAuth` *(default: 0)*
When enabled, the lobby requires players to sign in to NovaHQ before they can join your server. Players using the lobby as a guest cannot join. Signed-in players keep the same PCID and character name across sessions, while a guest is identified by IP address, so this makes PCID bans reliable. Not recommended unless you have a player identification problem.

### `ServerStats` *(default: 1)*
When enabled and hosting, one extra heartbeat is sent at the end of each round with per-player stats: kills, deaths, weapons, vehicles and various other in-game actions that occurred during the round. The lobby matches the stats to your server by `ServerKey`. Set this to 0 if you do not want stats from your server recorded. Your server stays listed either way. You can view servers stats
at [https://novahq.net/stats](https://novahq.net/stats).

### `ServerKey` *(default: randomly generated)*
A unique key sent with every heartbeat to identify your server to the lobby. It is generated on first launch and saved to the ini. You may replace it with a server key of your own. Unless it is already 40 hex characters, it is hashed before it is sent, so the text you type never leaves the ini.

> **Note:** The lobby uses this key to match your server to its stats. Servers sending the same key are grouped as one server, so give each server you run its own key. Remember the key if you move or reinstall the game, or the lobby will treat your server as a new one.

### `SaveStats` *(default: 0)*
When enabled with ServerStats, the final stats of each round are also saved as a JSON file in the `NHQStats` folder inside the game folder. Each file is named by the date, the time and the round id, such as `2026-10-01-215700-5e1b1a7e5b20d4c8.json`. 

### `SendRate` *(default: 64)*
When hosting, raises the network send rate to 32, 64 or 125 (see Networking Improvements). Any other value keeps the game's rate.

### `NetworkFixes` *(default: 1)*
Turns the networking improvements on or off (see Networking Improvements). Set to 0 to turn all network fixes off. This setting overrides SendRate.

### `MultiInstance` *(default: 0)*
When enabled, multiple instances of the game can be run simultaneously. Useful for testing or hosting multiple servers on the same machine. ***DOES NOT WORK WITH STEAM*** Steam users should use the `/serveonly` switch instead.

### `AntiSysDump` *(default: 1)*
Enables crash guards that prevent known game engine sysdumps. Protects against crashes caused by corrupt GImage pointers, invalid material pointers during map cycling, and other rendering issues.

### `CacheFix` *(default: 1)*
Deletes the "cache" folder in the game directory on startup. The game uses this folder to store web lobby resources which can become stale and cause issues.

### `StaticHostVars` *(default: 0)*
Forces hosting variables (BaffleKey, PCIDKey, AppId) to static values instead of random. Useful for debugging when creating your own host/join flow. You should probably not enable this.

## Special thanks

I want to give a HUGE shoutout to biggy/taylorfinnell from the [OpenNova](https://github.com/opennova-net) project. Their knowledge of the game is surpassed by no-one, and their repo and projects were a huge help in making this possible. I also want to thank [BadgerLove](https://github.com/BadgerLove) for their contributions to the games and community with several patches that improved stability, networking, and overall gameplay experience.
