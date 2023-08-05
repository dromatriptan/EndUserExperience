$fileSystemExclusions =@{
    "${env:ProgramFiles}\Microsoft Security Client",
    "${env:ProgramData}\Microsoft\Crypto",
    "${env:ProgramData}\Microsoft\dot3svc\Profiles\Interfaces",
    "${env:ProgramData}\Microsoft\Microsoft Antimalware",
    "${env:ProgramData}\Microsoft\Network\Downloader",
    "${env:WinDir}\CCM\CcmStore.sdf",
    "${env:WinDir}\CCM\CertEnrollmentStore.sdf",
    "${env:WinDir}\CCM\ClientEvents.sdf",
    "${env:WinDir}\CCM\CompIRelayStore.sdf",
    "${env:WinDir}\CCM\DDMCache.sdf",
    "${env:WinDir}\CCM\InventoryStore.sdf",
    "${env:WinDir}\CCM\ServiceData",
    "${env:WinDir}\CCM\StateMessageStore.sdf",
    "${env:WinDir}\CCM\UserAffinityStore.sdf",
    "${env:WinDir}\logs\WindowsUpdate",
    "${env:WinDir}\System32\Microsoft\Protect",
    "${env:WinDir}\Temp\Mpcmdrun.log",
    "${env:WinDir}\WindowsUpdate.log",
    "${env:WinDir}\System32\drivers\CrowdStrike",
    "${env:ProgramFiles}\CrowdStrike",
    "${env:ProgramFiles}\HYPR",
    "${env:ProgramData}\HYPR"
}
$registryExclusions = @{
    "HKLM:\Software\Microsoft\CCM\StateSystem",
    "HKLM:\Software\Microsoft\Microsoft\dot3svc",
    "HKLM:\Software\Microsoft\Microsoft Antimalware",
    "HKLM:\Software\Microsoft\Microsoft\SystemCertificates\SMS\Certificates",
    "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\TimeZones",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\BITS\StateIndex",
    "HKLM:\Software\Policies\Microsoft\Windows\WiredL2\GP_Policy",
    "HKLM:\System\CurrentControlSet\Control\TimeZoneInformation",
    "HKLM:\System\CrowdStrike",
    "HKLM:\System\CurrentControlSet\Services\CSAgent",
    "HKLM:\System\CurrentControlSet\Services\CSAgent\Sim",
    "HKLM:\System\CurrentControlSet\Services\CSBoot",
    "HKLM:\System\CurrentControlSet\Services\CSDeviceControl",
    "HKLM:\System\CurrentControlSet\Services\CSFalconService",
    "HKLM:\System\CurrentControlSet\Control\EarlyLaunch",
    "HKLM:\Software\Microsoft\AMSI\Providers",
    "HKLM:\System\CrowdStrike\{9b03c1d9-3138-44ed-9fae-d9f4c034b88d}\{16e0423f-7058-48c9-a204-725362b67639}\Default",
    "HKLM:\Software\Microsot\Windows\CurrentVersion\Authentication\Credential Providers\{C822931E-86C5-4482-85C1-049523A13A09}",
    "HKLM:\Software\HYPR Workforce Access"
}

<# https://learn.microsoft.com/en-us/windows-hardware/customize/enterprise/uwfmgrexe #>

$enableUwf = EnableWindowsOptionalFeature -Online -FeatureName 'Client-UnifiedWriteFilter' -NoRestart -All
$configureOverlay = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "overlay set-type disk" -WindowsStyle Hidden -Wait -PassThru
$setOverlaySize = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "overlay set-size 32768" -WindowsStyle Hidden -Wait -PassThru
$setCritical = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "overlay set-criticalthreshold 3277" -WindowsStyle Hidden -Wait -PassThru
$setWarning = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "overlay set-warningthreshold 6554" -WindowsStyle Hidden -Wait -PassThru

$fsExclusionSuccess = $false
$fileSystemExclusions.Foreach({
    $excluded = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "file add-exclusion `"$_`"" -WindowStyle Hidden -Wait -PassThru
    if ($excluded.ExitCode -ne 0) { $fsExclusionSuccess = $false }
})

$regExclusionSuccess = $true
$registryExclusions.Foreach({
    $excluded = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "registry add-exclusion `"$_`"" -WindowStyle Hidden -Wait -PassThru
    if ($excluded.ExitCode -ne 0) { $regExclusionSuccess = $false }
})

$enableFilter = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "filter enable" -WindowStyle Hidden -Wait -PassThru
$protectVolume = Start-Process -FilePath "uwfmgr.exe" -ArgumentList "volume protect C:" -WindowStyle Hidden -Wait -PassThru

return [PSCustomObject] @{
    Uwf_Enabled = $enableUwf.State
    Overlay_Configured = $configureOverlay.ExitCode
    Overlay_Sized = $setOverlaySize.ExitCode
    Critical_Threshold_Set = $setCritical.ExitCode
    Warning_Threshold_Set = $setWarning.ExitCode
    FileSystem_Exclusions_Added = $fsExclusionSuccess
    Registry_Exclusions_Added = $regExclusionSuccess
    Filter_Enabled = $enableFilter.ExitCode
    Volume_Protected = $protectVolume.ExitCode
}