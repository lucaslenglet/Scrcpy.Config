# Scrcpy.Config — Android Audio Bridge for Windows

A .NET 10 WinForms system tray application that routes audio from an Android device to a Windows PC via [`scrcpy`](https://github.com/Genymobile/scrcpy). Distributed as a global .NET tool (`lucaslgt.ScrcpyConfig`), it runs silently in the background and is fully controlled from the system tray icon — no terminal needed after installation.

> The application UI is in French.

## Table of Contents

- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration Reference](#configuration-reference)
- [Architecture Overview](#architecture-overview)
- [Local Development](#local-development)
- [Build System](#build-system)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Key Features

- **Android audio bridge** — streams Android audio output to Windows via `scrcpy` with low-latency buffering
- **System tray control** — start/stop the bridge and change modes without opening any window
- **USB and IP modes** — works over USB cable or over Wi-Fi (TCP/IP) with a configurable device IP address
- **Live status indicator** — tray icon switches between on/off states and the tooltip always shows current mode and status
- **Persistent configuration** — settings are saved to `%APPDATA%\ScrcpyAudioBridge\scrcpy-config.json` and survive restarts
- **Self-contained first run** — creates the config file and a local README automatically on first launch
- **Startup detection** — if `scrcpy` is already running when the app launches, it is adopted instead of launching a duplicate
- **Embedded icons** — no external icon files; both tray icons are compiled into the assembly as resources

---

## Tech Stack

| Component | Technology |
|---|---|
| Language | C# 13 |
| Framework | .NET 10 (Windows) |
| UI toolkit | WinForms (`System.Windows.Forms`) |
| Distribution | .NET global tool (`dotnet tool install -g`) |
| Versioning | Nerdbank.GitVersioning 3.9.50 |
| Build automation | Cake (C# scripting, `Cake.Sdk` 6.0.0) |
| CI/CD | GitHub Actions (windows-latest) |
| Package registry | NuGet.org |

---

## Prerequisites

Before installing or developing this project, you need:

1. **.NET 10 SDK or Runtime**
   - SDK required for development and `dotnet tool install`
   - Runtime alone is sufficient to run a pre-installed tool
   - Download: https://dotnet.microsoft.com/download/dotnet/10.0

2. **scrcpy** — the underlying Android mirroring tool that this application wraps
   ```powershell
   winget install --exact Genymobile.scrcpy
   ```
   After installation, verify `scrcpy` is on your `PATH`:
   ```powershell
   scrcpy --version
   ```

3. **Android device** with USB debugging enabled, connected via USB or reachable on the same Wi-Fi network

---

## Installation

### Install as a Global .NET Tool (recommended)

```powershell
dotnet tool install -g lucaslgt.ScrcpyConfig
```

This installs the `scrcpy-config` command globally. Launch it:

```powershell
scrcpy-config
```

The application starts silently — look for the new icon in your system tray.

### Update to the Latest Version

```powershell
dotnet tool update -g lucaslgt.ScrcpyConfig
```

### Uninstall

```powershell
dotnet tool uninstall -g lucaslgt.ScrcpyConfig
```

### Auto-start with Windows

To launch the bridge automatically when you log in, add a shortcut to the Windows startup folder:

1. Press `Win + R`, type `shell:startup`, press Enter
2. Create a shortcut pointing to `scrcpy-config` (or copy the `.exe` path from `%USERPROFILE%\.dotnet\tools\`)

---

## Usage

Once running, all control happens from the system tray icon (bottom-right of the taskbar).

### Tray Icon States

| Icon | Meaning |
|---|---|
| Active (lit) | Bridge is running — audio is being routed |
| Inactive (dim) | Bridge is stopped |

The tooltip always shows the current status and mode, e.g. `Scrcpy Audio Bridge (Activé : usb)`.

### Context Menu Items

Right-click the tray icon to access:

| Menu Item | Action |
|---|---|
| Status label (top) | Read-only display: `Activé : usb` or `Désactivé : ip`, etc. |
| **Démarrer le bridge** | Start the audio bridge with current config |
| **Arrêter le bridge** | Stop the audio bridge |
| **Mode USB** | Switch to USB mode (restarts bridge if running) |
| **Mode IP** | Switch to IP mode (restarts bridge if running) |
| **Ouvrir le dossier de config** | Opens `%APPDATA%\ScrcpyAudioBridge` in Explorer |
| **Ouvrir le fichier de log** | Opens `scrcpy-tray.log` in Notepad |
| **Quitter** | Stops the bridge and exits the application |

### Emergency Stop

If the application exits unexpectedly and `scrcpy` keeps running, use the included batch script:

```bat
stop.bat
```

This forcefully kills the `scrcpy.exe` process.

---

## Configuration Reference

The configuration file is created automatically at first launch:

```
%APPDATA%\ScrcpyAudioBridge\scrcpy-config.json
```

A human-readable explanation is also written to:

```
%APPDATA%\ScrcpyAudioBridge\scrcpy-config.README.md
```

### Config Schema

```json
{
    "mode": "usb",
    "ip": null
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `mode` | `string` | Yes | Connection mode: `"usb"` or `"ip"` |
| `ip` | `string` or `null` | No (required for IP mode) | Device IP address and port, e.g. `"192.168.1.178:41393"` |

### Example Configurations

**USB mode** (device connected via cable):
```json
{
    "mode": "usb"
}
```

**IP mode** (device on Wi-Fi):
```json
{
    "mode": "ip",
    "ip": "192.168.1.178:41393"
}
```

> When you switch to IP mode via the context menu for the first time and no IP is configured, the app fills in the placeholder `192.168.1.178:41393`. Edit the config file with the correct address for your device.

### Underlying scrcpy Arguments

The application builds the following CLI arguments depending on mode:

| Mode | Command |
|---|---|
| USB | `scrcpy --no-window -w --audio-buffer=50 --select-usb` |
| IP | `scrcpy --no-window -w --audio-buffer=50 --tcpip=+<ip>` |

- `--no-window` — suppresses the screen mirror window (audio only)
- `-w` — prevents the device screen from waking up
- `--audio-buffer=50` — sets a 50 ms audio buffer for low-latency output
- `--select-usb` — explicitly targets a USB-connected device
- `--tcpip=+<ip>` — connects to a device at the given IP:port over TCP/IP

---

## Architecture Overview

```
Program.cs
└── TrayApplication (ApplicationContext)
    ├── NotifyIcon + ContextMenuStrip   ← tray UI
    ├── ConfigService                   ← reads/writes config JSON
    ├── ScrcpyService                   ← manages scrcpy process
    └── LogService                      ← appends to log file
```

### Component Details

#### `TrayApplication` (`TrayApplication.cs`)

The central coordinator. Extends `ApplicationContext` (WinForms equivalent of a main window for tray apps). Responsibilities:

- Builds and owns the `NotifyIcon` and `ContextMenuStrip`
- Wires up all menu item click handlers
- Delegates to services for all logic
- Calls `UpdateTrayStatus()` after any state change to refresh icon and tooltip
- On startup, calls `ScrcpyService.DetectRunning()` to adopt an already-running process

#### `ScrcpyService` (`Services/ScrcpyService.cs`)

Manages the `scrcpy` child process. Key behaviors:

- `IsRunning` — checks both the tracked `Process` object and `Process.GetProcessesByName("scrcpy")` so it stays accurate even for externally started instances
- `DetectRunning()` — called once at startup; if `scrcpy` is already running, stores a reference to avoid starting a duplicate
- `Start(mode, ip)` — builds the argument string and starts `scrcpy` as a hidden process; fires a background `await WaitForExitAsync()` to update status when it exits naturally
- `Stop()` — kills the process tree (`entireProcessTree: true`) to ensure all child processes are terminated

#### `ConfigService` (`Services/ConfigService.cs`)

Handles all file I/O for configuration. On construction, it:

1. Ensures `%APPDATA%\ScrcpyAudioBridge\` exists
2. Creates `scrcpy-config.json` with `{ "mode": "usb" }` if absent
3. Creates `scrcpy-config.README.md` with inline documentation if absent

`GetConfig()` reads and deserializes the JSON file on every call (no caching), so edits to the file are picked up immediately on the next action.

#### `LogService` (`Services/LogService.cs`)

Minimal append-only logger. Writes timestamped lines to `scrcpy-tray.log`:

```
[2026-05-01 14:32:00] Lancement de l'application...
[2026-05-01 14:32:00] Application démarrée.
[2026-05-01 14:32:05] Bridge démarré avec les arguments: --no-window -w --audio-buffer=50 --select-usb
```

#### `AppConfig` (`Models/AppConfig.cs`)

Plain data object (POCO) with two properties: `Mode` (string, defaults to `"usb"`) and `Ip` (nullable string).

### Directory Layout

```
Scrcpy.Config/
├── src/
│   └── ScrcpyConfig/
│       ├── Models/
│       │   └── AppConfig.cs          # Config data model
│       ├── Services/
│       │   ├── ConfigService.cs      # Config file I/O
│       │   ├── LogService.cs         # Append-only logger
│       │   └── ScrcpyService.cs      # scrcpy process manager
│       ├── Resources/
│       │   ├── icon_on32.ico         # Tray icon: bridge active
│       │   └── icon_off32.ico        # Tray icon: bridge stopped
│       ├── Program.cs                # Entry point
│       ├── TrayApplication.cs        # Main coordinator
│       └── ScrcpyConfig.csproj
├── .github/
│   └── workflows/
│       ├── build.yml                 # PR build check
│       └── publish.yml               # Manual NuGet publish
├── cake.cs                           # Cake build script
├── Directory.Build.props             # Nerdbank.GitVersioning NuGet ref
├── global.json                       # Pins .NET SDK to 10.0.101
├── ScrcpyConfig.slnx                 # Solution file (new .slnx format)
├── stop.bat                          # Emergency kill script
└── version.json                      # Nerdbank.GitVersioning config
```

---

## Local Development

### 1. Clone the repository

```powershell
git clone https://github.com/lucaslenglet/Scrcpy.Config.git
cd Scrcpy.Config
```

### 2. Verify prerequisites

```powershell
dotnet --version   # Should show 10.x.x
scrcpy --version   # Should show scrcpy version
```

### 3. Restore dependencies

```powershell
dotnet restore ./ScrcpyConfig.slnx
```

### 4. Build the solution

```powershell
dotnet build ./ScrcpyConfig.slnx
```

### 5. Run locally

```powershell
dotnet run --project src/ScrcpyConfig/
```

The application starts in the system tray. To stop it, right-click the tray icon and choose **Quitter**.

### IDE Setup

Open `ScrcpyConfig.slnx` in Visual Studio 2022 (17.12+) or JetBrains Rider (2024.3+). Both support the `.slnx` solution format natively. Press F5 to run with the debugger attached.

> Note: Because the app is a `WinExe` with no visible window, debug output appears in the Output panel. Set breakpoints in service methods to inspect behavior.

---

## Build System

This project uses [Cake](https://cakebuild.net/) via the C# scripting runner (`Cake.Sdk`). The build file is `cake.cs` at the repository root.

### Available Targets

| Target | Command | Description |
|---|---|---|
| `Build` (default) | `dotnet run --project cake.cs` | Restore + build in Release |
| `Build` (Debug) | `dotnet run --project cake.cs -- --configuration Debug` | Build in Debug configuration |
| `PackAndPush` | `dotnet run --project cake.cs -- --target PackAndPush` | Pack NuGet and push to registry |

### PackAndPush Requirements

The `PackAndPush` target requires two environment variables:

| Variable | Description |
|---|---|
| `NUGET_API_KEY` | API key for the target NuGet source |
| `NUGET_SOURCE_URL` | Full URL of the NuGet push endpoint |

Set them before running:

```powershell
$env:NUGET_API_KEY = "your-api-key"
$env:NUGET_SOURCE_URL = "https://api.nuget.org/v3/index.json"
dotnet run --project cake.cs -- --target PackAndPush
```

Packed `.nupkg` files are staged to `./stg/` before being pushed.

### Versioning

Versioning is fully managed by **Nerdbank.GitVersioning**. The base version is defined in `version.json` as `0.1`. The full version (e.g. `0.1.42`) is derived from the git commit height automatically. **Do not manually edit version numbers** — they are computed at build time.

- Versions are only stamped as public releases on commits to the `main` branch (`publicReleaseRefSpec` in `version.json`)
- Cloud build number injection is enabled for CI environments

---

## CI/CD Pipeline

### Build Workflow (`.github/workflows/build.yml`)

**Trigger:** Pull requests targeting `main` that modify files under `src/`, `cake.cs`, or `ScrcpyConfig.slnx`

**Steps:**
1. Checkout with full history (`fetch-depth: 0`) so Nerdbank.GitVersioning can compute the version from commit depth
2. Run `cake.cs` with the `Build` target on `windows-latest`

This serves as the PR gate — merges are blocked until the build passes.

### Publish Workflow (`.github/workflows/publish.yml`)

**Trigger:** Manual (`workflow_dispatch`) — no automatic publishing

**Steps:**
1. Checkout with full history
2. Run `cake.cs` with the `PackAndPush` target, injecting `NUGET_API_KEY` and `NUGET_SOURCE_URL` from repository secrets

**Required secrets** (configured in GitHub repository settings):

| Secret | Description |
|---|---|
| `NUGET_API_KEY` | NuGet.org API key with push permission |
| `NUGET_SOURCE_URL` | NuGet push URL (e.g. `https://api.nuget.org/v3/index.json`) |

To publish a new version:
1. Merge changes into `main`
2. Go to **Actions** > **Publish** > **Run workflow**

---

## Troubleshooting

### The tray icon does not appear

- Check Task Manager for `scrcpy-config.exe` — the process may be running but the icon is hidden in the overflow tray. Click the `^` arrow in the taskbar notification area.
- If the process is not there, run `scrcpy-config` from a terminal to see any startup errors.

### "Le bridge est deja actif" when trying to start

The app detected `scrcpy` is already running (either managed by the app or started externally). Stop the bridge first via the context menu, then start it again.

### scrcpy fails to connect in USB mode

- Ensure USB debugging is enabled on the Android device (Settings > Developer Options > USB Debugging)
- Run `adb devices` to verify the device is listed and authorized
- Try unplugging and replugging the USB cable

### scrcpy fails to connect in IP mode

- Ensure both the PC and Android device are on the same Wi-Fi network
- Verify the IP address in the config file matches the device's current IP (`adb shell ip addr show wlan0`)
- To find the correct TCP port, enable Wireless Debugging on the device (Android 11+) or run `adb tcpip 5555` then `adb connect <device-ip>:5555`

### Audio is not routed to the PC

- Ensure the Android device is not muted
- Check that no other application (e.g. a separate `scrcpy` instance) is holding the audio device
- Try stopping and restarting the bridge from the tray menu

### scrcpy keeps running after the app closes

Use the emergency stop script:

```bat
stop.bat
```

Or kill it manually:

```powershell
taskkill /f /im scrcpy.exe
```

### Config file is corrupted or missing

Delete `%APPDATA%\ScrcpyAudioBridge\scrcpy-config.json` — the application recreates it with the default USB configuration on next launch.

### Build fails: "SDK version not found"

Ensure you have the SDK version pinned in `global.json` installed:

```powershell
dotnet --list-sdks
```

Download .NET 10.0.101 from https://dotnet.microsoft.com/download/dotnet/10.0 if it is not listed.

---

## Contributing

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes — UI strings are in French, keep them consistent
4. Open a Pull Request targeting `main` — the build CI runs automatically
5. A maintainer reviews and merges

There is no test project. Manual testing consists of running the application locally with a connected Android device.

---

## License

See the repository for license information: https://github.com/lucaslenglet/Scrcpy.Config
