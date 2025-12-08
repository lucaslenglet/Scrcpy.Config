Install-Module -Name PS2EXE -Force
Invoke-PS2EXE -inputFile "scrcpy-tray.ps1" -outputFile "start-tray.exe" -iconFile "icon_on32.ico" -noConsole
