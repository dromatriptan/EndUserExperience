[string]$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
[String]$valueName = "EnableDynamicContentInWSB"
[int]$expectedValue = 0

New-ItemProperty -Path $key -Name $valueName -PropertyType Dword -Value $expectedValue -Force -ErrorAction SilentlyContinue -ErrorVariable setError | Out-Null