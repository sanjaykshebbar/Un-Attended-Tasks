#!/bin/bash

set -e

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Please run this script as root (sudo)."
    exit 1
fi

USER_NAME="${SUDO_USER:-$(logname)}"
echo "👤 Running setup for user: $USER_NAME"

# Update & Upgrade
echo "🔄 Updating system..."
apt update && apt upgrade -y

# Install dependencies
echo "⬇️ Installing dependencies..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release

########################################
# Docker & Docker Compose
########################################
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker "$USER_NAME"
systemctl enable docker
systemctl start docker

########################################
# Git
########################################
echo "📦 Installing Git..."
apt install -y git

########################################
# Sublime Text
########################################
echo "📝 Installing Sublime Text..."
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor -o /usr/share/keyrings/sublime.gpg
echo "deb [signed-by=/usr/share/keyrings/sublime.gpg] https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
apt update
apt install -y sublime-text

########################################
# VS Code
########################################
echo "💻 Installing VS Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/vscode.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
apt update
apt install -y code

########################################
# Jenkins
########################################
echo "🔧 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt update
apt install -y openjdk-17-jdk jenkins
systemctl enable jenkins
systemctl start jenkins

########################################
# Terraform
########################################
echo "🌍 Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install -y terraform

########################################
# Google Chrome
########################################
echo "🌐 Installing Google Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

########################################
# Brave Browser
########################################
echo "🦁 Installing Brave Browser..."
curl -fsSL https://brave.com/signing-key.asc | gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
apt update
apt install -y brave-browser

########################################
# OpenSSH Server
########################################
echo "🔐 Installing & configuring OpenSSH Server..."
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Enable password authentication
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

########################################
# Hostname Change (Optional)
########################################
read -p "💡 Do you want to change the hostname? (y/n): " CHANGE_HOSTNAME
if [[ "$CHANGE_HOSTNAME" =~ ^[Yy]$ ]]; then
    read -p "🔧 Enter new hostname: " NEW_HOSTNAME
    hostnamectl set-hostname "$NEW_HOSTNAME"
    echo "Hostname changed to $NEW_HOSTNAME. Rebooting now to apply..."
    sleep 2
    reboot
else
    echo "ℹ️ Hostname unchanged."
fi

echo "✅ Setup completed successfully!"
