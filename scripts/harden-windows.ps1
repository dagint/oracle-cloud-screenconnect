# Harden-Windows.ps1
# Automated Windows Server Hardening for ScreenConnect
# Run as Administrator after initial deployment

Write-Host "Starting Windows hardening..." -ForegroundColor Cyan

# 1. Remove SMBv1
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# 2. Disable Print Spooler (if not needed)
Stop-Service Spooler -ErrorAction SilentlyContinue
Set-Service Spooler -StartupType Disabled

# 3. Rename Administrator account
try {
    Rename-LocalUser -Name "Administrator" -NewName "Admin-$(Get-Random)"
    Write-Host "Renamed Administrator account." -ForegroundColor Green
} catch { Write-Warning "Could not rename Administrator account: $_" }

# 4. Disable Guest account
try {
    Disable-LocalUser -Name "Guest"
    Write-Host "Disabled Guest account." -ForegroundColor Green
} catch { Write-Warning "Could not disable Guest account: $_" }

# 5. Enable Network Level Authentication (NLA) for RDP
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1
Write-Host "Enabled NLA for RDP." -ForegroundColor Green

# 6. Configure Windows Firewall (allow only required ports)
$ports = @(443, 8041, 80, 3389) # HTTPS, Relay, HTTP redirect, RDP
foreach ($port in $ports) {
    New-NetFirewallRule -DisplayName "Allow Port $port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -Profile Any -ErrorAction SilentlyContinue
}
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Write-Host "Configured Windows Firewall." -ForegroundColor Green

# 7. Enable BitLocker (if not already enabled)
if ((Get-BitLockerVolume -MountPoint "C:").VolumeStatus -ne 'FullyEncrypted') {
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector
    Write-Host "BitLocker enabled on C:." -ForegroundColor Green
} else {
    Write-Host "BitLocker already enabled on C:." -ForegroundColor Yellow
}

# 8. Enable audit policies
AuditPol /set /category:* /success:enable /failure:enable
Write-Host "Enabled audit policies." -ForegroundColor Green

# 9. Set password and account lockout policies
net accounts /minpwlen:12 /maxpwage:90 /lockoutthreshold:5 /lockoutduration:15
Write-Host "Set password and account lockout policies." -ForegroundColor Green

Write-Host "Windows hardening complete!" -ForegroundColor Cyan 