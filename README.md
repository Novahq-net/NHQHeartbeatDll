# NovaHQ Heartbeat DLL for JOP / DFX / DFX2
Since 2001, [Novahq.net](https://novahq.net) has provided players with news, resources and forums for the Delta Force / Joint Operations series of games. Around 2015, Novahq.net created its own lobby system to provide a backup public lobby for DF1, DF2, LW, TFD and BHD. In 2017 Novahq.net expanded its list of games covered by the lobby to include: AF3, F16, F22, M29, L3, TTF, C4.

Now, after many years and a lot of research, NovaHQ is finally able to provide a public lobby for the remaining 3 games: Joint Operations, Delta Force Xtreme & Delta Force Xtreme 2. 

## NHQHeartbeat
A `dinput8.dll` proxy that adds custom lobby support and LAN mode (DFX/DFX2) to NovaLogic games:

- **Joint Operations: Combined Arms Gold** (V1.7.5.7, Retail and Steam)
- **Delta Force: Xtreme** (V1.6.9.3, Retail and Steam)
- **Delta Force: Xtreme 2** (V1.7.5.7, Retail and Steam)

> **Notice:** This project is intended for use with legitimately owned copies of the supported game(s) to enable continued online play through community-operated lobby servers. It is not intended to be used with illegally obtained copies of the game.

## What It Does
These games rely on **NovaWorld** for online play. NovaWorld no longer allows account creation so it's impossible for new players to play online. Players with accounts cannot even login to Delta Force Xtreme or Delta Force Xtreme 2 any longer as NovaWorld responds with an error along the lines of "The database you are attempting to use is currently not available. (Code NWNODB01)" error. This DLL proxies `dinput8.dll` to load alongside the game, intercepting and answering NWU protocol calls locally within the DLL itself, without needing to contact NovaWorld.

### 1. NWU Bypass
Intercepts the NovaWorld authentication flow (gate server handshake, NWU auth) and discards it, returning permissive responses so the game believes it authenticated successfully. The game will never connect to NovaWorld when the bypass is enabled. This removes the NovaWorld account requirement for hosting and playing online. Since Delta Force Xtreme and Delta Force Xtreme 2 no longer work online, enabling this is required for any type of online play. Joint Operation players with NovaWorld accounts do not need to enable this, but it must be enabled to play on any server outside of NovaWorld.

### 2. NovaHQ Lobby Heartbeat
When hosting, sends a periodic heartbeat to the NovaHQ lobby with server info such as: server name, map, game mode, player list, player count, etc. This allows the server to appear in the NovaHQ lobby allowing players to join. Works with or without the NWU bypass enabled and only sends the heartbeat while hosting, not while playing.

- **Player Validation:** When the heartbeat is enabled and an active hosting session is detected, NWU player validation will be disabled. The game originally calls home to NovaWorld for each connecting player, ensuring that the player is logged into NovaWorld. This removes that check and allows players that do not have an account the ability to join.

### 3. LAN Mode
Enables direct LAN play without any internet connection for DFX and DFX2 (JOP has native support). Players can host and join games over a local network using the LAN browser built into the game. The DLL handles all the network state management, button wiring, and validation bypasses needed for LAN discovery and joining to work. You must use the provided `mp.mnu` and `main.mnu` templates for LAN Mode to work.

## How It Works

The game automatically loads `dinput8.dll` at startup for DirectInput. By placing a proxy DLL with the same name in the game directory, it loads alongside the game and:

1. Loads the real `dinput8.dll` from the system directory (if needed) and forwards calls to the original dll. Input is unaffected.
2. Auto-detects the game version from the PE header (SizeOfImage) and loads the appropriate address/offset tables.
3. Hooks Winsock and IAT functions to intercept network traffic originally destined for NovaWorld. Replaces the internal functions with permissive responses.
4. Injects the NovaHQ Lobby URL into the gate server response, directing your game to load lobby information from NovaHQ.
5. While hosting, sends a periodic heartbeat packet (5-8kb via HTTP) and a single UDP packet (less than 1kb) every 30 seconds to the NovaHQ Lobby. The UDP packet enables the NovaHQ Lobby to determine your game server port when behind a NAT router.

> **Note:** Core gameplay, input, and rendering are unaffected. The DLL only intercepts lobby and authentication traffic, with optional crash guards that protect against known engine issues during map cycling. Your gameplay, latency, and client-server connections run exactly as they did before. If you are crashing in game, sending the last sysdump.txt and a description of the crash would help me determine the cause. 

## Installation

1. Copy `dinput8.dll` from this project into the game directory
2. Copy `NHQHeartbeat.ini` into the game directory and configure it
3. For LAN mode (DFX/DFX2): run `mnu/MOD_Install.bat` to install the custom menu files (`main.mnu`, `mp.mnu`) into the game's `localres.pff`. The installer will prompt you to select your game folder and uses the game's `pack.exe` to pack the menu files into the PFF archive. A backup of `localres.pff` is offered before any changes are made, but you should make your own backup anyways.

## Configuring (NHQHeartbeat.ini)

### `LobbyHost` *(default: nw10.novalobby.net)*
The lobby server hostname or IP. Do not include `http://` or `https://`. When BypassNWU or Heartbeat is enabled, this becomes the lobby server the game connects to instead of NovaWorld. The LobbyHost must have a web implementation that mimics the NovaWorld lobby for hosting and joining to work.

### `BypassNWU` *(default: 1)*
Bypasses the NWU authentication flow from the game, allowing you to host and play online without communicating with NovaWorld. This removes the NovaWorld account requirement but means you won't see servers on the official NovaWorld lobby unless those servers have the heartbeat enabled.

- **Hosts:** If you just want your server listed on the NovaHQ lobby, set `BypassNWU=0` and `Heartbeat=1`. Your game will still authenticate with NovaWorld as normal, but your server will also send a heartbeat to the NovaHQ lobby. Players can then join through the NovaHQ Lobby.
- **Players:** Enable this to connect through the NovaHQ lobby instead of NovaWorld. Without a NovaWorld account, this is required to play or host online.

### `Heartbeat` *(default: 1)*
When active and hosting, a periodic heartbeat is sent to the lobby server with your server's information, allowing it to be listed on the NovaHQ lobby. Other than your IP and port, no personal information is sent. The heartbeat only sends generic server information like server name, player names, player count, map, game mode, etc.

> When Heartbeat is enabled, NWU player validation is disabled making it possible for players that have not authenticated with NovaWorld to join your game. If you do not want alternate lobby players to join your lobby, you must disable the heartbeat.

### `AntiSysDump` *(default: 1)*
Enables crash guards that prevent known game engine sysdumps. Protects against crashes caused by corrupt GImage pointers, invalid material pointers during map cycling, and other rendering issues. Works with or without BypassNWU.

### `CacheFix` *(default: 1)*
Deletes the "cache" folder in the game directory on startup. The game uses this folder to store web lobby resources which can become stale and cause issues. Enabled by default to ensure a clean cache every launch.

### `MultiInstance` *(default: 0)*
When enabled, multiple instances of the game can be run simultaneously. Useful for testing or hosting multiple servers on the same machine. ***DOES NOT WORK WITH STEAM***

### `StaticHostVars` *(default: 0)*
Forces hosting variables (BaffleKey, PCIDKey, AppId) to static values instead of random. Useful for debugging when creating your own host/join flow. Unless you know what you are doing that, you should probably not enable this.

### `ServerKey` *(default: empty)*
A SHA1 hash you generate, included in the heartbeat as a unique identifier for your server to prevent impersonation. You can generate a SHA1 hash from any string using online tools. Must be a valid SHA1 hash or it will be rejected.

> **Note:** As of 2026/04/07, the custom lobby does not require or use this field, but it may be used in the future for stats tracking, server management, or other features that require a unique server identifier.

## Special thanks
I want to give a HUGE shoutout to biggy/taylorfinnell from the [OpenNova](https://github.com/opennova-net) project. Their knowledge of the game is surpassed by no-one, and their repo and projects were a huge help in making this possible.