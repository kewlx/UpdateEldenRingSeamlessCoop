function Update-EldenRingSeamlessCoop {
    <#
    .SYNOPSIS
        Update the Elden Ring Seamless Coop exe and related files. You should choose a password to use otherwise it will 
        give you a random one and you have to change it later to match your friends.
    .DESCRIPTION
        Download the latest files and extract them. Remove the older files and change default password for multiplayer.
        Dynamically find the steam folder and copy the new files over.
        Checks co2 files and will make one if one doesn't exist. If it exists it does nothing to them. Removes downloaded files.
    .NOTES
        This script will not save your settings file and if you do not choose a password it will choose one for you.
    .LINK
        https://github.com/LukeYui/EldenRingSeamlessCoopRelease
    .EXAMPLE
        Update-EldenRingSeamlessCoop
    .EXAMPLE
        Update-EldenRingSeamlessCoop -Password "ExamplePasswordHere"
    .EXAMPLE
        Update-EldenRingSeamlessCoop -Password "ExamplePasswordHere" -WhatIf
    .EXAMPLE
        Update-EldenRingSeamlessCoop -Password "ExamplePasswordHere" -Verbose
    .EXAMPLE
        Update-EldenRingSeamlessCoop -Password "ExamplePasswordHere" -Verbose -WhatIf
    #>    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty]
        [string]$Password = (-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
    )
    
    begin {
        try {
            Write-Verbose -Message "Building Variables..."
            $latest = (Invoke-RestMethod -Uri "https://api.github.com/repos/LukeYui/EldenRingSeamlessCoopRelease/releases/latest").assets.browser_download_url
            $steamLocation = Split-Path -Path (Get-ItemProperty -Path "HKCU:\SOFTWARE\Valve\Steam").SteamExe -Parent
            $eldenRingLocation = "$steamLocation\steamapps\common\ELDEN RING\Game"
            $download = "$home\downloads\$(Split-Path -Path $latest -Leaf)"   
        }
        catch {
            $pscmdlet.throwterminatingerror($psitem)
        }
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("$latest", "Download")) {
                Start-BitsTransfer -Source $latest -Destination $download
            }
    
            if ($PSCmdlet.ShouldProcess("$download", "Extract")) {
                Expand-Archive -Path $download -DestinationPath "$home\downloads\EldenRing"
            }
    
            Write-Verbose -Message "Removing older files in $eldenRingLocation..."
            $newFiles = Get-ChildItem -Path "$home\downloads\EldenRing" -Recurse
    
            foreach ($newFile in $newFiles) {
                if (Test-Path -Path "$eldenRingLocation\$($newFile.name)") {
                    Remove-Item -Path "$eldenRingLocation\$($newFile.name)" -Recurse
                }
            }
    
            if ($PSCmdlet.ShouldProcess("seamlesscoopsettings.ini", "Setting default password")) {
                if (Test-Path -Path "$home\downloads\EldenRing\SeamlessCoop\seamlesscoopsettings.ini") {
                    (Get-Content -Path "$home\downloads\EldenRing\SeamlessCoop\seamlesscoopsettings.ini") -replace "cooppassword =", "cooppassword = $Password" | 
                    Set-Content -Path "$home\downloads\EldenRing\SeamlessCoop\seamlesscoopsettings.ini"
                }
                else {
                    Write-Warning -Message "Could not find $home\downloads\EldenRing\SeamlessCoop\seamlesscoopsettings.ini."
                }    
            }
    
            if ($PSCmdlet.ShouldProcess("$eldenRingLocation\", "Copying")) {
                if ($false -in (Test-Path -Path $eldenRingLocation,"$home\downloads\EldenRing")) {
                    Write-Warning -Message "Could not find $eldenRingLocation or "$home\downloads\EldenRing""
                }
                else {
                    Get-ChildItem -Path "$home\downloads\EldenRing" | Copy-Item -Destination "$eldenRingLocation\" -Recurse -Container
                }
            }
        
            Write-Verbose -Message "Checking for .co2 file..."
            if (Test-Path -Path "$env:APPDATA\EldenRing") {
        
                # Gathering files from Elden Ring roaming folder for character files
                $roamingFiles = Get-ChildItem -Path "$env:APPDATA\EldenRing\*" -Exclude "GraphicsConfig.xml", "*.bak", "*.vdf" -Recurse
    
                foreach ($file in $roamingFiles | Where-Object { $PSItem.Name -match "sl2" }) {
                    if (!(Test-Path -Path "$($file.Directory)\$($file.BaseName).co2" )) {
                        Write-Verbose -Message "Creating .co2 file from $($file.name)..." -Verbose
                        Copy-Item -Path $file.FullName -Destination "$($file.Directory)\$($file.BaseName).co2"
                    }
                }
    
            }
            else {
                Write-Warning -Message "Cannot create .co2 file. File location $env:APPDATA\EldenRing doesn't exist. Game/character may not have been started yet."
            }

            Write-Verbose -Message "Removing downloaded files..."
            foreach ($ItemName in "$home\downloads\EldenRing", $download) {
                if (Test-Path -Path $ItemName) {
                    Remove-Item -Path $ItemName -Recurse
                }
            }    
        }
        catch {
            $pscmdlet.throwterminatingerror($psitem)
        }
    }
    
    end {
        
    }
}

#Update-EldenRingSeamlessCoop

#Update-EldenRingSeamlessCoop -Password "ExamplePasswordHere"