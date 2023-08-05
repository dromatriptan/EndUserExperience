<#
    Simple Script to Schedule a task that runs as the user that's logged in.
    You'll want to write something that will figure out the computername and
    username of the logged on user this script will be targeting, however.

    This particular example will run a vbscript style popup prompting the user.
#>

$vbButton = 4
<# 
'0   OK button. 
'1   OK and Cancel buttons. 
'2   Abort, Retry, and Ignore buttons. 
'3   Yes, No, and Cancel buttons. 
'4   Yes and No buttons. 
'5   Retry and Cancel buttons.
#>
$vbIcon = 32
<# 
'16  "Stop Mark" icon. 
'32  "Question Mark" icon. 
'48  "Exclamation Mark" icon. 
'64  "Information Mark" icon.  
#>
$intButton = 0
<#
'1  OK button 
'2  Cancel button 
'3  Abort button 
'4  Retry button 
'5  Ignore button 
'6  Yes button 
'7  No button
'-1 Timed out
#>

$delayInMinutes = 1
$popupTimeout = 10
$vbTitle = "Title goes here"
$vbMessage = "Message goes here"
$runAsUser = "${env:COMPUTERNAME}\${env:USERNAME}"
$psCommand = "(New-Object -ComObject 'WScript.Shell').PopUp($vbMessage, $popupTimeout, $vbTitle, $vbButton + $vbIcon)"
$taskname = "VBScript Popup"
$taskAction = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-Version 4.0 -ExecutionPolicy Bypass -Command `"$psCommand`""
$taskDescription = 'Runs VBScript-based popup message'
$taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8
$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($delayInMinutes)
Register-ScheduledTask `
    -Force `
    -TaskName $taskName `
    -Action $taskAction `
    -Description $taskDescription `
    -Settings $taskSettings `
    -Trigger $taskTrigger `
    -User $runAsUser `
    -RunLevel Limited