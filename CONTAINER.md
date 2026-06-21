# DevSecOps Security Mode — Container Toolbox

Run all DevSecOps security scanning tools in a single container — no local installs required beyond **Podman**.

---

## What's Inside the Image

| Tool | Version | Purpose |
|------|---------|---------|
| `semgrep` | latest | Static analysis — security pattern detection in source code |
| `checkov` | latest | IaC scanner — Terraform, Ansible, Kubernetes, CloudFormation |
| `kics` | latest | IaC scanner — comprehensive multi-framework IaC scanning |
| `tfsec` | latest | Terraform-specific security scanner |
| `sslyze` | latest | TLS/SSL certificate and configuration analyser |
| `testssl.sh` | latest | TLS/SSL endpoint protocol and cipher tester |
| `trufflehog` | v3 latest | Secrets detection in git repos and filesystems |
| `detect-secrets` | latest | Pre-commit secrets baseline management |
| `git-secrets` | latest | Git hook-based secret leak prevention |

> **IBM Quantum Safe Explorer** and **OWASP ZAP** require a separate full runtime environment (JVM / dedicated daemon) and cannot be bundled into this image. See the main [README](README.md) for their installation instructions.

---

## Prerequisites

Only **Podman** needs to be installed on your host machine.

### macOS
```bash
brew install podman
podman machine init
podman machine start
```

