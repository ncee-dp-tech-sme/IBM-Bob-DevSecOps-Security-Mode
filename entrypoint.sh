#!/usr/bin/env bash
# entrypoint.sh — in-container tool dispatcher for devsecops-tools image
# Created: routes the first argument to the appropriate installed tool,
#          passes all remaining arguments through unchanged.

set -euo pipefail

TOOL="${1:-help}"
shift || true

print_help() {
    cat <<'EOF'

  IBM Bob DevSecOps Security Mode — Container Toolbox
  ────────────────────────────────────────────────────
  Usage (via scan.sh on host):
    ./scan.sh <tool> [tool-arguments]

  Available tools:
    semgrep        Static analysis / security pattern detection
    checkov        IaC security scanner (Terraform, Ansible, K8s, ...)
    kics           IaC security scanner (Checkmarx KICS)
    tfsec          Terraform-specific security scanner
    sslyze         TLS/SSL certificate and configuration scanner
    testssl        TLS/SSL endpoint scanner (testssl.sh)
    trufflehog     Secrets detection in git repos and filesystems
    detect-secrets Secrets baseline management (pre-commit)
    git-secrets    Git hook-based secret leak prevention
    help           Show this help message

  Note: OWASP ZAP requires its own container image (owasp/zap2docker-stable).
        Use: podman run -t owasp/zap2docker-stable zap-baseline.py -t <url>

  Examples:
    ./scan.sh semgrep --config auto /scan/project
    ./scan.sh checkov -d /scan/project
    ./scan.sh kics scan -p /scan/project -o /scan/results
    ./scan.sh tfsec /scan/project
    ./scan.sh sslyze api.example.com:443
    ./scan.sh testssl https://api.example.com
    ./scan.sh trufflehog filesystem /scan/project
    ./scan.sh detect-secrets scan /scan/project

EOF
}

case "$TOOL" in
    semgrep)
        exec semgrep "$@"
        ;;
    checkov)
        exec checkov "$@"
        ;;
    kics)
        exec kics "$@"
        ;;
    tfsec)
        exec tfsec "$@"
        ;;
    sslyze)
        exec sslyze "$@"
        ;;
    testssl)
        exec testssl "$@"
        ;;
    trufflehog)
        exec trufflehog "$@"
        ;;
    detect-secrets)
        exec detect-secrets "$@"
        ;;
    git-secrets)
        exec git-secrets "$@"
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        echo "ERROR: Unknown tool '$TOOL'" >&2
        print_help
        exit 1
        ;;
esac
