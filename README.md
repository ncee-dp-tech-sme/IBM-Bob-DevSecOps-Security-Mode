# IBM-Bob-DevSecOps-Security-Mode

## Overview

The **DevSecOps Security Mode** is a specialized Bob mode designed for implementing and validating security controls in regulated banking environments. It provides comprehensive security assurance through a 5-stage control model that addresses TLS/mTLS configuration, OAuth 2.0 security, cryptographic analysis, and continuous compliance monitoring.

### Key Capabilities

- **TLS/mTLS Configuration & Validation** - Secure protocol implementation across the software lifecycle
- **OAuth 2.0 Security** - Authentication flow validation and security testing
- **Cryptographic Analysis** - Algorithm assessment and quantum-safe migration planning
- **Infrastructure-as-Code Security** - Scanning for Ansible, nginx, Apache configurations
- **Runtime Security Validation** - Live endpoint testing and continuous monitoring
- **Banking Compliance** - Audit-ready evidence generation and regulatory alignment

### 5-Stage Control Model

1. **Shift-Left Detection** - Early identification of security abstractions during development
2. **Cryptographic Visibility** - Build-time analysis of algorithms and libraries
3. **Deployment Validation** - Configuration verification before production
4. **Runtime Verification** - Live endpoint security testing
5. **Continuous Compliance** - Ongoing monitoring and drift detection

---
# DevSecOps Security Mode - Complete Setup Guide

## Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [Tool Installation](#tool-installation)
  - [Static Analysis Tools](#static-analysis-tools)
  - [Infrastructure-as-Code Scanners](#infrastructure-as-code-scanners)
  - [Cryptographic Analysis Tools](#cryptographic-analysis-tools)
  - [Runtime Validation Tools](#runtime-validation-tools)
  - [Secrets Detection Tools](#secrets-detection-tools)
- [Configuration](#configuration)
- [Mode Activation](#mode-activation)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Prerequisites

### Required Knowledge

- Understanding of TLS/mTLS protocols and certificate management
- Familiarity with OAuth 2.0 authentication flows
- Experience with CI/CD pipelines
- Basic knowledge of security scanning tools
- Understanding of Infrastructure-as-Code (Ansible, Terraform, Kubernetes)

### Access Requirements

- Administrative access to development and CI/CD environments
- Permissions to install security scanning tools
- Access to certificate management systems
- Network access to scan target endpoints
- (Optional) IBM Quantum Safe Explorer license for cryptographic analysis

### Environment Setup

- **Operating System**: Linux, macOS, or Windows with WSL2
- **Shell**: Bash or Zsh
- **Python**: 3.8 or higher
- **Node.js**: 16.x or higher (for some tools)
- **Docker**: 20.10 or higher (optional, for containerized tools)
- **Git**: 2.30 or higher

---

## System Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk Space**: 10 GB free space
- **Network**: Internet connectivity for tool downloads and updates

### Recommended Requirements

- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Disk Space**: 20+ GB free space
- **Network**: High-speed internet for scanning operations

---

## Tool Installation

### Static Analysis Tools

#### Semgrep

Semgrep is used for detecting security patterns and abstractions in source code.

**Installation via pip:**
```bash
pip install semgrep
```

**Installation via Homebrew (macOS):**
```bash
brew install semgrep
```

**Installation via Docker:**
```bash
docker pull returntocorp/semgrep
```

**Verification:**
```bash
semgrep --version
```

**Expected output:** `semgrep 1.x.x`

---

### Infrastructure-as-Code Scanners

#### Checkov

Checkov scans IaC files for security and compliance issues.

**Installation via pip:**
```bash
pip install checkov
```

**Installation via Homebrew (macOS):**
```bash
brew install checkov
```

**Installation via Docker:**
```bash
docker pull bridgecrew/checkov
```

**Verification:**
```bash
checkov --version
```

**Expected output:** `2.x.x`

#### KICS (Keeping Infrastructure as Code Secure)

KICS provides comprehensive IaC security scanning.

**Installation via Docker:**
```bash
docker pull checkmarx/kics:latest
```

**Installation via Binary (Linux/macOS):**
```bash
# Download latest release
curl -sfL 'https://raw.githubusercontent.com/Checkmarx/kics/master/install.sh' | bash

# Move to PATH
sudo mv ./bin/kics /usr/local/bin/kics
```

**Verification:**
```bash
kics version
```

#### tfsec

Terraform-specific security scanner.

**Installation via Homebrew (macOS):**
```bash
brew install tfsec
```

**Installation via Binary (Linux):**
```bash
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
```

**Verification:**
```bash
tfsec --version
```

---

### Cryptographic Analysis Tools

#### IBM Quantum Safe Explorer

IBM Quantum Safe Explorer simplifies the discovery and management of cryptographic vulnerabilities within enterprise applications by performing source code scanning to identify cryptographically relevant artifacts that may be vulnerable to quantum attacks. Explorer identifies all the relevant cryptographic asset types, variants, and primitives used within the supported programming languages.

**Installation:**

Work with your IBM representative to gain access to the files required to install IBM Quantum Safe Explorer.

**Prerequisites:**
- Apple M1 Max or Intel Core i9 minimum 16 GB RAM
- Oracle JDK or Open JDK 17.0.8 or higher
- Maven 3.6 or higher (for building Java projects)

**Installation Steps:**

1. **Install the Desktop Application:**
   - macOS: Double-click the `IBM Quantum Safe Explorer.pkg` installer
   - Windows: Double-click the `IBM Quantum Safe Explorer.exe` installer
   - Follow the prompts in the installer
   - Once installed, open Launchpad and click the IBM Quantum Safe application to launch the backend service

2. **Install the CLI:**
   
   Clone the CLI project from GitHub:
   ```bash
   git clone https://github.ibm.com/quantum-safe-engineering/quantum-safe-read-repos.git
   cd quantum-safe-read-repos/CLI
   chmod 777 *
   ```
   
   **Note:** You will need appropriate access credentials to clone the repository. Contact your IBM representative for access.

**Getting Started with CLI:**

The CLI-based workflow is recommended for CI/CD integration and automated scanning.

1. **Build Your Java Project:**
   
   Navigate to your project directory and build with Maven:
   ```bash
   mvn clean install && mvn dependency:copy-dependencies
   ```
   
   This creates:
   - `target/classes` - Compiled class files
   - `target/dependency` - All project dependencies

2. **Set Environment Variables:**
   
   ```bash
   export dependency_path=target/dependency
   export class_path=target/classes
   ```

3. **Execute CLI Scan:**
   
   Basic scan with dependencies:
   ```bash
   ./cli.sh -i /path/to/project -l .java -da \
            -cf "./target/classes;/path/to/project/target/dependency;" \
            -ef src/test
   ```
   
   **CLI Parameters:**
   - `-i`: Input project directory (required)
   - `-l`: Language filter, e.g., `.java` (required)
   - `-da`: Discovery analysis flag (required)
   - `-cf`: Class file path - semicolon-separated list of classes and dependencies (required)
   - `-ef`: Exclude folder, e.g., `src/test` (optional)

**CLI Usage Examples:**

**Example 1: Single Project Scan**
```bash
# Clone and build project
git clone https://github.com/Password4j/password4j-jca.git -b master
mvn -f password4j-jca/ clean install && mvn -f password4j-jca/ dependency:copy-dependencies

# Set paths
export dependency_path=target/dependency
export class_path=target/classes

# Execute scan
cd quantum-safe-read-repos/CLI
./cli.sh -i $(pwd)/../password4j-jca -l .java -da \
         -cf "./$class_path;$(pwd)/../password4j-jca/$dependency_path;" \
         -ef src/test
```

**Example 2: Multi-Project Scan with Shared Dependencies**
```bash
# Build first project
git clone https://github.com/Password4j/password4j-jca.git -b master
mvn -f password4j-jca/ clean install && mvn -f password4j-jca/ dependency:copy-dependencies

# Build second project
git clone https://github.com/NeilMadden/salty-coffee.git -b master
mvn -f salty-coffee/ clean install -DskipTests && mvn -f salty-coffee/ dependency:copy-dependencies

# Scan second project with dependencies from both projects
cd quantum-safe-read-repos/CLI
./cli.sh -i $(pwd)/../salty-coffee -l .java -da \
         -cf "./$class_path;$(pwd)/../salty-coffee/$dependency_path;$(pwd)/../password4j-jca/$dependency_path;" \
         -ef src/test
```

**Example 3: Automated Scan Script**
```bash
#!/bin/bash
# scan-project.sh

PROJECT_DIR=$1
PROJECT_NAME=$(basename $PROJECT_DIR)

# Build project
mvn -f $PROJECT_DIR clean install && mvn -f $PROJECT_DIR dependency:copy-dependencies

# Execute scan
cd quantum-safe-read-repos/CLI
./cli.sh -i $PROJECT_DIR -l .java -da \
         -cf "./target/classes;$PROJECT_DIR/target/dependency;" \
         -ef src/test

echo "Scan complete for $PROJECT_NAME"
```

4. **Analyze Results:**
   - The CLI generates scan results showing cryptographic inventory
   - Inspect the vulnerabilities within the code to plan for mitigation
   - Identify weak algorithms (MD5, SHA-1, DES, RSA key sizes)
   - Assess quantum risk for each cryptographic primitive
   - Generate cryptographic SBOM for supply chain security

**Additional Resources:**

- [IBM Quantum Safe Explorer Documentation](https://www.ibm.com/docs/en/quantum-safe-explorer)
- [FAQ Section](https://www.ibm.com/docs/en/quantum-safe-explorer/faq)
- [Troubleshooting Guide](https://www.ibm.com/docs/en/quantum-safe-explorer/troubleshooting)
- [IBM Quantum Safe Products Technical Support](https://www.ibm.com/quantum-safe/support)

---

### Runtime Validation Tools

#### testssl.sh

Comprehensive TLS/SSL testing tool for endpoint validation.

**Installation via Git:**
```bash
git clone --depth 1 https://github.com/drwetter/testssl.sh.git
cd testssl.sh
```

**Installation via Docker:**
```bash
docker pull drwetter/testssl.sh
```

**Verification:**
```bash
./testssl.sh --version
```

**Basic Usage:**
```bash
# Standard scan
./testssl.sh https://api.example.com

# JSON output for automation
./testssl.sh --jsonfile results.json https://api.example.com

# Severity filtering
./testssl.sh --severity HIGH https://api.example.com

# Scan multiple endpoints
./testssl.sh --parallel --file endpoints.txt
```

#### SSLyze

Fast Python-based TLS scanner with programmatic interface.

**Installation via pip:**
```bash
pip install sslyze
```

**Verification:**
```bash
sslyze --version
```

**Basic Usage:**
```bash
# Standard scan
sslyze --regular api.example.com:443

# JSON output
sslyze --json_out=results.json --regular api.example.com:443

# Certificate information
sslyze --certinfo api.example.com:443

# Security headers check
sslyze --http_headers api.example.com:443
```

#### OWASP ZAP

Dynamic Application Security Testing tool with OAuth support.

**Installation:**

Download from [https://www.zaproxy.org/download/](https://www.zaproxy.org/download/)

**Installation via Docker:**
```bash
docker pull owasp/zap2docker-stable
```

**Basic Usage:**
```bash
# Baseline scan
docker run -t owasp/zap2docker-stable zap-baseline.py -t https://api.example.com

# Full scan
docker run -t owasp/zap2docker-stable zap-full-scan.py -t https://api.example.com

# API scan
docker run -t owasp/zap2docker-stable zap-api-scan.py -t https://api.example.com/openapi.json
```

---

### Secrets Detection Tools

#### TruffleHog

Scans for accidentally committed secrets and credentials.

**Installation via pip:**
```bash
pip install truffleHog
```

**Installation via Docker:**
```bash
docker pull trufflesecurity/trufflehog
```

**Verification:**
```bash
trufflehog --version
```

**Basic Usage:**
```bash
# Scan git repository
trufflehog git https://github.com/your-org/your-repo

# Scan local directory
trufflehog filesystem /path/to/project

# JSON output
trufflehog git https://github.com/your-org/your-repo --json
```

#### git-secrets

Prevents committing secrets to git repositories.

**Installation via Homebrew (macOS):**
```bash
brew install git-secrets
```

**Installation via Git (Linux):**
```bash
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
sudo make install
```

**Setup for Repository:**
```bash
# Initialize in repository
cd /path/to/your/repo
git secrets --install

# Add AWS patterns
git secrets --register-aws

# Add custom patterns
git secrets --add 'password\s*=\s*.+'
git secrets --add 'api[_-]?key\s*=\s*.+'
```

#### detect-secrets

Detects secrets in code before they're committed.

**Installation via pip:**
```bash
pip install detect-secrets
```

**Setup:**
```bash
# Create baseline
detect-secrets scan > .secrets.baseline

# Audit findings
detect-secrets audit .secrets.baseline
```

---

## Configuration

### 1. Create Custom Semgrep Rules

Create directory structure:
```bash
mkdir -p .semgrep
```

Create `.semgrep/spring-security.yml`:
```yaml
rules:
  - id: spring-ssl-bundle-usage
    pattern: |
      spring.ssl.bundle.$BUNDLE
    message: |
      SSL bundle configuration detected. Verify:
      1. Certificate paths are correct
      2. TLS versions are approved (1.2+)
      3. Cipher suites are AEAD-based
      4. Runtime validation is performed
    severity: WARNING
    languages: [yaml]
    metadata:
      category: security
      technology: [spring-boot]
      cwe: "CWE-327: Use of a Broken or Risky Cryptographic Algorithm"
```

Create `.semgrep/oauth-patterns.yml`:
```yaml
rules:
  - id: oauth-redirect-uri-validation
    pattern-either:
      - pattern: |
          if ($URI.startsWith($REGISTERED)) { ... }
      - pattern: |
          if ($URI.contains($REGISTERED)) { ... }
    message: |
      Loose redirect URI validation detected. Use exact string matching only.
      Loose matching enables open redirect vulnerabilities.
    severity: ERROR
    languages: [java, javascript, typescript]
    metadata:
      category: security
      technology: [oauth2]
      cwe: "CWE-601: URL Redirection to Untrusted Site"
```

### 2. Configure Checkov

Create `.checkov.yml`:
```yaml
# Skip specific checks with justification
skip-check:
  - CKV_K8S_43  # Image should use digest
    # Justification: Using tags for development flexibility

soft-fail-checks:
  - CKV_K8S_14  # Image Tag should be fixed
    # Justification: Allow in non-production environments

framework:
  - kubernetes
  - ansible
  - dockerfile

output: json
compact: true
quiet: true
```

### 3. Configure Git Hooks

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash

echo "Running security checks..."

# Run Semgrep
echo "→ Running Semgrep..."
semgrep --config=.semgrep/ --severity=ERROR --severity=WARNING .
if [ $? -ne 0 ]; then
    echo "❌ Semgrep found security issues"
    exit 1
fi

# Run secrets detection
echo "→ Checking for secrets..."
git secrets --scan
if [ $? -ne 0 ]; then
    echo "❌ Secrets detected in commit"
    exit 1
fi

echo "✅ Security checks passed"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### 4. Create Endpoint List for Scanning

Create `endpoints.txt`:
```
https://api.example.com
https://app.example.com
https://admin.example.com
```

---

## Mode Activation

### Activating DevSecOps Security Mode

The mode is automatically available in Bob once the `.bobmodes` file is present in your project.

**To activate:**
1. Open Bob in your project
2. Type `/mode` or click the mode selector
3. Select "🔒 DevSecOps Security"

**Mode Capabilities:**
- ✅ Read all files
- ✅ Edit security configurations, IaC files, CI/CD workflows
- ✅ Execute commands
- ✅ Access MCP tools

**File Edit Permissions:**

The mode can edit files matching these patterns:
- `security/*` - Security-specific files
- `config/*.{yaml,yml,conf,properties}` - Configuration files
- `*.semgrep.yml` - Semgrep rule files
- `Dockerfile` - Container definitions
- `.github/workflows/*` - GitHub Actions workflows
- `ansible/*` - Ansible playbooks
- `nginx.conf`, `apache*.conf` - Web server configs
- `docs/security/*` - Security documentation
- `SECURITY.md`, `*.security.md` - Security documentation

---

## Usage Examples

### Example 1: Validate Spring Boot TLS Configuration

**Scenario:** Review a Spring Boot application's TLS configuration for security issues.

**Steps:**

1. **Activate DevSecOps Security Mode**

2. **Request Analysis:**
```
Analyze the Spring Boot application in ./src for TLS/mTLS security issues
```

3. **Mode Actions:**
   - Scans code with Semgrep for SSL bundle usage
   - Checks for hardcoded certificates
   - Validates TLS version configurations
   - Reviews cipher suite selections

4. **Expected Output:**
   - List of security abstractions requiring verification
   - Recommendations for explicit TLS configuration
   - Cipher suite improvements
   - Certificate management best practices

### Example 2: Scan Infrastructure-as-Code

**Scenario:** Validate Ansible playbooks and nginx configurations before deployment.

**Request:**
```
Scan the ansible/ directory and nginx.conf for security issues
```

**Mode Actions:**
- Runs Checkov on Ansible playbooks
- Validates nginx TLS directives
- Checks for weak protocol versions
- Verifies certificate path configurations

### Example 3: Runtime TLS Validation

**Scenario:** Validate live endpoints after deployment.

**Request:**
```
Validate TLS configuration for endpoints in endpoints.txt
```

**Mode Actions:**
- Executes testssl.sh against each endpoint
- Checks protocol versions (TLS 1.2/1.3 only)
- Validates cipher suites (AEAD only)
- Verifies certificate chains
- Checks HSTS headers

### Example 4: OAuth Security Review

**Scenario:** Review OAuth 2.0 implementation for security vulnerabilities.

**Request:**
```
Review OAuth 2.0 implementation in ./src/auth for security issues
```

**Mode Actions:**
- Scans for redirect URI validation issues
- Checks for PKCE implementation
- Validates token storage patterns
- Reviews scope management
- Identifies deprecated flows (implicit, password)

### Example 5: Cryptographic Analysis

**Scenario:** Analyze Java application for cryptographic risks using IBM Quantum Safe Explorer CLI.

**Request:**
```
Analyze my-java-app project for cryptographic vulnerabilities
```

**Mode Actions:**

1. **Build the Application:**
   ```bash
   cd my-java-app
   mvn clean install && mvn dependency:copy-dependencies
   ```

2. **Clone QSE CLI (if not already available):**
   ```bash
   git clone https://github.ibm.com/quantum-safe-engineering/quantum-safe-read-repos.git
   cd quantum-safe-read-repos/CLI
   chmod 777 *
   ```

3. **Execute Cryptographic Scan:**
   ```bash
   export dependency_path=target/dependency
   export class_path=target/classes
   
   ./cli.sh -i /path/to/my-java-app -l .java -da \
            -cf "./target/classes;/path/to/my-java-app/target/dependency;" \
            -ef src/test
   ```

4. **Analysis Results:**
   - Identifies weak algorithms (MD5, SHA-1, DES, 3DES)
   - Checks RSA key sizes (flags < 2048 bits)
   - Detects deprecated cryptographic APIs
   - Assesses quantum vulnerability risk
   - Generates cryptographic SBOM (Software Bill of Materials)
   - Pinpoints exact code locations for remediation

### Example 6: Complete CI/CD Integration

**Scenario:** Set up full security pipeline.

**Request:**
```
Create a GitHub Actions workflow for the 5-stage security control model
```

**Mode Creates:**

`.github/workflows/security-pipeline.yml`:
```yaml
name: DevSecOps Security Pipeline

on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  stage1-shift-left:
    name: Stage 1 - Shift-Left Detection
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Semgrep
        run: |
          pip install semgrep
          semgrep --config=.semgrep/ --severity=ERROR --severity=WARNING .
      
      - name: Run Checkov
        run: |
          pip install checkov
          checkov -d . --framework kubernetes ansible dockerfile
      
      - name: Scan for Secrets
        run: |
          pip install trufflehog
          trufflehog filesystem . --json

  stage2-crypto-analysis:
    name: Stage 2 - Cryptographic Visibility
    runs-on: ubuntu-latest
    needs: stage1-shift-left
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Build Application
        run: |
          mvn clean install && mvn dependency:copy-dependencies
      
      - name: Clone QSE CLI
        env:
          QSE_TOKEN: ${{ secrets.QSE_GITHUB_TOKEN }}
        run: |
          git clone https://${QSE_TOKEN}@github.ibm.com/quantum-safe-engineering/quantum-safe-read-repos.git
          cd quantum-safe-read-repos/CLI
          chmod 777 *
      
      - name: Run QSE Cryptographic Scan
        run: |
          export dependency_path=target/dependency
          export class_path=target/classes
          cd quantum-safe-read-repos/CLI
          ./cli.sh -i $GITHUB_WORKSPACE -l .java -da \
                   -cf "./$class_path;$GITHUB_WORKSPACE/$dependency_path;" \
                   -ef src/test
      
      - name: Upload Scan Results
        uses: actions/upload-artifact@v3
        with:
          name: qse-crypto-scan-results
          path: quantum-safe-read-repos/CLI/qs_scan_result/
      
      - name: Check for Critical Findings
        run: |
          # Parse scan results and fail if critical vulnerabilities found
          if grep -q "MD5\|SHA-1\|DES" quantum-safe-read-repos/CLI/qs_scan_result/*.json; then
            echo "❌ Critical cryptographic vulnerabilities detected"
            exit 1
          fi

  stage3-deployment-validation:
    name: Stage 3 - Deployment Validation
    runs-on: ubuntu-latest
    needs: stage2-crypto-analysis
    steps:
      - uses: actions/checkout@v3
      
      - name: Render Ansible Templates
        run: |
          ansible-playbook ansible/deploy.yml --check --diff
      
      - name: Validate Configurations
        run: |
          python3 scripts/validate-configs.py

  stage4-runtime-validation:
    name: Stage 4 - Runtime Validation
    runs-on: ubuntu-latest
    needs: stage3-deployment-validation
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Run testssl.sh
        run: |
          git clone --depth 1 https://github.com/drwetter/testssl.sh.git
          ./testssl.sh/testssl.sh --jsonfile tls-results.json \
                                   --severity HIGH \
                                   --file endpoints.txt
      
      - name: Run OWASP ZAP
        run: |
          docker run -t owasp/zap2docker-stable \
            zap-baseline.py -t https://api.example.com

  stage5-continuous-monitoring:
    name: Stage 5 - Continuous Compliance
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Schedule Monitoring
        run: |
          echo "Continuous monitoring configured"
          # Set up scheduled scans, alerting, etc.
```

---

## Troubleshooting

### Common Issues

#### Issue: Semgrep Not Finding Custom Rules

**Symptom:** Custom rules in `.semgrep/` are not being executed.

**Solution:**
```bash
# Verify rules directory exists
ls -la .semgrep/

# Test rule syntax
semgrep --validate --config=.semgrep/spring-security.yml

# Run with explicit config path
semgrep --config=.semgrep/ .
```

#### Issue: Checkov Failing on Valid Configurations

**Symptom:** Checkov reports false positives.

**Solution:**

Add exceptions to `.checkov.yml`:
```yaml
skip-check:
  - CKV_K8S_43  # With justification
```

Or use inline suppressions:
```yaml
# checkov:skip=CKV_K8S_43:Justification here
```

#### Issue: testssl.sh Connection Failures

**Symptom:** Cannot connect to endpoints.

**Solution:**
```bash
# Check network connectivity
curl -I https://api.example.com

# Verify DNS resolution
nslookup api.example.com

# Test with verbose output
./testssl.sh --debug 3 https://api.example.com

# Check for proxy requirements
export https_proxy=http://proxy.example.com:8080
```

#### Issue: IBM Quantum Safe Explorer Not Available

**Symptom:** QSE commands not found.

**Solution:**
- Verify QSE installation and licensing
- Check PATH configuration
- Contact IBM support for installation assistance
- Use alternative: Manual cryptographic review

#### Issue: Git Hooks Not Executing

**Symptom:** Pre-commit hooks don't run.

**Solution:**
```bash
# Verify hook exists and is executable
ls -la .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Test hook manually
.git/hooks/pre-commit

# Check git config
git config --get core.hooksPath
```

---

## Best Practices

### 1. Shift-Left Security

- **Run Semgrep locally** before committing code
- **Use pre-commit hooks** to catch issues early
- **Integrate into IDE** for real-time feedback
- **Review findings immediately** rather than batching

### 2. Cryptographic Standards

- **Use TLS 1.3** as the preferred protocol
- **TLS 1.2 minimum** for legacy compatibility
- **AEAD cipher suites only** (GCM, ChaCha20-Poly1305)
- **Disable CBC mode** ciphers completely
- **RSA 2048-bit minimum**, prefer 3072-bit or higher
- **Enable Perfect Forward Secrecy** (ECDHE)

### 3. OAuth Security

- **Use Authorization Code flow** with PKCE
- **Exact redirect URI matching** only
- **Short-lived access tokens** (15 minutes)
- **Refresh token rotation** enabled
- **Avoid implicit and password flows** (deprecated)
- **Implement proper scope management**

### 4. Certificate Management

- **Automate certificate renewal** (Let's Encrypt, ACME)
- **Monitor expiration dates** (alert 30 days before)
- **Use certificate pinning** for mobile apps
- **Validate certificate chains** in runtime tests
- **Store private keys securely** (HSM, vault)

### 5. Continuous Monitoring

- **Schedule daily TLS scans** of production endpoints
- **Track cryptographic posture** over time
- **Alert on configuration drift** immediately
- **Generate compliance reports** monthly
- **Review security findings** weekly

### 6. Documentation

- **Document all security decisions** and trade-offs
- **Maintain exception justifications** for skipped checks
- **Create runbooks** for incident response
- **Keep audit trail** of all security changes
- **Update security documentation** with each release

### 7. Tool Maintenance

- **Update security tools** monthly
- **Review and update custom rules** quarterly
- **Test tool configurations** after updates
- **Subscribe to security advisories** for tools
- **Maintain tool version inventory**

---

## Additional Resources

### Documentation

- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Checkov Documentation](https://www.checkov.io/documentation.html)
- [testssl.sh Documentation](https://testssl.sh/)
- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [IBM Quantum Safe Explorer](https://www.ibm.com/quantum-safe)

### Security Standards

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html)

### Training

- [OWASP Security Training](https://owasp.org/www-project-security-knowledge-framework/)
- [IBM Security Learning Academy](https://www.ibm.com/security/services/training)
- [SANS Security Training](https://www.sans.org/)

---

## Support

For issues or questions:

1. **Check this documentation** for common solutions
2. **Review tool-specific documentation** for detailed guidance
3. **Consult security team** for policy questions
4. **Open issue** in project repository for bugs

---

## License

This mode and documentation are part of the Bob AI assistant project. Refer to the main project license for terms and conditions.

---

**Last Updated:** 2026-06-05  
**Version:** 1.0.0  
**Maintained By:** DevSecOps Security Team
