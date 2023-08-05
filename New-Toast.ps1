<#
    Original lives here https://imab.dk
    This is a customized
#>
param(
    [Parameter(Position = 1, Mandatory = $true)]
    [ValidateSet("short","long","reminder")]
    [String]$scenario,
    [Parameter(Position = 2, Mandatory = $false)]
    [DateTime]$deadline = (Get-Date -Date "2023-07-27 19:00")
)
$imgPath = "$($PSScriptRoot.Replace("\","/"))/Images"
$imgHero  = "file:///$imagesPath/hero.png"
$imgLogo = "file://$imagesPath/logo.png"
$txtAttribution = "dromatriptan.local"
$txtHeader = "The End User Computing Team"
$txtTitle = "Application Upgrade"
$txtBody1 = "Your Microsoft Office suite is scheduled for an upgrade"
$txtBody2 = "On $($deadline.DayOfWeek) $($deadline.ToShortDateString()) @ $($deadline.ToShortTimeString()), your Microsoft Office suite will be upgraded."
$btnAction1 = "Support"
$btnAction2 = $null
$btnSnooze = "Snooze"
$App = "Microsoft.SoftwareCenter.DesktopToasts"

$xmlToast = New-Object -TypeName Xml
$nodeDeclaration = $Toast.CreateXmlDeclaration("1.0","UTF-8",$null)

$elemToast = $xmlToast.CreateElement("toast")
$elemToast.SetAttribute("scenario", $scenario)
$elemToast.SetAttribute("duration", "long")
$elemToast.SetAttribute("launch", "toastID=1")

$elemVisual = $xmlToast.CreateElement("visual")

$elemBinding = $xmlToast.CreateElement("binding")
$elemBinding.SetAttribute("template","ToastGeneric")

$elemImgHero = $xmlToast.CreateElement("image")
$elemImgHero.SetAttribute("id", "1")
$elemImgHero.SetAttribute("placement", "hero")
$elemImgHero.SetAttribute("src", $imgHero)

$elemImgLogo = $xmlToast.CreateElement("image")
$elemImgLogo.SetAttribute("id", "1")
$elemImgLogo.SetAttribute("placement","appLogoOverride")
$elemImgLogo.SetAttribute("hint-crop", "circle")
$elemImgLogo.SetAttribute("src", $imgLogo)

$elemTxtAttribution = $xmlToast.CreateElement("text")
$elemTxtAttribution.SetAttribute("placement", "attribution")
$nodeTxtAttribution = $xmlToast.CreateTextNode($txtAttribution)
$elemTxtAttribution.AppendChild($nodeTxtAttribution) | Out-Null

$elemTxtHeader = $xmlToast.CreateElement("text")
$nodeTxtHeader = $xmlToast.CreateTextNode($txtHeader)
$elemTxtHeader.AppendChild($nodeTxtHeader) | Out-Null

$elemGrpTxtTitle = $xmlToast.CreateElement("group")
$elemSubTxtTitle = $xmlToast.CreateElement("subgroup")
$elemTxtTitle = $xmlToast.CreateElement("text")
$elemTxtTitle.SetAttribute("hint-style", "title")
$elemTxtTitle.SetAttribute("hint-wrap", "true")
$nodeTxtTitle = $xmlToast.CreateTextNode($txtTitle)
$elemTxtTitle.AppendChild($nodeTxtTitle) | Out-Null
$elemSubTxtTitle.AppendChild($elemTxtTitle) | Out-Null
$elemGrpTxtTitle.AppendChild($elemSubTxtTitle) | Out-Null

$elemGrpTxtBody1 = $xmlToast.CreateElement("group")
$elemSubTxtBody1 = $xmlToast.CreateElement("subgroup")
$elemTxtBody1 = $xmlToast.CreateElement("text")
$elemTxtBody1.SetAttribute("hint-style","base")
$elemTxtBody1.SetAttribute("hint-wrap", "true")
$nodeTxtBody1 = $xmlToast.CreateTextNode($txtBody1)
$elemTxtBody1.AppendChild($nodeTxtBody1) | Out-Null
$elemSubTxtBody1.AppendChild($elemTxtBody1) | Out-Null
$elemGrpTxtBody1.AppendChild($elemSubTxtBody1) | Out-Null

