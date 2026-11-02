# Install-SoundBlasterSwitcher.ps1
# Installation de Sound Blaster Switcher

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$AppName = 'Sound Blaster Switcher'
$SourceDir = $PSScriptRoot
$InstallDir = Join-Path $env:ProgramFiles 'Sound Blaster Switcher'
$ExePath = Join-Path $InstallDir 'SoundBlasterSwitcher.exe'
$RunKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunValue = 'SoundBlasterSwitcher'

# Vérifier les droits administrateur
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`""
    )
    exit
}

try {
    # Vérifier les fichiers nécessaires
    $requiredFiles = @(
        'SoundBlasterSwitcher.exe',
        'sbz-switch.exe',
        'headphones.ico',
        'speakers.ico'
    )

    foreach ($file in $requiredFiles) {
        $path = Join-Path $SourceDir $file

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Fichier introuvable : $path"
        }
    }

    # Créer le dossier d'installation
    New-Item -Path $InstallDir -ItemType Directory -Force |
        Out-Null

    # Copier les fichiers
    foreach ($file in $requiredFiles) {
        Copy-Item `
            -LiteralPath (Join-Path $SourceDir $file) `
            -Destination (Join-Path $InstallDir $file) `
            -Force
    }

    # Ajouter le lancement automatique pour l'utilisateur courant
    if (-not (Test-Path $RunKey)) {
        New-Item -Path $RunKey -Force | Out-Null
    }

    Set-ItemProperty `
        -Path $RunKey `
        -Name $RunValue `
        -Value "`"$ExePath`""
    Start-Process -FilePath $ExePath

    [System.Windows.Forms.MessageBox]::Show(
        "Installation terminée.`r`n`r`n" +
        "Dossier : $InstallDir`r`n`r`n" +
        "Le programme sera lancé automatiquement à la prochaine ouverture de session.",
        $AppName,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

catch {
    Add-Type -AssemblyName System.Windows.Forms

    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Erreur d'installation - $AppName",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    exit 1
}