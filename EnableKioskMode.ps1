function EnableLauncher {
    [bool]$enabled = $false
    $state = Get-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State
    if ($state -match "disabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -NoRestart -All
        $state = Get-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State
        if ($state -match "enabled") { $enabled = $true }
    } elseif ($state -match "enabled") { $enabled = $true }
    return $enabled
}

function ConfigureShells {
    [bool]$successful = $false

    $restartShell = 0
    $restartDevice = 1
    $adminUserSid = "S-1-5-32-544"
    $usersGroupSid = "S-1-5-32-545"
    $defaultShell = "cmd.exe"
    $kioskShell = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe --start-fullscreen --app=`"https://some.url.com`""
    $adminShell = "explorer.exe"

    try {
        $shellLauncherClass = Get-CimClass -ClassName 'WESL_UserSetting' -Namespace 'root\standardcimv2\embedded'
    }
    catch {
        $shellLauncherClass = $null
    }
    if ($null -ne $shellLauncherClass) {
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName SetDefaultShell -Arguments @{DefaultAction=$restartDevice; Shell=$defaultShell} -ErrorAction SilentlyContinue
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName SetCustomShell -Arguments @{Sid=$usersGroupSid; Shell=$kioskShell; CustomReturnCodes=$null; CustomReturnCodesAction=$null; DefaultAction=$restartShell} -ErrorAction SilentlyContinue
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName SetCustomShell -Arguments @{Sid=$adminUserSid; Shell=$adminShell; CustomReturnCodes=$null; CustomReturnCodesAction=$null; DefaultAction=$restartShell} -ErrorAction SilentlyContinue
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName SetEnabled -Arguments @{Enabled=$true} -ErrorAction SilentlyContinue
        $isShellLauncherEnabled = Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName IsEnabled -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled
        if ($isShellLauncherEnabled) { $successful = $true }
    }
    return $successful
}

$isEnabled = EnableLauncher
if ($isEnabled) {
    $isConfigured = ConfigureShells
}

return [PSCustomObject] @{
    DeviceName = $env:COMPUTERNAME
    LauncherEnabled = $isEnabled
    ShellsConfigured = $isConfigured
}