$elemGrpTxtBody2 = $xmlToast.CreateElement("group")
$elemSubTxtBody2 = $xmlToast.CreateElement("subgroup")
$elemTxtBody2 = $xmlToast.CreateElement("text")
$elemTxtBody2.SetAttribute("hint-style","base")
$elemTxtBody2.SetAttribute("hint-wrap", "true")
$nodeTxtBody2 = $xmlToast.CreateTextNode($txtBody2)
$elemTxtBody2.AppendChild($nodeTxtBody2) | Out-Null
$elemSubTxtBody2.AppendChild($elemTxtBody2) | Out-Null
$elemGrpTxtBody2.AppendChild($elemSubTxtBody2) | Out-Null

$elemBinding.AppendChild($elemImgHero) | Out-Null
$elemBinding.AppendChild($elemImgLogo) | Out-Null
$elemBinding.AppendChild($elemTxtAttribution) | Out-Null
$elemBinding.AppendChild($elemTxtHeader) | Out-Null
$elemBinding.AppendChild($elemGrpTxtTitle) | Out-Null
$elemBinding.AppendChild($elemGrpTxtBody1) | Out-Null
$elemBinding.AppendChild($elemGrpTxtBody2) | Out-Null

$elemVisual.AppendChild($elemBinding) | Out-Null

$elemGrpActions = $xmlToast.CreateElement("actions")
$elemBtnAction1 = $xmlToast.CreateElement("action")
$elemBtnAction1.SetAttribute("activationtype", "protocol")
$elemBtnAction1.SetAttribute("arguments","mailto:support@company.com")
$elemBtnAction1.SetAttribute("content",$btnAction1)

$elemInput = $xmlToast.CreateElement("input")
$elemInput.SetAttribute("id", "snoozeTime")
$elemInput.SetAttribute("type", "selection")
$elemInput.SetAttribute("title", "Snooze")
$elemInput.SetAttribute("defaultInput", "15")

$elemSelInput1 = $xmlToast.CreateElement("selection")
$elemSelInput1.SetAttribute("id","15")
$elemSelInput1.SetAttribute("content", "15 Minutes")

$elemSelInput2 = $xmlToast.CreateElement("selection")
$elemSelInput2.SetAttribute("id","30")
$elemSelInput2.SetAttribute("content", "30 Minutes")

$elemSelInput3 = $xmlToast.CreateElement("selection")
$elemSelInput3.SetAttribute("id","1")
$elemSelInput3.SetAttribute("content", "1 Hour")

$elemInput.AppendChild($elemSelInput1) | Out-Null
$elemInput.AppendChild($elemSelInput2) | Out-Null
$elemInput.AppendChild($elemSelInput3) | Out-Null

$elemBtnSnooze = $xmlToast.CreateElement("action")
$elemBtnSnooze.SetAttribute("activationtype", "system")
$elemBtnSnooze.SetAttribute("arguments", "snooze")
$elemBtnSnooze.SetAttribute("hint-inputId", "snoozeTime")
$elemBtnSnooze.SetAttribute("content", $btnSnooze)

$elemBtnDismiss = $xmlToast.CreateElement("action")
$elemBtnDismiss.SetAttribute("activationtype", "system")
$elemBtnDismiss.SetAttribute("arguments", "dismiss")
$elemBtnDismiss.SetAttribute("content", $elemBtnDismiss)

$elemGrpActions.AppendChild($elemInput) | Out-Null
$elemGrpActions.AppendChild($elemBtnAction1) | Out-Null
$elemGrpActions.AppendChild($elemBtnSnooze) | Out-Null
$elemGrpActions.AppendChild($elemBtnDismiss) | Out-Null

$elemToast.AppendChild($elemVisual) | Out-Null
$elemToast.AppendChild($elemGrpActions) | Out-Null
$xmlToast.AppendChild($nodeDeclaration) | Out-Null
$xmlToast.AppendChild($elemToast) | Out-Null

$load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRunTime]

$docToast = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
$docToast.LoadXml($xmlToast.OuterXml)

try { [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($docToast) } catch { <# Do nothing here for now. #> }