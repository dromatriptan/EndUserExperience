$taskName = "Install Application"
$taskRun = "some.exe  -andsomearguments"
$startTime = "{0:HH:mm}" -f (Get-Date).AddMinutes(5)
$runAs = "${env:USERDOMAIN}\${env:USERNAME}"
$params = @{
    FilePath = "schtasks.exe"
    ArgumentList = "/Create /TN `"$taskName`" /TR `"$taskRun`" /SC ONCE /ST `"$startTime`" /F /IT /V1 /RU `"$runAs`""
    WindowStyle = 'Hidden'
    PassThru = $true
    Wait = $true
}
$p = Start-Process @params
$p.ExitCode