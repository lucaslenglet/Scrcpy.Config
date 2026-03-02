# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Scrcpy.Config** is a .NET 10 WinForms system tray application that routes Android audio to a Windows PC via `scrcpy`. It is distributed as a global dotnet tool (`lucaslgt.ScrcpyConfig`). The UI is in French.

## Build Commands

```bash
# Restore and build
dotnet restore ./ScrcpyConfig.slnx
dotnet build ./ScrcpyConfig.slnx

# Run locally (from src/ScrcpyConfig/)
dotnet run

# Build via Cake (CI-style)
dotnet run --project cake.cs -- --target Build
dotnet run --project cake.cs -- --target PackAndPush  # requires NUGET_API_KEY, NUGET_SOURCE_URL
```

No test project exists in this solution.

## Architecture

The app uses a simple service-based pattern coordinated by `TrayApplication`.

**Entry point:** [Program.cs](src/ScrcpyConfig/Program.cs) — enables visual styles, launches `TrayApplication`.

**TrayApplication** ([TrayApplication.cs](src/ScrcpyConfig/TrayApplication.cs)) — inherits `ApplicationContext`, owns the `NotifyIcon` and `ContextMenuStrip`. It coordinates the three services and updates tray icon/status on state changes.

**ScrcpyService** ([Services/ScrcpyService.cs](src/ScrcpyConfig/Services/ScrcpyService.cs)) — manages the `scrcpy` process lifecycle. Builds CLI arguments for USB vs IP mode, detects an already-running scrcpy at startup, and kills the process tree on stop.
- USB args: `--no-window -w --audio-buffer=50 --select-usb`
- IP args: `--no-window -w --audio-buffer=50 --tcpip=+[IP]`

**ConfigService** ([Services/ConfigService.cs](src/ScrcpyConfig/Services/ConfigService.cs)) — reads/writes `%APPDATA%\ScrcpyAudioBridge\scrcpy-config.json`. Auto-creates the file and a local README on first run.

**LogService** ([Services/LogService.cs](src/ScrcpyConfig/Services/LogService.cs)) — appends timestamped lines to `scrcpy-tray.log` in the config directory.

**AppConfig** ([Models/AppConfig.cs](src/ScrcpyConfig/Models/AppConfig.cs)) — POCO with `Mode` ("usb"/"ip") and `Ip` (optional IP:port string).

## Key Conventions

- Versioning is managed by **Nerdbank.GitVersioning** (`version.json`). Do not manually edit version numbers.
- Icons are embedded .NET resources (`icon_on32.ico`, `icon_off32.ico`). No external icon files are needed at runtime.
- CI builds on PRs to `main`; NuGet publish is manual (`workflow_dispatch`).
- The solution uses the new `.slnx` format (`ScrcpyConfig.slnx`).
