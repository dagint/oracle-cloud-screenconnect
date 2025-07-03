# Oracle Cloud ScreenConnect Repository Setup Script
# This script helps create a new, standalone repository for the deployment code

param(
    [Parameter(Mandatory=$true)]
    [string]$NewRepoPath,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "oracle-cloud-screenconnect",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateGitHubRepo = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$InitializeGit = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateWorkflows = $true
)

# Function to write colored output
function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    
    $colors = @{
        "INFO" = "Cyan"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    $color = $colors[$Status]
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

Write-Status "Starting Oracle Cloud ScreenConnect repository setup..." "INFO"

# Validate inputs
if (-not (Test-Path $NewRepoPath)) {
    Write-Status "Creating new repository directory: $NewRepoPath" "INFO"
    New-Item -Path $NewRepoPath -ItemType Directory -Force | Out-Null
}

# Copy all files to new repository
Write-Status "Copying files to new repository..." "INFO"
$currentDir = Get-Location
$sourceDir = Join-Path $currentDir "oracle-cloud-screenconnect"

if (-not (Test-Path $sourceDir)) {
    Write-Status "Error: Source directory not found: $sourceDir" "ERROR"
    exit 1
}

# Copy all files and directories
Copy-Item -Path "$sourceDir\*" -Destination $NewRepoPath -Recurse -Force

# Create .gitattributes file
Write-Status "Creating .gitattributes file..." "INFO"
$gitattributes = @"
# Auto detect text files and perform LF normalization
* text=auto

# PowerShell scripts
*.ps1 text eol=crlf

# Terraform files
*.tf text
*.tfvars text
*.hcl text

# Documentation
*.md text
*.txt text

# Binary files
*.zip binary
*.exe binary
*.msi binary
*.pem binary
*.key binary
"@

Set-Content -Path (Join-Path $NewRepoPath ".gitattributes") -Value $gitattributes

# Create LICENSE file if it doesn't exist
$licensePath = Join-Path $NewRepoPath "LICENSE"
if (-not (Test-Path $licensePath)) {
    Write-Status "Creating MIT LICENSE file..." "INFO"
    $license = @"
MIT License

Copyright (c) 2024 Oracle Cloud ScreenConnect Deployment

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
    Set-Content -Path $licensePath -Value $license
}

# Create GitHub workflows if requested
if ($CreateWorkflows) {
    Write-Status "Creating GitHub workflows..." "INFO"
    $workflowsDir = Join-Path $NewRepoPath ".github\workflows"
    New-Item -Path $workflowsDir -ItemType Directory -Force | Out-Null
    
    # Validate workflow
    $validateWorkflow = @"
name: Validate Terraform Configuration

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: "1.5.0"
    
    - name: Terraform Format Check
      run: terraform fmt -check -recursive
    
    - name: Terraform Init
      run: |
        cd environments/production
        terraform init -backend=false
    
    - name: Terraform Validate
      run: |
        cd environments/production
        terraform validate
"@
    Set-Content -Path (Join-Path $workflowsDir "validate.yml") -Value $validateWorkflow
    
    # Release workflow
    $releaseWorkflow = @"
name: Create Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: `${{ github.ref }}
        release_name: Release `${{ github.ref }}
        body: |
          Oracle Cloud ScreenConnect Deployment Release
          
          See CHANGELOG.md for detailed changes.
        draft: false
        prerelease: false
"@
    Set-Content -Path (Join-Path $workflowsDir "release.yml") -Value $releaseWorkflow
    
    # Security workflow
    $securityWorkflow = @"
name: Security Scan

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
"@
    Set-Content -Path (Join-Path $workflowsDir "security.yml") -Value $securityWorkflow
    
    # Create issue templates
    $issueTemplatesDir = Join-Path $NewRepoPath ".github\ISSUE_TEMPLATE"
    New-Item -Path $issueTemplatesDir -ItemType Directory -Force | Out-Null
    
    $bugTemplate = @"
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment:**
 - OS: [e.g. Windows Server 2022]
 - ScreenConnect Version: [e.g. 24.1.0.8811]
 - Oracle Cloud Region: [e.g. us-ashburn-1]

**Additional context**
Add any other context about the problem here.
"@
    Set-Content -Path (Join-Path $issueTemplatesDir "bug_report.md") -Value $bugTemplate
    
    $featureTemplate = @"
---
name: Feature request
about: Suggest an idea for this project
title: ''
labels: 'enhancement'
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
"@
    Set-Content -Path (Join-Path $issueTemplatesDir "feature_request.md") -Value $featureTemplate
    
    $migrationTemplate = @"
---
name: Migration request
about: Request help with AWS to Oracle Cloud migration
title: ''
labels: 'migration, help wanted'
assignees: ''

---

**Current Environment**
- Cloud Provider: [e.g. AWS]
- ScreenConnect Version: [e.g. 24.1.0.8811]
- Customizations: [e.g. Custom themes, SSL certificates, etc.]

**Target Environment**
- Oracle Cloud Region: [e.g. us-ashburn-1]
- Domain: [e.g. remotesupport.yourdomain.com]
- Special Requirements: [e.g. High availability, specific compliance]

**Migration Questions**
1. [Your specific question]
2. [Another question]

**Additional Information**
Any other details that might help with the migration planning.
"@
    Set-Content -Path (Join-Path $issueTemplatesDir "migration_request.md") -Value $migrationTemplate
}

# Create GitHub repository if requested
if ($CreateGitHubRepo) {
    Write-Status "Creating GitHub repository..." "INFO"
    
    # Check if GitHub CLI is installed
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Status "GitHub CLI not found. Please install it first:" "WARNING"
        Write-Status "https://cli.github.com/" "WARNING"
        Write-Status "Or create the repository manually at https://github.com/new" "WARNING"
    } else {
        try {
            $repoUrl = "https://github.com/$GitHubUsername/$RepositoryName"
            gh repo create $RepositoryName --public --description "Oracle Cloud ScreenConnect deployment with automated migration from AWS"
            Write-Status "GitHub repository created: $repoUrl" "SUCCESS"
        } catch {
            Write-Status "Failed to create GitHub repository: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Initialize Git repository if requested
if ($InitializeGit) {
    Write-Status "Initializing Git repository..." "INFO"
    
    # Change to new repository directory
    Push-Location $NewRepoPath
    
    try {
        # Initialize git
        git init
        
        # Add all files
        git add .
        
        # Create initial commit
        git commit -m "Initial commit: Oracle Cloud ScreenConnect deployment

- Complete Terraform infrastructure as code
- Automated migration tools from AWS
- Comprehensive documentation and guides
- Security best practices and validation
- Multi-environment support"
        
        # Add remote origin if GitHub repo was created
        if ($CreateGitHubRepo) {
            $repoUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
            git remote add origin $repoUrl
            Write-Status "Git remote added: $repoUrl" "SUCCESS"
        }
        
        Write-Status "Git repository initialized successfully" "SUCCESS"
        
    } catch {
        Write-Status "Failed to initialize Git repository: $($_.Exception.Message)" "ERROR"
    } finally {
        Pop-Location
    }
}

# Update README with new repository information
Write-Status "Updating README with repository information..." "INFO"
$readmePath = Join-Path $NewRepoPath "README.md"
if (Test-Path $readmePath) {
    $readmeContent = Get-Content $readmePath -Raw
    $readmeContent = $readmeContent -replace "oracle-cloud-screenconnect", $RepositoryName
    Set-Content -Path $readmePath -Value $readmeContent
}

Write-Status "Repository setup completed successfully!" "SUCCESS"
Write-Status "" "INFO"
Write-Status "Next steps:" "INFO"
Write-Status "1. Review the copied files in: $NewRepoPath" "INFO"
Write-Status "2. Update any hardcoded paths or references" "INFO"
Write-Status "3. Test the Terraform configuration" "INFO"
Write-Status "4. Push to GitHub if remote was added" "INFO"
Write-Status "5. Create your first release" "INFO"
Write-Status "" "INFO"
Write-Status "For detailed instructions, see: REPOSITORY_SETUP.md" "INFO" 