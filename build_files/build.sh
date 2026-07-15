#!/bin/bash
set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

## DNF5 speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

## Rimuovo GNOME Shell per usare niri come compositor
dnf5 -y remove gnome-shell
dnf5 -y install niri pipewire xdg-desktop-portal-wlr lxpolkit

## DMS (Dank Material Shell) - barra, launcher, notifiche, centro controllo
curl --output-dir "/etc/yum.repos.d/" \
  --remote-name "https://copr.fedorainfracloud.org/coprs/avengemedia/dms/repo/fedora-$(rpm -E %fedora)/avengemedia-dms-fedora-$(rpm -E %fedora).repo"
dnf5 -y install quickshell dms greetd dms-greeter --allowerasing

## Login manager (greetd, qualsiasi va bene)
mkdir -p /etc/greetd/
cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1
[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/greetd.service /etc/systemd/system/display-manager.service
systemctl enable --force greetd.service

# Avvia dms automaticamente per ogni nuovo utente
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service /etc/skel/.config/systemd/user/graphical-session.target.wants/

## App utente
dnf5 -y install \
  showtime \
  gnome-music \
  gnome-text-editor \
  nautilus \
  gnome-calculator \
  loupe \
  gnome-system-monitor \
  seahorse \
  file-roller \
  network-manager-applet

## Browser: Brave (repo ufficiale)
# curl -fsSL https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo \
#   -o /etc/yum.repos.d/brave-browser.repo
# dnf5 -y install brave-browser

## Browser: Helium (via repo Terra, community)
curl -fsSL https://terra.fyralabs.com/terra.repo -o /etc/yum.repos.d/terra.repo
dnf5 -y install helium-browser-bin

## Antigravity (Google) - nessun RPM ufficiale per la 2.0, si estrae il tarball
# ANTIGRAVITY_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.1.4-6481382726303744/linux-x64/Antigravity.tar.gz"
# mkdir -p /opt/antigravity
# curl -fsSL "$ANTIGRAVITY_URL" | tar -xz -C /opt/antigravity --strip-components=1
# ln -sf /opt/antigravity/antigravity /usr/local/bin/antigravity
# cat > /usr/share/applications/antigravity.desktop << EOF
# [Desktop Entry]
# Name=Antigravity
# Exec=/usr/local/bin/antigravity --ozone-platform-hint=wayland %F
# Icon=antigravity
# Type=Application
# Categories=Development;
# EOF

## Podman socket abilitato
systemctl enable podman.socket

## CLEAN UP
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf