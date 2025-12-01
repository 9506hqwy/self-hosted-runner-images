#!/bin/bash

# Disable SubscriptionManager plugin.
sed -i /etc/dnf/plugins/subscription-manager.conf -e 's/^enabled=1/enabled=0/'

# Configure environment variables in all process.
cat >> /etc/environment <<EOF
HTTP_PROXY=${HTTP_PROXY:-}
HTTPS_PROXY=${HTTPS_PROXY:-}
NO_PROXY=${NO_PROXY:-}
http_proxy=${http_proxy:-}
https_proxy=${https_proxy:-}
no_proxy=${no_proxy:-}
BASH_ENV=~/.bash_env
EOF

# Uppdate base system.
dnf update -y

# Install base packages.
dnf install -y \
    sudo \
    git \
    \
    gcc \
    gcc-c++ \
    \
    dotnet-sdk-6.0 \
    dotnet-sdk-7.0 \
    dotnet-sdk-8.0 \
    dotnet-sdk-9.0 \
    \
    golang \
    \
    nodejs \
    \
    python3 \
    python3-devel \
    python3-pip \
    python3.11 \
    python3.11-devel \
    python3.11-pip \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    \
    cargo \
    clippy \
    rust \
    rustfmt \
    \
    lz4 \
    unzip \
    xz \
    zip \
    zstd \
    \
    diffutils \
    gettext \
    jq \
    xmlstarlet \
    'dnf-command(config-manager)'

# ----------------------------------------------------------------------------

# Install forgejo runner.
#RUNNER_VERSION=$(curl -fsSL https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .name -r)
FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION#v}-linux-amd64"

curl -fsSL --output-dir /usr/local/bin -o forgejo-runner "${FORGEJO_URL}"
chmod +x /usr/local/bin/forgejo-runner

curl -fsSL --output-dir /tmp -o forgejo-runner.asc "${FORGEJO_URL}.asc"
gpg --keyserver hkps://keys.openpgp.org --recv EB114F5E6C0DC2BCDD183550A4B61A2DC5923710
gpg --verify /tmp/forgejo-runner.asc /usr/local/bin/forgejo-runner

# ----------------------------------------------------------------------------

# Run as runner
useradd -m -s /sbin/nologin runner

# Configure profile
cat >> /home/runner/.bash_env <<EOF
source ~/.bash_profile
EOF
chown runner:runner /home/runner/.bash_env

# ----------------------------------------------------------------------------

# Install Docker Engine.
# https://docs.docker.com/engine/install/centos/
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Configure Docker Engine.
# https://docs.docker.com/engine/daemon/proxy/#systemd-unit-file
mkdir -p /etc/systemd/system/docker.service.d
cat >> /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
EnvironmentFile=/etc/environment
EOF

# Run as runner.
usermod -a -G docker runner

# Configure Docker Client.
# https://docs.docker.com/engine/cli/proxy/#configure-the-docker-client
mkdir -p /home/runner/.docker
cat >> /home/runner/.docker/config.json <<EOF
{
    "proxies": {
        "default": {
            "httpProxy": "${HTTP_PROXY:-}",
            "httpsProxy": "${HTTPS_PROXY:-}",
            "noProxy": "${NO_PROXY:-}"
        }
    }
}
EOF
chown runner:runner -R /home/runner/.docker

# Configure storage-drive at docker in podman.
# Default storage drive is `overlayfs` in docker-ce 29.x or later.
cat > /etc/docker/daemon.json <<EOF
{
    "storage-driver": "fuse-overlayfs"
}
EOF

# Enable Docker Engine.
systemctl enable docker

# ----------------------------------------------------------------------------

# Configure sudo
sed -i /etc/sudoers -e 's/.*\(%wheel.*\)/\1/'
usermod -a -G wheel runner

# Cleanup
dnf clean all

# Install entrypoint.
cp /src/scripts/docker-entrypoint.sh /
chmod 755 /docker-entrypoint.sh
