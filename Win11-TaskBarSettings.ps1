[Array]$StartMenuProperties = @(
    [PSCustomObject]@{
        <# Disable Widgets Taskbar button #>
        path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        type = [Microsoft.Win32.RegistryValueKind]::DWord
        value = [String]"TaskbarDa"
        data = [int]0
    },
    [PSCustomObject]@{
        <# Remove Chat from Taskbar #>
        path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        type = [Microsoft.Win32.RegistryValueKind]::DWord
        value = [String]"TaskbarMn"
        data = [int]0
    },
    [PSCustomObject]@{
        <# Left-align the Start Menu #>
        path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        type = [Microsoft.Win32.RegistryValueKind]::DWord
        value = [String]"TaskbarAl"
        data = [int]0
    },
    [PSCustomObject]@{
        <# Disable Taskbar Application Grouping #>
        path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        type = [Microsoft.Win32.RegistryValueKind]::DWord
        value = [String]"TaskbarGlomLevel"
        data = [int]0
    },
    [PSCustomObject]@{
        <# Enable classic right-click context menu - this removes the "Show More Options" feature #>
        path = "Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        type = [Microsoft.Win32.RegistryValueKind]::String
        value = [String]"(Default)"
        data = [String]""
    },
    [PSCustomObject]@{
        <# Untested - Show Classic (Windows 10) Start Menu #>
        path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        type = [Microsoft.Win32.RegistryValueKind]::DWord
        value = [String]"Start_ShowClassicMode"
        data = [int]1
    }
)

function InstallRegEntries {
    param(
        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("HKU", "HKLM", IgnoreCase = $true)]
        [String]$root,
        [Parameter(Position = 2, Mandatory = $true)]
        [Array]$regEntries
    )

    $successful = $true
    if ($root -like 'hku') {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -ErrorAction SilentlyContinue -ErrorVariable driveError | Out-Null
        if (-not $driveError) {
            $userKeys = Get-ChildItem -Path 'HKU:\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21' -and $_.Name -notlike '*_Classes' }
            foreach ($u in $userKeys) {
                foreach ($r in $regEntries) {
                    $regKey = Join-Path -Path $u.PSPath -ChildPath $r.path
                    if ( (Test-Path -Path $regKey -PathType Container) -eq $false ) {
                        New-Item -Path (Split-Path -Path $regKey -Parent) -Name (Split-Path -Path $regKey -Leaf) -Force -ErrorAction SilentlyContinue -ErrorVariable RegError | Out-Null
                        if ($regError) { $successful = $false }
                    }
                    New-ItemProperty -Path $regKey -Name $r.value -PropertyType $r.data -Value $r.data -Force -ErrorAction SilentlyContinue -ErrorVariable RegError | Out-Null
                    if ($regError) { $successful = $false }
                }
            }
            Remove-PSDrive -Name HKU -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
    elseif ($root -like 'hklm') {
        foreach ($r in $regEntries) {
            $regKey = Join-Path -Path 'HKLM:\' -ChildPath $r.Path
            if ( (Test-Path -Path $regKey -PathType Container) -eq $false ) {
                New-Item -Path (Split-Path $regKey -Parent) -Name (Split-Path -Path $regKey -Leaf) -Force -ErrorAction RegError | Out-Null
                if ($regError) { $successful = $false }
            }
            New-ItemProperty -Path $regKey -Name $r.value -PropertyType $r.type -Value $r.data -ErrorAction SilentlyContinue -ErrorVariable RegError | Out-Null
            if ($regError) { $successful = $false }
        }
    }
    return $successful
}

$installed = InstallRegEntries -root HKU -regEntries $StartMenuProperties
if ($installed) { [System.Environment]::Exit(0) } else { [System.Environment]::Exit(0) }