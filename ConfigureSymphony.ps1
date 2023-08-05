[String]$installDir = "{$env:ProgramFiles}\Symphony\Symphony\config"
[Array]$symphoyConfig = @(
    [PSCustomObject]@{
        url = "https://company.symphony.com"
        minimizeOnClose = "ENABLED"
        launchOnStartup = "DISABLED"
        alwaysOnTop = "DISABLED"
        bringToFront = "DISABLED"
        whitelistUrl = "*"
        isCustomTitleBar = "ENABLED"
        memoryRefresh = "ENABLED"
        devToolsEnabled = $false
        contextIsolation = $true
        contextOriginUrl = ""
        disableGpu = $false
        ctWhitelist = @()
        podWhitelist = @()
        autoLaunchPath = ""
        notificationSettings = [PSCustomObject]@{ 
            position = "uppr-right"
            display = "" 
        }
        customFlags = [PSCustomObject]@{ 
            authServerWhitelist = ""
            authNegotiateDelegateWhitelist = ""
            disableThrottling = "DISABLED"
        }
        permissions = [PSCustomObject]@{
            media = $true
            geolocation = $true
            notifications = $true
            midiSysex = $true
            pointerLock = $true
            fullscreen = $true
            openExternal = $true
        }
    }
)

if ((Test-Path -Path $installDir -PathType Container)) {
    $symphonyConfig | ConvertTo-Json -Depth 99 | Out-File -Encoding ascii -FilePath (Join-Path -Path $installDir -ChildPath "Symphony.config") -Force -ErrorAction SilentlyContinue -ErrorVariable writeError
    if ($writeError) { return $false }
} else { return $false }