Add-Type -AssemblyName System.Windows.Forms

# Vérifie si scrcpy est déjà en cours d'exécution
$scrcpyRunning = Get-Process -Name "scrcpy" -ErrorAction SilentlyContinue
if ($scrcpyRunning) {
    [void][System.Windows.Forms.MessageBox]::Show("scrcpy est déjà en cours d'exécution.", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    [System.Windows.Forms.Application]::Exit()
    return
}

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("./icon32.ico")
$notifyIcon.Text = "Scrcpy (Audio)"
$notifyIcon.Visible = $true

# Démarre scrcpy en arrière-plan
$process = Start-Process "scrcpy" -ArgumentList "--no-window -w --audio-buffer=50" -PassThru -WindowStyle Hidden

# Crée un menu contextuel pour le clic droit
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$quitItem = $contextMenu.Items.Add("Fermer")
$quitItem.Add_Click({
    $process | Stop-Process -Force
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notifyIcon.ContextMenuStrip = $contextMenu

# Garde le script actif pour que l'icône reste visible
[System.Windows.Forms.Application]::Run()