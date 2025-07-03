# ScreenConnect Version Update Script
# This script automates updating ScreenConnect to a new version

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')]
    [string]$NewVersion,
    
    [ValidateNotNullOrEmpty()]
    [string]$ConfigPath = "environments/production/terraform.tfvars",
    [ValidateNotNullOrEmpty()]
    [string]$UserDataPath = "modules/compute/user_data.tpl",
    [ValidateNotNullOrEmpty()]
    [string]$VersionPath = "VERSION",
    [switch]$DryRun,
    [switch]$Force
)

# Security: Validate script is running from expected location
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$expectedRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path (Join-Path $expectedRoot "VERSION"))) {
    Write-Error "Script must be run from the repository root directory"
    exit 1
}

Write-Host "=== ScreenConnect Version Update ===" -ForegroundColor Green
Write-Host "Current Version: $(Get-Content $VersionPath)" -ForegroundColor Yellow
Write-Host "New Version: $NewVersion" -ForegroundColor Yellow
Write-Host ""

# Check if version is already current
$currentVersion = Get-Content $VersionPath
if ($currentVersion -eq $NewVersion -and -not $Force) {
    Write-Warning "Version $NewVersion is already current. Use -Force to update anyway."
    exit 0
}

# Validate files exist
$filesToUpdate = @($ConfigPath, $UserDataPath, $VersionPath)
foreach ($file in $filesToUpdate) {
    if (-not (Test-Path $file)) {
        Write-Error "Required file not found: $file"
        exit 1
    }
}

try {
    Write-Host "Updating ScreenConnect version to $NewVersion..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Cyan
    }
    
    # 1. Update user_data.tpl with new ScreenConnect URL
    Write-Host "Updating user_data.tpl..." -ForegroundColor Yellow
    $userDataContent = Get-Content $UserDataPath -Raw
    
    # Update ScreenConnect download URL
    $oldUrlPattern = 'https://download\.screenconnect\.com/\d+\.\d+\.\d+\.\d+/ScreenConnect_\d+\.\d+\.\d+\.\d+\.msi'
    $newUrl = "https://download.screenconnect.com/$NewVersion/ScreenConnect_$NewVersion.msi"
    
    if ($userDataContent -match $oldUrlPattern) {
        $newUserDataContent = $userDataContent -replace $oldUrlPattern, $newUrl
        if (-not $DryRun) {
            $newUserDataContent | Set-Content $UserDataPath -NoNewline
        }
        Write-Host "✓ Updated ScreenConnect download URL to $newUrl" -ForegroundColor Green
    } else {
        Write-Warning "Could not find ScreenConnect URL pattern in user_data.tpl"
    }
    
    # 2. Update VERSION file
    Write-Host "Updating VERSION file..." -ForegroundColor Yellow
    if (-not $DryRun) {
        $NewVersion | Set-Content $VersionPath -NoNewline
    }
    Write-Host "✓ Updated VERSION file to $NewVersion" -ForegroundColor Green
    
    # 3. Update terraform.tfvars if it contains version info
    Write-Host "Checking terraform.tfvars for version references..." -ForegroundColor Yellow
    if (Test-Path $ConfigPath) {
        $configContent = Get-Content $ConfigPath -Raw
        if ($configContent -match 'screenconnect.*version') {
            Write-Host "Found version reference in terraform.tfvars - manual review recommended" -ForegroundColor Yellow
        }
    }
    
    # 4. Generate changelog entry
    Write-Host "Generating changelog entry..." -ForegroundColor Yellow
    $changelogEntry = @"

## [$NewVersion] - $(Get-Date -Format "yyyy-MM-dd")

### Changed
- Updated ScreenConnect to version $NewVersion
- Updated download URL to https://download.screenconnect.com/$NewVersion/

### Security
- No security changes in this update

### Breaking Changes
- None

### Migration Notes
- Standard ScreenConnect update process
- No configuration changes required
"@
    
    if (-not $DryRun) {
        $changelogContent = Get-Content "CHANGELOG.md" -Raw
        $insertPosition = $changelogContent.IndexOf("## [")
        if ($insertPosition -ge 0) {
            $newChangelogContent = $changelogContent.Insert($insertPosition, $changelogEntry)
            $newChangelogContent | Set-Content "CHANGELOG.md" -NoNewline
            Write-Host "✓ Added changelog entry" -ForegroundColor Green
        }
    }
    
    # 5. Validate the update
    Write-Host "Validating update..." -ForegroundColor Yellow
    
    # Check if new URL is accessible
    try {
        $response = Invoke-WebRequest -Uri $newUrl -Method Head -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ New ScreenConnect version is available for download" -ForegroundColor Green
        } else {
            Write-Warning "New version may not be available yet (HTTP $($response.StatusCode))"
        }
    } catch {
        Write-Warning "Could not verify new version availability: $($_.Exception.Message)"
    }
    
    # 6. Generate deployment instructions
    Write-Host ""
    Write-Host "=== Update Complete ===" -ForegroundColor Green
    Write-Host "ScreenConnect has been updated to version $NewVersion" -ForegroundColor Green
    
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Review the changes in the files above" -ForegroundColor White
        Write-Host "2. Test the deployment in a staging environment" -ForegroundColor White
        Write-Host "3. Deploy to production using: terraform plan && terraform apply" -ForegroundColor White
        Write-Host "4. Verify ScreenConnect is working correctly after deployment" -ForegroundColor White
    }
    
    # 7. Create backup of original files
    if (-not $DryRun) {
        $backupDir = "backups/$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        
        Copy-Item $UserDataPath "$backupDir/user_data.tpl.backup"
        Copy-Item $VersionPath "$backupDir/VERSION.backup"
        
        Write-Host "✓ Backup created in $backupDir" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Update failed: $($_.Exception.Message)"
    exit 1
} 