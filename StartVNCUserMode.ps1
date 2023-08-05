function GetFreePort {
    [int]$sessionId = -1
    [int]$localPort = 5500
    $processes = Get-WmiObject -Class Win32_Process -Filter "Name = 'explorer.exe'"
    foreach ($process in $processes) {
        $users = Invoke-WmiMethod -InputObject $process -Name GetOwner -ErrorAction SilentlyContinue | Where-Object -Property User -eq $env:USERNAME
        if ($null -ne $users) { 
            $sessionId = $process | Select-Object -ExpandProperty SessionId
        }
    }

    if ($sessionId -gt 0) {
        $localPort += $sessonId
        $processIds = Get-WmiObject -Class Win32_Process -Filter "Name = 'vncserver.exe'" | Where-Object -Property SessionID -eq $sessionId | Select-Object -ExpandProperty ProcessId -Unique
        foreach ($processId in $processIds) {
            $ports = Get-NetTCPConnection -OwningProcess $processId | Select-Object -ExpandProperty LocalPort -Unique
            foreach ($port in $ports) {
                if ($localPort -eq $port) { $localPort++ }
            }
        }
    }
    return $localPort
}
function TerminateInstance {
    [bool]$terminated = $false
    [int]$sessionId = -1
    $processes = Get-WmiObject -Class Win32_Process -Filter "Name = 'explorer.exe'"
    foreach ($process in $processes) {
        $users = Invoke-WmiMethod -InputObject $process -Name GetOwner -ErrorAction SilentlyContinue | Where-Object -Property User -eq $env:USERNAME
        if ($null -ne $users) { 
            $sessionId = $process | Select-Object -ExpandProperty SessionId
        }
    }

    if ($sessionId -gt 0) {
        $processIds = Get-WmiObject -Class Win32_Process -Filter "Name = 'vncserver.exe'" | Where-Object -Property SessionID -eq $sessionId | Select-Object -ExpandProperty ProcessId -Unique
        foreach ($processId in $processIds) {
            $sp = Stop-Process -id $processId -Force -ErrorAction SilentlyContinue -PassThru -ErrorVariable stopError
            Wait-Process -InputObject $sp -Timeout 10
        }
        if (-not $stopError) { $terminated = $true }
    }
    return $terminated
}

if ( (Test-Path -Path "${env:ProgramFiles}\RealVNC\VNC Server\vncserver.exe" -PathType Leaf) -eq $true) {
    TerminateInstance | Out-Null
    $vncPort = GetFreePort
    $p = Start-Process -FilePath "${env:ProgramFiles}\RealVNC\VNC Server\vncserver.exe" -ArgumentList "-noconsole -newinstance -RfbPort $vncPort" -PassThru -WindowStyle Hidden
    if ($null -ne (Get-process -Id $p.id -ErrorAction SilentlyContinue)) { [System.Environment]::Exit(0) }
    else { [System.Environment]::Exit(1) } <# VNC Server Process Terminated Unexpectedly #>
} else { [System.Environment]::Exit(2) } <# VNC Server is not installed #>