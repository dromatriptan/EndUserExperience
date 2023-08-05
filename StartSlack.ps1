function RemoveSlackFromRegistryRunKey {
    $item = Get-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue -ErrorVariable getItemError
    if (-not $getItemError) {
        foreach ($value in $item.GetValueNames()) {
            $regValue = Get-ItemPropertyValue -Path $item.PSPath -Name $value -ErrorAction SilentlyContinue
            if ($regValue -like "*$(Join-Path -Path $env:ProgramFiles -ChildPath "Slack\slack.exe")*" -or $regValue -like "*$(Join-Path -Path $env:LocalAppData -ChildPath "Slack\slack.exe")*") {
                Remove-ItemProperty -Path $item.PSPath -Name $value | Out-Null
            }
        }
    }
}

function RemoveSlackFromStartMenuStartup {
    $objShell = New-Object -ComObject WScript.Shell
    $shortcuts = Get-ChildItem -Path (Join-Path -Path $env:AppData -ChildPath "Microsoft\Windows\Start Menu\Programs\Startup\*.lnk") -ErrorAction SilentlyContinue
    foreach ($shortcut in $shortcuts) {
        $targetPath = $objShell.CreateShortcut($shortcut.FullName).TargetPath
        if ($targetPath -like "*$(Join-Path -Path $env:ProgramFiles -ChildPath "Slack\slack.exe")*" -or $targetPath -like "*$(Join-Path -Path $env:LocalAppData -ChildPath "Slack\slack.exe")*") {
            Remove-Item -Path $shortcut.FullName -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function StartSlack {
    [String]$uri = "https://app.slack.com"
    [int]$timeoutInSeconds = 900
    [int]$sleepInSeconds = 5
    [int]$maxWait = [System.Math]::round( ($timeoutInSeconds / $sleepInSeconds),0 )
    [int]$waitCount = 0

    $request = $null

    Get-Process -Name Slack -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Do {
        try {
            $time = (Measure-Command {$request = Invoke-WebRequest -Uri $uri -UseBasicParsing}).TotalMilliseconds
        }
        catch {
            $request = $_.Exception.Response
            $time = -1
        }
        Start-Sleep -Seconds $sleepInSeconds
        $waitCount++
    } Until ($request.StatusCode -eq "200" -or $waitCount -ge $maxWait)

    if ($request.StatusCode -ne "200" -or $time -eq -1 -or $time -gt 60000) {
        $code = [int]$request.StatusCode
        if ($code -eq 0) { <# Cannot resolve the URL #> }
    }
    else {
        Get-Process -Name Slack -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if ( (Test-Path -Path "${env:LocalAppData}\slack\slack.exe" -PathType Leaf) -eq $true ) {
            Start-Process -FilePath "${env:LocalAppData}\slack\slack.exe" -WorkingDirectory $env:LocalAppData -ErrorAction SilentlyContinue
        }
    }
}

RemoveSlackFromRegistryRunKey
RemoveSlackFromStartMenuStartup
StartSlack
[System.Environment]::Exit(0)