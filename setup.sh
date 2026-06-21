#!/usr/bin/env bash
# setup.sh — DevSecOps Security Mode tool installer
# Created: installs Python packages, optional venv, and per-tool CLI/Podman installs
# for the IBM Bob DevSecOps Security Mode on macOS and Linux.

set -euo pipefail

# ─── Colours ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
header()  { echo -e "\n${BOLD}━━━  $*  ━━━${RESET}"; }

# ─── Prompt helper ──────────────────────────────────────────────────────────
# ask <question>  →  returns 0 for yes, 1 for no
ask() {
    local answer
    while true; do
        read -r -p "$(echo -e "${BOLD}$1${RESET} [y/n]: ")" answer
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     echo "Please answer y or n." ;;
        esac
    done
}

# ─── Summary & confirmation ──────────────────────────────────────────────────
header "IBM Bob DevSecOps Security Mode — Setup"
echo ""
echo "  This script will:"
echo "   1. Optionally create and activate a Python virtual environment"
echo "   2. Install Python security packages (semgrep, checkov, sslyze,"
echo "      truffleHog, detect-secrets)"
echo "   3. Prompt per additional tool (tfsec, testssl, git-secrets,"
echo "      KICS, OWASP ZAP, TruffleHog container, Semgrep container)"
echo "      and install if requested"
echo ""
warn "No data will be deleted. However some steps require sudo for system-wide installs."
echo ""
if ! ask "Continue with setup?"; then
    echo "Aborted."; exit 0
fi

# ─── Detect OS ───────────────────────────────────────────────────────────────
header "Detecting OS"
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    success "Detected macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    success "Detected Linux"
else
    error "Unsupported OS: $OSTYPE"; exit 1
fi

# ─── Check Python ────────────────────────────────────────────────────────────
header "Checking Python"
PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PYTHON="$cmd"
        break
    fi
done

if [[ -z "$PYTHON" ]]; then
    error "Python is not installed or not in PATH."
    if [[ "$OS" == "macos" ]]; then
        echo "  Install it via Homebrew:  brew install python"
    else
        echo "  Install it via your package manager, e.g.: sudo apt-get install python3"
    fi
    exit 1
fi

PYTHON_VERSION=$($PYTHON --version 2>&1)
success "Found: $PYTHON_VERSION  ($(command -v "$PYTHON"))"

# ─── Check / install Homebrew (macOS only) ───────────────────────────────────
BREW_OK=false
if [[ "$OS" == "macos" ]]; then
    header "Checking Homebrew"
    if command -v brew &>/dev/null; then
        success "Homebrew found: $(brew --version | head -1)"
        BREW_OK=true
    else
        warn "Homebrew is not installed."
        echo ""
        echo "  Homebrew is required to install CLI tools on macOS."
        echo "  Install it by running:"
        echo ""
        echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        if ask "Install Homebrew now?"; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Re-check after install
            if command -v brew &>/dev/null; then
                success "Homebrew installed successfully."
                BREW_OK=true
            else
                warn "Homebrew installation may need a shell restart. CLI tool installs via brew will be skipped."
            fi
        else
            warn "Skipping Homebrew install. CLI tool installs via brew will be skipped."
        fi
    fi
fi

# ─── Virtual environment ─────────────────────────────────────────────────────
header "Python Virtual Environment"
VENV_DIR=".venv-devsecops"
VENV_ACTIVE=false

if ask "Create and activate a Python virtual environment in './$VENV_DIR'?"; then
    if [[ -d "$VENV_DIR" ]]; then
        warn "Directory '$VENV_DIR' already exists — reusing it."
    else
        $PYTHON -m venv "$VENV_DIR"
        success "Virtual environment created: $VENV_DIR"
    fi
    # Activate
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
    PYTHON="python"
    VENV_ACTIVE=true
    success "Virtual environment activated."
else
    info "Skipping virtual environment — using system Python."
fi

PIP="$PYTHON -m pip"

# ─── Python packages ─────────────────────────────────────────────────────────
header "Installing Python Packages"
echo "  Packages: semgrep, checkov, sslyze, truffleHog, detect-secrets"
echo ""

$PIP install --upgrade pip --quiet
for pkg in semgrep checkov sslyze truffleHog detect-secrets; do
    info "Installing $pkg ..."
    $PIP install "$pkg" --quiet && success "$pkg installed." || warn "$pkg install failed — check pip output above."
done

# ─── Per-tool CLI installs ────────────────────────────────────────────────────

# Helper: install via brew (macOS) or binary script (Linux)
install_tfsec() {
    if [[ "$OS" == "macos" ]]; then
        if $BREW_OK; then
            brew install tfsec && success "tfsec installed via Homebrew."
        else
            warn "Homebrew not available — cannot install tfsec. Install manually: https://github.com/aquasecurity/tfsec/releases"
        fi
    else
        info "Installing tfsec via binary script ..."
        curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
        success "tfsec installed."
    fi
}

install_testssl() {
    if [[ "$OS" == "macos" ]]; then
        if $BREW_OK; then
            brew install testssl && success "testssl installed via Homebrew."
        else
            warn "Homebrew not available — cannot install testssl. Clone manually: https://github.com/drwetter/testssl.sh"
        fi
    else
        if [[ -d "testssl.sh" ]]; then
            warn "testssl.sh directory already exists — skipping clone."
        else
            git clone --depth 1 https://github.com/drwetter/testssl.sh.git
            success "testssl.sh cloned to ./testssl.sh"
        fi
        info "Run testssl with: ./testssl.sh/testssl.sh <host>"
    fi
}

install_git_secrets() {
    if [[ "$OS" == "macos" ]]; then
        if $BREW_OK; then
            brew install git-secrets && success "git-secrets installed via Homebrew."
        else
            warn "Homebrew not available — cannot install git-secrets. Install manually: https://github.com/awslabs/git-secrets"
        fi
    else
        if [[ -d "git-secrets" ]]; then
            warn "git-secrets directory already exists — skipping clone."
        else
            git clone https://github.com/awslabs/git-secrets.git
        fi
        cd git-secrets && sudo make install && cd ..
        success "git-secrets installed."
    fi
}

install_podman_image() {
    local image="$1"
    local label="$2"
    if command -v podman &>/dev/null; then
        info "Pulling $label image: $image ..."
        podman pull "$image" && success "$label image pulled."
    else
        warn "Podman is not installed — cannot pull $label image. See note at end of setup."
    fi
}

# ─── tfsec ───────────────────────────────────────────────────────────────────
header "tfsec (Terraform IaC scanner)"
if command -v tfsec &>/dev/null; then
    success "tfsec already installed: $(tfsec --version 2>&1 | head -1)"
elif ask "Install tfsec?"; then
    install_tfsec
else
    info "Skipping tfsec."
fi

# ─── testssl.sh ──────────────────────────────────────────────────────────────
header "testssl.sh (TLS/SSL endpoint scanner)"
if command -v testssl &>/dev/null || command -v testssl.sh &>/dev/null; then
    success "testssl already installed."
elif ask "Install testssl.sh?"; then
    install_testssl
else
    info "Skipping testssl.sh."
fi

# ─── git-secrets ─────────────────────────────────────────────────────────────
header "git-secrets (secret leak prevention)"
if command -v git-secrets &>/dev/null; then
    success "git-secrets already installed."
elif ask "Install git-secrets?"; then
    install_git_secrets
else
    info "Skipping git-secrets."
fi

# ─── Podman images ────────────────────────────────────────────────────────────
header "Podman Container Images"
echo "  The following tools are available as container images via Podman."
echo ""

if ask "Pull KICS (IaC scanner) image? [checkmarx/kics:latest]"; then
    install_podman_image "checkmarx/kics:latest" "KICS"
else
    info "Skipping KICS image."
fi

if ask "Pull OWASP ZAP (DAST / OAuth scanner) image? [owasp/zap2docker-stable]"; then
    install_podman_image "owasp/zap2docker-stable" "OWASP ZAP"
else
    info "Skipping OWASP ZAP image."
fi

if ask "Pull Semgrep container image? [returntocorp/semgrep]"; then
    install_podman_image "returntocorp/semgrep" "Semgrep"
else
    info "Skipping Semgrep container image."
fi

if ask "Pull Checkov container image? [bridgecrew/checkov]"; then
    install_podman_image "bridgecrew/checkov" "Checkov"
else
    info "Skipping Checkov container image."
fi

if ask "Pull TruffleHog container image? [trufflesecurity/trufflehog]"; then
    install_podman_image "trufflesecurity/trufflehog" "TruffleHog"
else
    info "Skipping TruffleHog container image."
fi

# ─── Final summary ─────────────────────────────────────────────────────────
header "Setup Complete"
echo ""
echo -e "  ${GREEN}${BOLD}Your DevSecOps Security Mode environment is ready.${RESET}"
echo ""

if $VENV_ACTIVE; then
    echo -e "  ${CYAN}Virtual environment:${RESET}"
    echo "    Activate it in future sessions with:"
    echo "      source $VENV_DIR/bin/activate"
    echo ""
fi

echo -e "  ${YELLOW}${BOLD}Manual steps still required:${RESET}"
echo ""
echo -e "  ${BOLD}1. Podman${RESET}"
echo "     Podman must be installed to use container-based tools (KICS, OWASP ZAP,"
echo "     Semgrep, Checkov, TruffleHog container images)."
if [[ "$OS" == "macos" ]]; then
    echo "     Install:  brew install podman"
    echo "     Then:     podman machine init && podman machine start"
else
    echo "     Install:  https://podman.io/getting-started/installation"
fi
echo ""
echo -e "  ${BOLD}2. IBM Quantum Safe Explorer${RESET}"
echo "     This tool requires a commercial IBM license."
echo "     Contact your IBM representative to obtain access and installation files."
echo "     Docs: https://www.ibm.com/docs/en/quantum-safe-explorer"
echo ""
echo -e "  ${BOLD}3. SSLyze / TruffleHog verification${RESET}"
echo "     Run:  sslyze --version"
echo "     Run:  trufflehog --version"
echo ""
echo "  To use the mode to its full capabilities, ensure all tools above are"
echo "  installed and Podman is running before starting scans."
echo ""
success "Done."
