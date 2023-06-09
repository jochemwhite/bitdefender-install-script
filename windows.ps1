# Insert your company-hash here. When you get the download link, this is the long alpha-numeric scring 
# that comes after setupdownloader_ in the filename. 
# Do not include the square brackets (but do include the = if there is one).
$CompanyHash = "aHR0cHM6Ly9jbG91ZC1lY3MuZ3Jhdml0eXpvbmUuYml0ZGVmZW5kZXIuY29tL1BhY2thZ2VzL0JTVFdJTi8wL0tXZHJseS9pbnN0YWxsZXIueG1sP2xhbmc9ZW4tVVM="

### Modify below this line at your own risk!

# If it's already installed, just do nothing
$Installed = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
Where-Object { $_.DisplayName -eq "Bitdefender Endpoint Security Tools" }

if ($Installed) {
    Write-Output "Bitdefender already installed. Exiting."
    Exit 0
}

$BitdefenderURL = "setupdownloader_[$CompanyHash].exe"
$BaseURL = "https://cloud.gravityzone.bitdefender.com/Packages/BSTWIN/0/"
$URL = $BaseURL + $BitdefenderURL
$Destination = 'C:\Windows\Temp\setupdownloader.exe'

try 
{
    Write-Output "Beginning download of Bitdefender to $Destination"
    Invoke-WebRequest -Uri $URL -OutFile $Destination
}
catch
{
    Write-Output "Error Downloading - $_.Exception.Response.StatusCode.value_"
    Write-Output $_
    Exit 1
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script
$FullDestination = "$DestinationPath\setupdownloader_[$CompanyHash].exe"
if (Test-Path $FullDestination) {
   Remove-Item $FullDestination
   Write-Out "Removed $FullDestination..."
}

Rename-Item -Path $Destination -NewName "setupdownloader_[$CompanyHash].exe"
Write-Output "Download succeeded, beginning install..."
Start-Process -FilePath "C:\Windows\Temp\$BitdefenderURL" -ArgumentList "/bdparams /silent silent" -Wait -NoNewWindow

# Wait an additional 30 seconds after the installer process completes to verify installation
Start-Sleep -Seconds 30

$Installed = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
Where-Object { $_.DisplayName -eq "Bitdefender Endpoint Security Tools" }

if ($Installed) {
    Write-Output "Bitdefender successfully installed."
    Exit 0
}
else {
    Write-Output "ERROR: Failed to install Bitdefender"
    Exit 1
}
