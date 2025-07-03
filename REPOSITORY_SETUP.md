# Oracle Cloud ScreenConnect Repository Setup Guide

This guide will help you create a new, standalone repository for the Oracle Cloud ScreenConnect deployment code.

## Repository Structure

```
oracle-cloud-screenconnect/
├── .github/
│   ├── workflows/
│   │   ├── validate.yml
│   │   ├── release.yml
│   │   └── security.yml
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       ├── feature_request.md
│       └── migration_request.md
├── docs/
│   ├── AWS_MIGRATION.md
│   ├── COST_ANALYSIS.md
│   ├── DEPLOYMENT_GUIDE.md
│   ├── SECURITY_GUIDE.md
│   └── UPDATE_GUIDE.md
├── environments/
│   ├── production/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars.example
│   │   └── terraform.tfvars.secure
│   ├── staging/
│   └── development/
├── modules/
│   ├── compute/
│   ├── networking/
│   ├── storage/
│   ├── vault/
│   └── cloudflare_dns/
├── scripts/
│   ├── aws-migration-assistant.ps1
│   ├── create-environment.ps1
│   ├── maintenance.ps1
│   ├── migration-plan.ps1
│   ├── release.ps1
│   ├── scheduled-backup.ps1
│   ├── setup-secure-config.ps1
│   ├── ssl-management.ps1
│   ├── update-screenconnect.ps1
│   ├── validate-deployment.ps1
│   ├── validate-prerequisites.ps1
│   └── validate-secrets.ps1
├── .gitignore
├── .gitattributes
├── LICENSE
├── README.md
├── CHANGELOG.md
├── VERSION
├── SECURITY_BEST_PRACTICES.md
└── UPDATE_GUIDE.md
```

## Step 1: Create New Repository

### Option A: GitHub CLI
```bash
# Create new repository
gh repo create oracle-cloud-screenconnect --public --description "Oracle Cloud ScreenConnect deployment with automated migration from AWS"

# Clone the new repository
git clone https://github.com/yourusername/oracle-cloud-screenconnect.git
cd oracle-cloud-screenconnect
```

### Option B: GitHub Web Interface
1. Go to https://github.com/new
2. Repository name: `oracle-cloud-screenconnect`
3. Description: `Oracle Cloud ScreenConnect deployment with automated migration from AWS`
4. Make it Public or Private as needed
5. Don't initialize with README (we'll copy the existing one)

## Step 2: Copy Files to New Repository

```bash
# From your current workspace
cp -r oracle-cloud-screenconnect/* /path/to/new/repo/
cp oracle-cloud-screenconnect/.gitignore /path/to/new/repo/
cp oracle-cloud-screenconnect/.vscode /path/to/new/repo/ 2>/dev/null || true
```

## Step 3: Update Repository-Specific Files

### Update README.md
Replace the repository URL and update any references to the old location.

### Create .gitattributes
```bash
# Create .gitattributes for better file handling
cat > .gitattributes << 'EOF'
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
EOF
```

### Create LICENSE (if not exists)
```bash
# Create MIT License
cat > LICENSE << 'EOF'
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
EOF
```

## Step 4: Create GitHub Workflows

### Create .github/workflows/validate.yml
```yaml
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
```

### Create .github/workflows/release.yml
```yaml
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
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        body: |
          Oracle Cloud ScreenConnect Deployment Release
          
          See CHANGELOG.md for detailed changes.
        draft: false
        prerelease: false
```

### Create .github/workflows/security.yml
```yaml
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
```

## Step 5: Create Issue Templates

### .github/ISSUE_TEMPLATE/bug_report.md
```markdown
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
```

### .github/ISSUE_TEMPLATE/feature_request.md
```markdown
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
```

### .github/ISSUE_TEMPLATE/migration_request.md
```markdown
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
```

## Step 6: Initialize Git and Push

```bash
# Initialize git repository
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

# Add remote origin (replace with your repository URL)
git remote add origin https://github.com/yourusername/oracle-cloud-screenconnect.git

# Push to main branch
git push -u origin main

# Create develop branch
git checkout -b develop
git push -u origin develop
```

## Step 7: Create First Release

```bash
# Create and push a tag for the first release
git tag -a v1.0.0 -m "Initial release: Oracle Cloud ScreenConnect deployment"
git push origin v1.0.0
```

## Step 8: Repository Settings

### Enable GitHub Features
1. Go to Settings > Features
2. Enable Issues
3. Enable Projects
4. Enable Wiki (optional)
5. Enable Discussions (optional)

### Set Up Branch Protection
1. Go to Settings > Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators

### Configure Security
1. Go to Settings > Security
2. Enable Dependabot alerts
3. Enable Code scanning
4. Enable Secret scanning

## Step 9: Update Documentation References

### Update README.md
- Replace any references to the old repository location
- Update installation instructions
- Verify all links work correctly

### Update Scripts
- Check for any hardcoded paths that need updating
- Verify all relative paths work in the new structure

## Step 10: Test the Repository

```bash
# Test Terraform configuration
cd environments/production
terraform init
terraform validate

# Test PowerShell scripts
powershell -ExecutionPolicy Bypass -File "../../scripts/validate-prerequisites.ps1"

# Test documentation links
# Verify all markdown links work correctly
```

## Repository Features

### Automated Workflows
- **Validation**: Terraform format and validation checks
- **Security**: Automated vulnerability scanning
- **Releases**: Automated release creation on tags

### Documentation
- **AWS Migration Guide**: Step-by-step migration instructions
- **Security Guide**: Best practices and security configuration
- **Cost Analysis**: Detailed cost breakdown and optimization
- **Deployment Guide**: Complete deployment instructions

### Scripts
- **Migration Tools**: AWS to Oracle Cloud migration assistance
- **Validation**: Pre-deployment validation and security checks
- **Maintenance**: Automated maintenance and updates
- **Environment Management**: Multi-environment support

### Security
- **Secrets Management**: Oracle Vault integration
- **Access Control**: IP-based RDP access
- **SSL/TLS**: Automatic certificate management
- **Audit Logging**: Complete audit trails

## Next Steps

1. **Customize**: Update repository name, description, and branding
2. **Configure**: Set up GitHub Actions secrets for Oracle Cloud credentials
3. **Document**: Add any project-specific documentation
4. **Test**: Verify all functionality works in the new repository
5. **Share**: Make the repository public or share with your team

## Support

For questions about the repository setup:
1. Check the documentation in the `docs/` directory
2. Review the issue templates for common questions
3. Create an issue for specific problems or feature requests 