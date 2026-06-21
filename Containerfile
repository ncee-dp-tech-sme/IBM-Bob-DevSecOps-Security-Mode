# Containerfile — IBM Bob DevSecOps Security Mode
# Created: all-in-one image with semgrep, checkov, kics, tfsec, sslyze,
#          trufflehog, detect-secrets, git-secrets, testssl.sh, and OWASP ZAP CLI.
#
# Build:  podman build -t devsecops-tools .
# Run:    ./scan.sh <tool> [args]

FROM python:3.12-slim

# Avoid interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# ─── System dependencies ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    make \
    jq \
    wget \
    ca-certificates \
    openssl \
    dnsutils \
    netcat-openbsd \
    bsdmainutils \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ─── Python packages ──────────────────────────────────────────────────────────
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        semgrep \
        checkov \
        sslyze \
        truffleHog \
        detect-secrets

# ─── tfsec ───────────────────────────────────────────────────────────────────
# Install script places the binary directly in /usr/local/bin
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# ─── KICS ────────────────────────────────────────────────────────────────────
# Latest release binary installed to /usr/local/bin
RUN KICS_VERSION=$(curl -s https://api.github.com/repos/Checkmarx/kics/releases/latest \
        | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//') && \
    curl -sSfL "https://github.com/Checkmarx/kics/releases/download/v${KICS_VERSION}/kics_${KICS_VERSION}_linux_amd64.tar.gz" \
        -o /tmp/kics.tar.gz && \
    tar -xzf /tmp/kics.tar.gz -C /tmp && \
    mv /tmp/kics /usr/local/bin/kics && \
    rm -rf /tmp/kics*

# ─── testssl.sh ───────────────────────────────────────────────────────────────
RUN git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl && \
    ln -s /opt/testssl/testssl.sh /usr/local/bin/testssl

# ─── git-secrets ──────────────────────────────────────────────────────────────
RUN git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets && \
    cd /tmp/git-secrets && make install && \
    rm -rf /tmp/git-secrets

# ─── TruffleHog v3 (binary — more features than pip version) ─────────────────
RUN curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
        | sh -s -- -b /usr/local/bin

# ─── Working directory & output dir ──────────────────────────────────────────
RUN mkdir -p /scan/results
WORKDIR /scan

# ─── Entrypoint: delegate to the requested tool ───────────────────────────────
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
