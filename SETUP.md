# DevSecOps Security Mode — Setup Guide

`setup.sh` is an interactive installer that sets up all tools required for the IBM Bob DevSecOps Security Mode on **macOS** and **Linux**.

---

## Prerequisites

| Requirement | macOS | Linux |
|-------------|-------|-------|
| Python 3 | Required (install via `brew install python` if missing) | Required (install via `apt-get install python3` or equivalent) |
| Homebrew | Recommended — script will offer to install if missing | Not applicable |
| Git | Required for some Linux binary installs | Required |
| Internet access | Required | Required |

> **Note:** Some Linux install steps use `sudo` for system-wide placement of binaries (e.g. `git-secrets`). You will be prompted by sudo as needed.

---

## Usage

Clone or download this repository, then run:

```bash
cd IBM-Bob-DevSecOps-Security-Mode
chmod +x setup.sh
./setup.sh
```

The script is compatible with both **Bash** and **ZSH** on macOS and Linux.

---

## What the Script Does

The script walks you through the following stages in order. At each interactive prompt, answer `y` (yes) or `n` (no).

### 1. Confirmation

Prints a summary of all planned actions and asks for confirmation before doing anything. You can safely abort here with no changes made.

### 2. OS Detection

Detects whether you are running **macOS** or **Linux** and adjusts all install methods accordingly. Unsupported operating systems will cause the script to exit with an error.

### 3. Python Check

Looks for `python3` or `python` in your `PATH`.

- If found — continues and reports the version.
- If **not found** — prints platform-specific install instructions and **exits**. Install Python first, then re-run the script.

### 4. Homebrew Check *(macOS only)*

Checks whether `brew` is available.

- If found — continues.
- If **not found** — shows the Homebrew install command and offers to install it automatically. If you decline or the install needs a shell restart, Homebrew-dependent tool steps are skipped (you can install those tools manually later).

### 5. Python Virtual Environment *(optional)*

Asks whether to create a virtual environment at `./.venv-devsecops`.

| Choice | Result |
|--------|--------|
| **Yes** | Creates `.venv-devsecops` (or reuses it if it already exists) and activates it for the rest of the script run. All Python packages are installed inside it. |
| **No** | Python packages are installed into the system Python. |

> To activate the virtual environment in future terminal sessions:
> ```bash
> source .venv-devsecops/bin/activate
> ```

### 6. Python Packages *(always installed)*

The following packages are installed via `pip` without prompting — they are always required:

| Package | Purpose |
|---------|---------|
| `semgrep` | Static analysis — detects security patterns in source code |
| `checkov` | IaC scanner — security and compliance checks for Terraform, Ansible, etc. |
| `sslyze` | TLS scanner — fast programmatic TLS/certificate analysis |
| `truffleHog` | Secrets detection — scans git history and filesystems for leaked credentials |
| `detect-secrets` | Pre-commit secrets baseline — prevents secrets from being committed |

### 7. CLI Tool Installation *(per-tool prompt)*

Each tool below is checked for an existing install first. If already present it is skipped. Otherwise you are asked whether to install it.

#### tfsec — Terraform IaC security scanner

| OS | Install method |
|----|---------------|
| macOS | `brew install tfsec` |
| Linux | Upstream binary install script via `curl` |

#### testssl.sh — TLS/SSL endpoint scanner

| OS | Install method |
|----|---------------|
| macOS | `brew install testssl` |
| Linux | `git clone` of the testssl.sh repository into `./testssl.sh/` |

> On Linux, run scans with: `./testssl.sh/testssl.sh <hostname>`

#### git-secrets — Secret leak prevention for git

| OS | Install method |
|----|---------------|
| macOS | `brew install git-secrets` |
| Linux | `git clone` + `sudo make install` |

After install, initialise it in each repository you want to protect:
```bash
cd /path/to/your/repo
git secrets --install
git secrets --register-aws   # add AWS credential patterns
```

### 8. Podman Container Images *(per-image prompt)*

Each image is pulled only if **Podman is already installed** on your system. If Podman is not found, the pull is skipped with a warning and you are reminded to install Podman at the end.

| Image | Tool | Purpose |
|-------|------|---------|
| `checkmarx/kics:latest` | KICS | IaC security scanning |
| `owasp/zap2docker-stable` | OWASP ZAP | DAST and OAuth flow validation |
| `returntocorp/semgrep` | Semgrep | Container-based static analysis |
| `bridgecrew/checkov` | Checkov | Container-based IaC scanning |
| `trufflesecurity/trufflehog` | TruffleHog | Container-based secrets scanning |

---

## Manual Steps After Running the Script

The script will remind you of these at the end, but they cannot be automated:

### Podman

Podman must be installed separately to use any container-based tool.

**macOS:**
```bash
brew install podman
podman machine init
podman machine start
```

**Linux:**
See the official guide: [https://podman.io/getting-started/installation](https://podman.io/getting-started/installation)

### IBM Quantum Safe Explorer

This tool requires a **commercial IBM license** and cannot be installed automatically.

- Contact your **IBM representative** to obtain the installer and access credentials.
- Documentation: [https://www.ibm.com/docs/en/quantum-safe-explorer](https://www.ibm.com/docs/en/quantum-safe-explorer)
- Support: [https://www.ibm.com/quantum-safe/support](https://www.ibm.com/quantum-safe/support)

---

## Verifying the Installation

After the script completes, verify each tool with these commands:

```bash
# Python packages
semgrep --version
checkov --version
sslyze --version
trufflehog --version
detect-secrets --version

# CLI tools
tfsec --version
testssl --version          # macOS
./testssl.sh/testssl.sh --version  # Linux

# Podman images
podman images

# git-secrets
git secrets --list
```

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| `Python is not installed or not in PATH` | Install Python 3 and re-run the script |
| `Homebrew installation may need a shell restart` | Open a new terminal window, then re-run `./setup.sh` |
| `Podman is not installed — cannot pull image` | Install Podman first (see above), then pull images manually with `podman pull <image>` |
| `pip install failed` | Check network access; try running `pip install <package>` manually to see the full error |
| `sudo make install` fails for git-secrets | Ensure `make` is installed: `sudo apt-get install build-essential` (Debian/Ubuntu) |
| Virtual environment not active after script | Run `source .venv-devsecops/bin/activate` in your terminal |

---

## Full Capabilities Checklist

To use the IBM Bob DevSecOps Security Mode to its full capabilities, ensure the following are all in place:

- [ ] Python packages installed (`semgrep`, `checkov`, `sslyze`, `truffleHog`, `detect-secrets`)
- [ ] `tfsec` installed and in PATH
- [ ] `testssl.sh` installed and accessible
- [ ] `git-secrets` installed and initialised in target repositories
- [ ] **Podman installed and running** with required images pulled
- [ ] **IBM Quantum Safe Explorer** installed with valid IBM license