### Linux
Follow the official guide: [https://podman.io/getting-started/installation](https://podman.io/getting-started/installation)

### Verify Podman is running
```bash
podman info
```

---

## Quick Start

### 1. Clone the repository
```bash
git clone <this-repo>
cd IBM-Bob-DevSecOps-Security-Mode
```

### 2. Make scripts executable
```bash
chmod +x scan.sh entrypoint.sh
```

### 3. Build the image
```bash
./scan.sh --build
```

This builds the `devsecops-tools` image locally. It takes a few minutes on first build. All subsequent runs use the cached image.

### 4. Run your first scan
```bash
# Scan current directory with Semgrep
./scan.sh semgrep --config auto .

# Scan IaC files with Checkov
./scan.sh checkov -d .

# Test TLS of a remote endpoint
./scan.sh testssl https://api.example.com
```

---

## Usage

```
./scan.sh <tool> [tool-arguments]
./scan.sh --build          # (Re)build the container image
./scan.sh help             # Show available tools
```

### How paths work

- Your **current working directory** is automatically mounted into the container as `/scan/project`.
- A `scan-results/` directory is created in your current directory and mounted as `/scan/results` for output files.
- You can pass paths relative to your current directory — they just work.

```
Host:                          Container:
./my-project/        ──────►  /scan/project/
./scan-results/      ──────►  /scan/results/
```

---

## Tool Examples

### Semgrep — Static Analysis

```bash
# Auto-detect rules for the current project
./scan.sh semgrep --config auto .

# Use specific ruleset
./scan.sh semgrep --config p/owasp-top-ten .

# Use custom rules from within your project
./scan.sh semgrep --config .semgrep/ .

# JSON output into scan-results/
./scan.sh semgrep --config auto --json -o scan-results/semgrep.json .
```

### Checkov — IaC Scanner

```bash
# Scan all IaC in current directory
./scan.sh checkov -d .

# Scan specific framework only
./scan.sh checkov -d . --framework terraform
./scan.sh checkov -d . --framework ansible
./scan.sh checkov -d . --framework kubernetes

# JSON report
./scan.sh checkov -d . -o json --output-file-path scan-results/

# Skip a specific check
./scan.sh checkov -d . --skip-check CKV_AWS_20
```

### KICS — IaC Scanner

```bash
# Scan current directory
./scan.sh kics scan -p . -o scan-results/

# Scan with specific query type
./scan.sh kics scan -p . -t "Terraform" -o scan-results/

# JSON output
./scan.sh kics scan -p . --report-formats json -o scan-results/
```

### tfsec — Terraform Scanner

```bash
# Scan current directory
./scan.sh tfsec .

# JSON output
./scan.sh tfsec . --format json > scan-results/tfsec.json

# Show only HIGH and CRITICAL
./scan.sh tfsec . --minimum-severity HIGH
```

### testssl.sh — TLS/SSL Endpoint Scanner

> Requires network access — `scan.sh` automatically adds `--network host` for this tool.

```bash
# Full TLS scan
./scan.sh testssl https://api.example.com

# JSON output
./scan.sh testssl --jsonfile scan-results/testssl.json https://api.example.com

# Check only severity HIGH and above
./scan.sh testssl --severity HIGH https://api.example.com

# Scan multiple endpoints from a file
./scan.sh testssl --parallel --file endpoints.txt
```

### SSLyze — TLS Certificate Analyser

> Requires network access — `scan.sh` automatically adds `--network host` for this tool.

```bash
# Standard scan
./scan.sh sslyze api.example.com:443

# JSON output
./scan.sh sslyze --json_out=scan-results/sslyze.json api.example.com:443

# Certificate info
./scan.sh sslyze --certinfo api.example.com:443

# Check OCSP stapling and HTTP headers
./scan.sh sslyze --certinfo --http_headers api.example.com:443
```

### TruffleHog — Secrets Detection

```bash
# Scan git repository (remote)
./scan.sh trufflehog git https://github.com/your-org/your-repo

# Scan current directory filesystem
./scan.sh trufflehog filesystem .

# JSON output
./scan.sh trufflehog filesystem . --json > scan-results/trufflehog.json

# Scan only verified secrets
./scan.sh trufflehog filesystem . --only-verified
```

### detect-secrets — Secrets Baseline

```bash
# Create a baseline of known secrets (run once per repo)
./scan.sh detect-secrets scan . > .secrets.baseline

# Audit findings interactively
./scan.sh detect-secrets audit .secrets.baseline

# Scan and compare against baseline
./scan.sh detect-secrets scan . | ./scan.sh detect-secrets audit --diff .secrets.baseline
```

### git-secrets — Git Hook Integration

```bash
# Register AWS patterns
./scan.sh git-secrets --register-aws

# Scan entire repository history
./scan.sh git-secrets --scan-history

# Add a custom forbidden pattern
./scan.sh git-secrets --add 'password\s*=\s*.+'
```

---

## Output Files

All tools that produce file output write into `./scan-results/` in your current directory. This directory is created automatically on every `./scan.sh` run.

```
./scan-results/
├── semgrep.json
├── checkov/
├── kics/
├── tfsec.json
├── testssl.json
└── sslyze.json
```

---

## Rebuilding the Image

Rebuild after pulling updated tool versions or after modifying `Containerfile`:

```bash
./scan.sh --build
```

To force a clean rebuild with no layer cache:

```bash
podman build --no-cache -t devsecops-tools -f Containerfile .
```

---

## File Reference

| File | Purpose |
|------|---------|
| [`Containerfile`](Containerfile) | Image definition — installs all tools |
| [`entrypoint.sh`](entrypoint.sh) | In-container dispatcher — routes `$1` to the correct tool |
| [`scan.sh`](scan.sh) | Host-side wrapper — handles mounts, path rewriting, and `podman run` |

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `Podman is not installed or not in PATH` | Install Podman and start the machine (macOS: `podman machine start`) |
| `Image 'devsecops-tools' not found` | Run `./scan.sh --build` — the script also auto-builds on first use |
| `permission denied` on `scan.sh` | Run `chmod +x scan.sh entrypoint.sh` |
| `KICS` binary not found during build | GitHub API rate limit hit — retry after a few minutes |
| Network tools (testssl, sslyze) can't reach host | Already handled via `--network host`; check firewall/VPN settings |
| Scan results directory is empty | Pass an explicit output path: `-o scan-results/` in the tool arguments |
| `z` flag error on volume mount | On SELinux systems the `:z` relabel flag is required and already set in `scan.sh` |
