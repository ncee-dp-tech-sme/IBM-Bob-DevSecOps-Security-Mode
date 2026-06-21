#!/usr/bin/env bash
# scan.sh — host-side convenience wrapper for the devsecops-tools container image
# Created: mounts the current working directory into the container as /scan/project
#          and writes all output to ./scan-results on the host.
#
# Usage:  ./scan.sh <tool> [tool-arguments]
# Build:  ./scan.sh --build

set -euo pipefail

IMAGE_NAME="devsecops-tools"
CONTAINERFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_PROJECT_DIR="$(pwd)"
HOST_RESULTS_DIR="${HOST_PROJECT_DIR}/scan-results"
CONTAINER_PROJECT="/scan/project"
CONTAINER_RESULTS="/scan/results"

# ─── Colours ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ─── Require podman ──────────────────────────────────────────────────────────
if ! command -v podman &>/dev/null; then
    error "Podman is not installed or not in PATH."
    echo ""
    echo "  Install Podman:"
    echo "    macOS:  brew install podman && podman machine init && podman machine start"
    echo "    Linux:  https://podman.io/getting-started/installation"
    exit 1
fi

# ─── Build flag ──────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--build" ]]; then
    info "Building image '$IMAGE_NAME' from $CONTAINERFILE_DIR/Containerfile ..."
    podman build -t "$IMAGE_NAME" -f "$CONTAINERFILE_DIR/Containerfile" "$CONTAINERFILE_DIR"
    success "Image '$IMAGE_NAME' built successfully."
    exit 0
fi

# ─── Help / no args ──────────────────────────────────────────────────────────
if [[ $# -eq 0 || "${1:-}" == "help" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    podman run --rm -t "$IMAGE_NAME" help
    exit 0
fi

# ─── Check image exists ───────────────────────────────────────────────────────
if ! podman image exists "$IMAGE_NAME" 2>/dev/null; then
    warn "Image '$IMAGE_NAME' not found. Building it now..."
    podman build -t "$IMAGE_NAME" -f "$CONTAINERFILE_DIR/Containerfile" "$CONTAINERFILE_DIR"
    success "Image built."
fi

# ─── Prepare results directory ────────────────────────────────────────────────
mkdir -p "$HOST_RESULTS_DIR"

TOOL="$1"
shift

# ─── Build podman run arguments ───────────────────────────────────────────────
# --userns=keep-id maps the container UID to the host user's UID so the process
# can write to bind-mounted directories without permission errors.
PODMAN_ARGS=(
    run --rm -t
    --userns=keep-id
    -v "${HOST_PROJECT_DIR}:${CONTAINER_PROJECT}:z"
    -v "${HOST_RESULTS_DIR}:${CONTAINER_RESULTS}:z"
    --workdir "${CONTAINER_PROJECT}"
)

# ─── Tool-specific path rewriting ────────────────────────────────────────────
# Rewrite any host-absolute paths that sit inside the project dir to their
# container equivalents, so users can pass plain host paths on the CLI.
rewrite_paths() {
    local rewritten=()
    for arg in "$@"; do
        if [[ "$arg" == "${HOST_PROJECT_DIR}"* ]]; then
            rewritten+=("${CONTAINER_PROJECT}${arg#${HOST_PROJECT_DIR}}")
        elif [[ "$arg" == "${HOST_RESULTS_DIR}"* ]]; then
            rewritten+=("${CONTAINER_RESULTS}${arg#${HOST_RESULTS_DIR}}")
        else
            rewritten+=("$arg")
        fi
    done
    printf '%s\n' "${rewritten[@]}"
}

# Collect rewritten args
REWRITTEN_ARGS=()
while IFS= read -r line; do
    REWRITTEN_ARGS+=("$line")
done < <(rewrite_paths "$@")

# ─── Special handling: testssl and sslyze need network access ────────────────
# --network host is only supported on Linux; on macOS Podman runs inside a VM
# so host networking is not available and causes a sysfs mount permission error.
if [[ "$TOOL" == "testssl" || "$TOOL" == "sslyze" ]]; then
    if [[ "$(uname -s)" == "Linux" ]]; then
        PODMAN_ARGS+=(--network host)
    fi
fi

# ─── Run ─────────────────────────────────────────────────────────────────────
info "Running '$TOOL' in container..."
info "Project mounted from: $HOST_PROJECT_DIR"
info "Results written to:   $HOST_RESULTS_DIR"
echo ""

podman "${PODMAN_ARGS[@]}" "$IMAGE_NAME" "$TOOL" "${REWRITTEN_ARGS[@]+"${REWRITTEN_ARGS[@]}"}"

echo ""
success "Scan complete. Results available in: $HOST_RESULTS_DIR"
