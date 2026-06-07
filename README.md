# ALAU

ALAU is a Godot 4.6 third-person 3D steppe runner about carrying an ancestral fire under the gaze of Ko'k Bo'ri. Place beacons behind you, keep the torch alive, draw families toward warmth, and decide when to become the final flame.

## Controls

- Turn / steer: A/D or Left/Right
- Move faster: W or Up
- Place beacon: E or Space, costs 1 wood + 1 flint + torch fuel
- Attack / defend: F
- Select weapon: 1-4 after finding weapons on the road
- Sacrifice: Q
- Restart after game over: Enter

## Current Build

The playable loop now uses a 3D third-person steppe path: automatic nomad travel, human-like body turning, torch fuel drain, beacon placement and fuel, wolf attacks, visible family rescue, live minimap trail, highscore saving, sacrifice, and an end screen trail map with Ko'k Bo'ri's consolation.

## Run

Open this folder in Godot 4.6.3 and run `res://scenes/game/main.tscn`.

From a terminal in this folder:

```powershell
..\Godot_v4.6.3-stable_win64_console.exe --path .
```

Packaged local build:

```powershell
builds\windows\Play_ALAU.bat
```

## Export

Use Godot's Export window with the included Windows Desktop or Web preset. Build outputs are intended for `builds/windows/ALAU.exe` and `builds/web/index.html`.
