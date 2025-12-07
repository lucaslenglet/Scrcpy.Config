Install-Module -Name PS2EXE -Force
Invoke-PS2EXE -inputFile "start.ps1" -outputFile "start.exe" -iconFile "icon32.ico" -noConsole
