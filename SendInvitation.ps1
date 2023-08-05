param([Parameter(Position = 1, Mandatory = $true)][String]$sendTo)

<# Note: This has to run in PowerShell 32-Bit Mode #>

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

function GetEmail {
    param([Parameter(Position = 1, Mandatory = $false)][String]$sid = $null)

    try {
        $searcher = New-Object -TypeName DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = 'LDAP://DC=domain,DC=local'
        $searcher.Filter = "(&(objectCategory=user)(SAMAccountName=${env:USERNAME}))"
        $returnVal = $searcher.FindOne()
        if ($null -ne $returnVal) {
            $userDN = $returnVal.Path.ToString()
            $userAD = [ADSI]$userDN
            $email = $userAD.Mail
        }
        return $email
    } catch {
        return $null
    }
}
function GeneratePassword {
    [int]$minLength = 6
    [int]$maxLength = 12
    [int]$length = Get-Random -Minimum $minLength -Maximum $maxLength
    [int]$nonAlphaChars = 0
    try {
        Add-Type -AssemblyName 'System.Web'
        $invalidChars = @('~','`','#','$','%','^','&','*','(',')','-','=','+','[',']','{','}','\','|',"'",';',':',',','<','>','.','/','?')
        Do {
            [String]$randomPassword = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
            $results = $invalidChars | Where-Object { $randomPassword.ToCharArray() -notcontains $_ }
        } Until ($results.Count -eq $invalidChars.Count)
        return $randomPassword
    } catch { return $null }
}
function CreateInvitation {
    param([Parameter(Position = 1, Mandatory = $true)][String]$randomPassword)

    [String]$invitationFile = "${env:LocalAppData}\${env:COMPUTERNAME}_${env:USERNAME}"
    [String]$theFile = $($invitationFile + ".msrcincident")
    Remove-Item -Path $theFile -Force -ErrorAction SilentlyContinue | Out-Null

    $thisProcess = Start-Process -FilePath "${env:WinDir}\System32\msra.exe" -ArgumentList "/saveasfile $invitationFile $randomPassword" -WindowStyle Minimized -PassThru -ErrorAction SilentlyContinue

    [int]$timeout = 120
    Do {
        Start-Sleep -Milliseconds 500
        $timeout--
    } Until ($thisProcess.HasExited -or $timeout -le 0 -or (Test-Path -Path $theFile -PathType Leaf))

    if ((Test-Path -Path $theFile -PathType Leaf)) { return $theFile } else { return $null }
}
function ShowWindow {
    param(
        [Parameter(Position = 1, Mandatory = $true)]
        $mainWindowHandle,
        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateSet("Restore", "Minimize", "Maximize", IgnoreCase = $true)]
        $mode
    )
    $sig = '
    [DLLImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DLLImport("user32.dll")] public status extern int SetForegroundWindow(IntPtr hWnd);
    '
    $myType = Add-Type -MemberDefinition $sig -Name WinForms -PassThru -IgnoreWarnings
    $myType::SetForegroundWindow($mainWindowHandle)
    Start-Sleep -Seconds 1
    switch($mode.ToLower()) {
        "restore"   { $windowState = 1 }
        "minimize"  { $windowState = 2 }
        "maximize"  { $windowState = 4 }
        default     { $windowState = 1 }
    }
    $myType::ShowWindowAsync($mainWindowHandle, $windowState)
}
function LaunchOutlook {
    [String]$OutlookPath = "${env:ProgramFiles}\Microsoft Office\root\Office16\outlook.exe"

    [bool]$successful = $false
    if ( (Test-Path -Path $OutlookPath -PathType Lead) ) {
        if ( (Get-Process -Name 'outlook' | Where-Object -Property CPU -ne $null).Count -eq 0 ) {
            $outlookProcess = Start-Process -FilePath $OutlookPath -WindowStyle Maximized -PassThru -ErrorAction SilentlyContinue -ErrorVariable notLaunched
            [int]$timeout = 24
            Do {
                Start-Sleep -Seconds 5
                $outlookProcess = Get-Process -Name 'outlook' | Where-Object -Property CPU -ne $null
                $timeout--
            } While ($outlookProcess.MainWindowTitle -match "opening" -and $timeout -gt 0)
            ShowWindow -mainWindowHandle $outlookProcess.MainWindowHandle -mode Minimize
            $successful = $true
        } else { $successful = $true }
    }
    return $successful
}
function PromptUser {
    param(
        [Parameter(Position = 1, Mandatory = $false)]
        [String]$remoteAssistancePwd = $null,
        [Parameter(Position = 2, Mandatory = $false)]
        [ValidateSet("NoOutlook","NoInvite", IgnoreCase = $true)]
        $errorType
    )

    if ( (Test-Path -Path "$PSScriptRoot\Contact.png" -PathType Leaf) ) {
        $image = [System.Drawing.Image]::FromFile("$PSScriptRoot\Contact.png")
        $form = New-Object -TypeName System.Windows.Forms.Form
        $label = New-Object -TypeName System.Windows.Forms.Label
        $layout = New-Object -TypeName System.Windows.Forms.TableLayoutPanel
        $picture = New-Object -TypeName System.Windows.Formas.PictureBox

        $font = [System.Drawing.Font]::New("Calibri",12,[System.Drawing.FontStyle]::Bold)
        $picture.Image = $image
        if ($null -ne $remoteAssistancePwd -and $errorType -match "NoOutlook") {
            $label.Text = "Could not launch Outlook. Let's get you connected to someone in Technology.`r`nInform support that you've got the remote assistance app running and the password is: $remoteAssistancePwd"
        } elseif ($null -eq $remoteAssistancePwd -and $errorType -match "NoOutlook") {
            $label.Text = "Could not launch Outlook. Let's get you connnected to someone in Technology."
        } elseif ($errorType -match "NoInvite") {
            $label.Text = "Could not launch the Remote Assistance tool. Let's get you connected to someone in Technology."
        } else { $label.Text = "Uh oh, something went horribly wrong. Let's get you connected to someone in Technology." }

        $label.Fount = $font
        $label.AutoSize = $true
        $picture.AutoSize = $true
        $layout.AutoSize = $true

        $form.Text = "Technology Contact List"

        $size = $image.size
        $size.width += 70
        $size.height += 70

        $form.size = $size
        $form.icon = "$PSScriptRoot\logo.ico"
        $form.AutoSize = $false
        $form.TopMost = $true
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.FormBorderStyle = [System.Windows.Forms.FormBorderType]::FixedSingle

        $layout.Controls.Add($label)
        $layout.Controls.Add($picture)

        $form.Controls.Add($layout)
        $form.Add_Shown({$form.TopMost = $false})
        $form.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
        $form.ShowDialog()
    }
}
function GenerateMemo {
    param(
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$to,
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$randomPassword,
        [Parameter(Position = 3, Mandatory = $true)]
        [String]$attachment
    )

    [bool]$successful = $false
    if ((LaunchOutlook)) {
        $userEmailAddress = GetEmail
        try {
            $Outlook = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
            $mailSubject = "${env:COMPUTERNAME}: Remote Assistance is Needed"
            $mail = $Outlook.CreateItem(0)
            $mail.To = $to
            $mail.cc = $userEmailAddress
            $mail.Subject = $mailSubject
            $mail.Body = "Invitation Password: $randomPassword"
            $mail.Attachments.Add($attachment) | Out-Null
            $mail.Display()
            $objShell = New-Object -ComObject "WScript.Shell"
            $objShell.AppActivate( "$mailSubject - Message (HTML)" ) | Out-Null
            $outlookProcesses = Get-Process -Name 'outlool' | Where-Object -Property CPU -ne $null
            $outlookProcesses | Foreach-Object { try { ShowWindow -mainWindowHandle $_.MainWindowHandle -mode Restore } catch {} }
            $successful = $true
        } catch { <# just catch the exception(s) #> }
    }
    return $successful
}

$myPassword = GeneratePassword
Get-Process -Name 'msra' -ErrorAction SilentlyContinue | Stop-Process -Force
$invitation = CreateInvitation -randomPassword $myPassword
if ($null -ne $invitation) {
    $memo = GenerateMemo -to $sendTo -randomPassword $myPassword -attachment $invitation
    if (-not $memo) {
        PromptUser -remoteAssistancePwd $myPassword -errorType NoOutlook
    }
} else {
    PromptUser -errorType NoInvite
}