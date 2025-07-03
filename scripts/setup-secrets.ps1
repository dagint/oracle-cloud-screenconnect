# Oracle Cloud Vault Secrets Setup
# This script creates secrets in Oracle Vault for secure credential storage

param(
    [Parameter(Mandatory=$true)]
    [string]$CompartmentId,
    
    [Parameter(Mandatory=$true)]
    [string]$VaultId,
    
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$true)]
    [string]$Namespace,
    
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPassword = "",
    
    [Parameter(Mandatory=$false)]
    [string]$SecretPrefix = "screenconnect-backup"
)

# Function to write logs
function Write-Log {
    param($Message)
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Output $logMessage
}

Write-Log "Setting up Oracle Vault secrets for ScreenConnect backup credentials"

# Check if OCI CLI is installed
if (-not (Get-Command oci -ErrorAction SilentlyContinue)) {
    Write-Log "ERROR: Oracle Cloud CLI (oci) not found"
    Write-Log "Please install OCI CLI from: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
}

# Function to create or update secret
function Set-OracleSecret {
    param(
        [string]$SecretName,
        [string]$SecretValue,
        [string]$Description
    )
    
    try {
        # Check if secret already exists
        $existingSecret = oci vault secret list --compartment-id $CompartmentId --vault-id $VaultId --query "data[?display-name=='$SecretName'].id" --raw-output
        
        if ($existingSecret) {
            Write-Log "Secret '$SecretName' already exists. Updating..."
            
            # Create temporary file for secret content
            $tempFile = [System.IO.Path]::GetTempFileName()
            $SecretValue | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
            
            # Update existing secret
            oci vault secret update-bundle --secret-id $existingSecret --secret-bundle-content-content $tempFile --description $Description
            
            Remove-Item $tempFile -Force
            Write-Log "Secret '$SecretName' updated successfully"
        } else {
            Write-Log "Creating new secret: $SecretName"
            
            # Create temporary file for secret content
            $tempFile = [System.IO.Path]::GetTempFileName()
            $SecretValue | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
            
            # Create new secret
            oci vault secret create --compartment-id $CompartmentId --vault-id $VaultId --display-name $SecretName --description $Description --secret-bundle-content-content $tempFile
            
            Remove-Item $tempFile -Force
            Write-Log "Secret '$SecretName' created successfully"
        }
    } catch {
        Write-Log "ERROR: Failed to create/update secret '$SecretName': $_"
        exit 1
    }
}

# Create secrets
$secrets = @(
    @{
        Name = "$SecretPrefix-bucket-name"
        Value = $BucketName
        Description = "Oracle Object Storage bucket name for ScreenConnect backups"
    },
    @{
        Name = "$SecretPrefix-namespace"
        Value = $Namespace
        Description = "Oracle Object Storage namespace for ScreenConnect backups"
    },
    @{
        Name = "$SecretPrefix-region"
        Value = $Region
        Description = "Oracle Cloud region for ScreenConnect backups"
    }
)

# Add backup password if provided
if ($BackupPassword) {
    $secrets += @{
        Name = "$SecretPrefix-backup-password"
        Value = $BackupPassword
        Description = "Password for encrypted ScreenConnect backups"
    }
}

# Create each secret
foreach ($secret in $secrets) {
    Set-OracleSecret -SecretName $secret.Name -SecretValue $secret.Value -Description $secret.Description
}

# List created secrets
Write-Log ""
Write-Log "=== CREATED SECRETS ==="
try {
    $createdSecrets = oci vault secret list --compartment-id $CompartmentId --vault-id $VaultId --query "data[?contains(display-name, '$SecretPrefix')].{name: display-name, description: description}" --output table
    Write-Log $createdSecrets
} catch {
    Write-Log "ERROR: Failed to list secrets: $_"
}

Write-Log ""
Write-Log "=== SECRET MANAGEMENT COMMANDS ==="
Write-Log "List all secrets: oci vault secret list --compartment-id $CompartmentId --vault-id $VaultId"
Write-Log "Get secret value: oci vault secret get --secret-id <secret-id>"
Write-Log "Update secret: oci vault secret update-bundle --secret-id <secret-id> --secret-bundle-content-content <file-path>"
Write-Log "Delete secret: oci vault secret delete --secret-id <secret-id> --force"
Write-Log ""

Write-Log "Oracle Vault secrets setup completed successfully!"
Write-Log "You can now use the updated backup scripts that retrieve credentials from Oracle Vault" 