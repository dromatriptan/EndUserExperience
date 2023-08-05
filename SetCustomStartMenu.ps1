[String]$saveTo = "${env:PUBLIC}\Documents\StartLayout.xml"
[xml]$startMenuXml = '<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride LayoutCustomizationRestrictionType="OnlySpecifiedGroups">
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6">
                <start:Group Name="My company">
                    <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationID="Chrome" />
                    <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationID="Microsoft.Office.OUTLOOK.EXE.15" />
                    <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationID="Microsoft.SoftwareCenter.DesktopToasts" />
                </start:Group>
            </defaultlayout:StartLayout>
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>'

$startMenuXml.Save($saveTo)

$explorer = Get-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -ErrorAction SilentlyContinue
if ($null -eq $explorer) {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Force
}

$lockedStartLayout = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name LockedStartLayout -ErrorAction SilentlyContinue
if ($null -eq $lockedStartLayout) {
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name LockedStartLayout -PropertyType Dword -Value 1 -Force
} else { 
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name LockedStartLayout -Value 1 -Force
}

$startLayoutFile = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name StartLayoutFile -ErrorAction SilentlyContinue
if ($null -eq $startLayoutFile) {
    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name StartLayoutFile -PropertyType String -Value $saveTo -Force
}
else {
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name StartLayoutFile -Value $saveTo -Force
}