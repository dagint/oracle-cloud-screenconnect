# Windows Server Hardening Guide for ScreenConnect

This guide provides step-by-step recommendations and scripts to harden your Oracle Cloud Windows VM running ScreenConnect. Apply these steps **after initial deployment** and before exposing the instance to the internet.

---

## 1. OS & Service Hardening

- **Remove Unnecessary Features:**
  - Open PowerShell as Administrator:
    ```powershell
    # Remove SMBv1
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
    # Remove Print Spooler if not needed
    Stop-Service Spooler
    Set-Service Spooler -StartupType Disabled
    # Remove legacy components
    Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' } | Out-File InstalledFeatures.txt
    # Review and remove unnecessary features
    ```

- **Rename/Disable Local Administrator:**
    ```powershell
    # Rename Administrator
    Rename-LocalUser -Name "Administrator" -NewName "Admin-$(Get-Random)"
    # Disable Guest
    Disable-LocalUser -Name "Guest"
    ```

- **Remove Unused Accounts:**
    ```powershell
    Get-LocalUser | Where-Object { $_.Enabled -eq $true -and $_.Name -notin 'Admin-YourName','ScreenConnect' } | Disable-LocalUser
    ```

---

## 2. RDP Security

- **Restrict RDP to Specific IPs:**
  - Already implemented in Terraform security lists. Review regularly.

- **Change RDP Port (optional):**
    ```powershell
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'PortNumber' -Value 3390
    # Update firewall rules accordingly
    ```

- **Enable Network Level Authentication (NLA):**
    ```powershell
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1
    ```

- **Enforce Strong Passwords & MFA:**
  - Use Group Policy (see below) and consider third-party MFA solutions for RDP.

---

## 3. Windows Update

- **Enable Automatic Updates:**
    ```powershell
    sconfig # Use menu to enable automatic updates
    # Or via Group Policy:
    # Computer Configuration > Administrative Templates > Windows Components > Windows Update > Configure Automatic Updates
    ```

---

## 4. Defender & Endpoint Protection

- **Ensure Defender is Enabled:**
    ```powershell
    Set-MpPreference -DisableRealtimeMonitoring $false
    Update-MpSignature
    Start-MpScan -ScanType QuickScan
    ```

- **Consider EDR:**
  - For high-security environments, deploy a third-party EDR solution.

---

## 5. Windows Firewall

- **Restrict Inbound/Outbound Traffic:**
    ```powershell
    # Allow only required inbound ports
    New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
    New-NetFirewallRule -DisplayName "Allow Relay" -Direction Inbound -Protocol TCP -LocalPort 8041 -Action Allow
    New-NetFirewallRule -DisplayName "Allow HTTP Redirect" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
    # RDP (if needed)
    New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
    # Block all other inbound
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
    # Block all outbound except required (optional, advanced)
    # Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block
    ```

---

## 6. BitLocker (Disk Encryption)

- **Enable BitLocker:**
    ```powershell
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector
    ```

---

## 7. Logging & Auditing

- **Enable Audit Policies:**
    ```powershell
    AuditPol /set /category:* /success:enable /failure:enable
    # Or via Group Policy:
    # Computer Configuration > Windows Settings > Security Settings > Advanced Audit Policy Configuration
    ```

- **Forward Logs to SIEM (optional):**
  - Use Windows Event Forwarding or a third-party agent.

---

## 8. Password & Account Lockout Policies

- **Set via Group Policy (Local Security Policy):**
    - Minimum password length: 12+
    - Complexity: Enabled
    - Lockout threshold: 5 attempts
    - Lockout duration: 15+ minutes
    - Example (PowerShell):
      ```powershell
      net accounts /minpwlen:12 /maxpwage:90 /lockoutthreshold:5 /lockoutduration:15
      ```

---

## 9. Just-in-Time Access

- **Use Oracle Bastion or Session Manager:**
  - Avoid always-open RDP/SSH. Use temporary access when possible.

---

## 10. Vulnerability Scanning

- **Run Regular Scans:**
  - Use Nessus, OpenVAS, or Oracle’s built-in tools.
  - Address findings promptly.

---

## 11. ScreenConnect Application Security

- **Enforce 2FA for Admins:**
- **Set Session Timeouts:**
- **Regularly Review Users/Sessions:**
- **Restrict Access by IP (if possible):**

---

## References
- [CIS Microsoft Windows Server Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [Microsoft Security Compliance Toolkit](https://www.microsoft.com/en-us/download/details.aspx?id=55319)
- [Oracle Cloud Security Best Practices](https://docs.oracle.com/en-us/iaas/Content/Security/Concepts/security_best_practices.htm) 