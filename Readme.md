# Scrcpy.Config — Audio bridge pour Android → PC 🔊➡️🖥️

Script PowerShell qui récupère le son de votre appareil Android et le redirige vers la sortie audio du PC via `scrcpy`. Simple, discret (sans console) et pilotable depuis une icône dans la zone de notification.

## Comment ça marche ?
- `start.ps1` :
  - Vérifie si `scrcpy` est déjà lancé ; si oui, affiche une alerte et arrête pour éviter les doublons.
  - Démarre `scrcpy` en arrière-plan avec les options `--no-window -w --audio-buffer=50` pour activer la capture audio tout en gardant une fenêtre invisible.
  - Crée une icône dans la zone de notification (`icon32.ico`) et ajoute un menu contextuel « Fermer » qui arrête proprement le process `scrcpy` et ferme l'application.
  - Garde le script actif via l'API Windows Forms (`[System.Windows.Forms.Application]::Run()`), ce qui permet d'avoir l'icône toujours présente tant que `scrcpy` tourne.
- `compile.ps1` :
  - Installe (si besoin) le module `PS2EXE` et appelle `Invoke-PS2EXE` pour transformer `start.ps1` en `start.exe` sans console et avec l'icône embarquée.

## Comment l'installer ?
- Installer `scrcpy` (préféré via `winget`) :

```powershell
winget install --exact Genymobile.scrcpy
```

- Compiler le script en exécutable (ouvre PowerShell en administrateur) :

```powershell
.\compile.ps1
```

- Un exécutable `start.exe` sera disponible : double-cliquez pour lancer le programme (ou exécutez `start.ps1` directement).

Notes rapides :
- Assurez-vous que `icon32.ico` est présent dans le même dossier.
- Si `start.exe` ne se génère pas, exécutez `compile.ps1` en administrateur (l'installation des modules via `Install-Module` peut nécessiter des permissions).
- Si le programme ne se ferme pas correctement, exécutez le script `stop.bat` pour terminer le processus `scrcpy`.