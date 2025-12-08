# Scrcpy.Config — Audio bridge pour Android → PC 🔊➡️🖥️

Application PowerShell avec systray qui permet de router l’audio d’un appareil Android vers le PC via `scrcpy`, avec configuration dynamique et contrôle complet depuis l’icône système.

## Fonctionnalités principales
- **Bridge audio Android → PC** via scrcpy
- **Icône système (systray)** avec menu contextuel pour :
  - Démarrer/Arrêter le bridge
  - Choisir le mode USB ou IP (modifie la config et relance le bridge si besoin)
  - Ouvrir le dossier de configuration (`%APPDATA%\ScrcpyAudioBridge`)
  - Quitter l’application
- **Affichage du statut** (démarré/arrêté) dans le systray
- **Configuration dynamique** via le fichier `%APPDATA%\ScrcpyAudioBridge\scrcpy-config.json` (créé automatiquement si absent)
- **README local** dans le dossier de config pour documenter les options
- **Icône embarquée** (Base64, pas de dépendance à un fichier externe)

## Installation
- Installer `scrcpy` (préféré via `winget`) :

```powershell
winget install --exact Genymobile.scrcpy
```

- Compiler le script en exécutable (ouvre PowerShell en administrateur) :

```powershell
.\compile-tray.ps1
```

- Un exécutable `start-tray.exe` sera disponible : double-cliquez pour lancer le programme (ou exécutez `scrcpy-tray.ps1` directement).

## Utilisation
- L’icône système affiche le statut du bridge (démarré/arrêté)
- Menu contextuel pour démarrer/arrêter le bridge, changer le mode USB/IP, ouvrir le dossier de config, quitter
- Le fichier de config (`scrcpy-config.json`) permet de personnaliser le mode et l’IP
- Le README local (`scrcpy-config.README.md`) explique les options

## Notes rapides
- Pas besoin de fichier icône externe, tout est embarqué
- Si le programme ne se ferme pas correctement, exécutez le script `stop.bat` pour terminer le processus `scrcpy`

## Exemple de config
```json
{
    "mode": "usb"
}
```
```json
{
    "mode": "ip",
    "ip": "192.168.1.178:41393"
}
```