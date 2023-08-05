function DisableLauncher {
    [bool]$disabled = $false
    $state = Get-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State
    if ($state -notmatch "disabled") {
        Disable-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -NoRestart | Out-Null
        $state = Get-WindowsOptionalFeature -Online -FeatureName 'Client-EmbeddedShellLauncher' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State
        if ($state -match "disabled") { $disabled = $true }
    } elseif ($state -match "disabled") { $disabled = $true }
    return $disabled
}

function RemoveustomShells {
    [bool]$successful = $false

    $adminUserSid = "S-1-5-32-544"
    $usersGroupSid = "S-1-5-32-545"

    try {
        $shellLauncherClass = Get-CimClass -ClassName 'WESL_UserSetting' -Namespace 'root\standardcimv2\embedded'
    }
    catch {
        $shellLauncherClass = $null
    }
    if ($null -ne $shellLauncherClass) {
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName RemoveCustomShell -Arguments @{Sid=$usersGroupSid} -ErrorAction SilentlyContinue
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName RemoveCustomShell -Arguments @{Sid=$adminUserSid} -ErrorAction SilentlyContinue
        Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName SetEnabled -Arguments @{Enabled=$false} -ErrorAction SilentlyContinue
        $isShellLauncherEnabled = Invoke-CimMethod -Namespace 'root\standardcimv2\embedded' -ClassName 'WESL_UserSetting' -MethodName IsEnabled -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled
        if (-not $isShellLauncherEnabled) { $successful = $true }
    }
    return $successful
}

$isRemoved = RemoveCustomShells
if ($isRemoved) {
    $isDisabled = DisableLauncher
}


return [PSCustomObject] @{
    DeviceName = $env:COMPUTERNAME
    ShellsRemoved = $isRemoved
    LauncherDisabled = $isDisabled
}