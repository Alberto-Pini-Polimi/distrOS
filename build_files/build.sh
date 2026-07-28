#!/bin/bash
set -ouex pipefail

### Helper centralizzato per download con retry
# Uso: fetch <url> <output_file>
fetch() {
    curl --retry 5 --retry-delay 5 --retry-all-errors --connect-timeout 10 -fsSL "$1" -o "$2"
}

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

## DNF5 speedup
sed -i '/^\[main\]/a max_parallel_downloads=10' /etc/dnf/dnf.conf

## Rimuovo GNOME Shell per usare niri come compositor
dnf5 -y remove gnome-shell
dnf5 -y install niri pipewire xdg-desktop-portal-wlr lxpolkit

## DMS (Dank Material Shell) - barra, launcher, notifiche, centro controllo
fetch "https://copr.fedorainfracloud.org/coprs/avengemedia/dms/repo/fedora-$(rpm -E %fedora)/avengemedia-dms-fedora-$(rpm -E %fedora).repo" \
      "/etc/yum.repos.d/dms.repo"
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

mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -s /usr/lib/systemd/user/dms.service /etc/skel/.config/systemd/user/graphical-session.target.wants/

## App utente
dnf5 -y install \
  showtime \
  gnome-text-editor \
  nautilus \
  gnome-calculator \
  loupe \
  seahorse \
  file-roller \
  network-manager-applet \
  uv \
  simple-scan \
  snapshot \
  papers

## Browser: Brave (repo ufficiale)
fetch "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" \
      "/etc/yum.repos.d/brave-browser.repo"
dnf5 -y install brave-browser

## VS Code (repo ufficiale Microsoft)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo << EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
dnf5 -y install code

# ## Browser: Helium (COPR ufficiale del progetto)
# dnf5 -y copr enable imput/helium
# dnf5 -y install helium-bin

# ## Antigravity (Google) - nessun RPM ufficiale per la 2.0, si estrae il tarball
# ANTIGRAVITY_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.1.4-6481382726303744/linux-x64/Antigravity.tar.gz"
# mkdir -p /opt/antigravity
# curl --retry 5 --retry-delay 5 --retry-all-errors -fsSL "$ANTIGRAVITY_URL" | tar -xz -C /opt/antigravity --strip-components=1
# ln -sf /opt/antigravity/antigravity /usr/local/bin/antigravity
# cat > /usr/share/applications/antigravity.desktop << EOF
# [Desktop Entry]
# Name=Antigravity
# Exec=/usr/local/bin/antigravity --ozone-platform-hint=wayland %F
# Icon=antigravity
# Type=Application
# Categories=Development;
# EOF

## Rimuovo waybar (arriva come dipendenza, in conflitto visivo con DMS)
dnf5 -y remove waybar --noautoremove
## rimuovere firefox
dnf5 -y remove firefox firefox-langpacks
dnf5 -y remove gnome-control-center
dnf5 -y remove alacritty
dnf5 -y remove fuzzel --noautoremove
dnf5 -y remove htop nvtop
dnf5 -y remove rygel

## abilito il search esteso al posto di fuzzel:
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -sf /usr/lib/systemd/user/dsearch.service /etc/skel/.config/systemd/user/graphical-session.target.wants/


## Podman socket abilitato
systemctl enable podman.socket

## CLEAN UP
dnf5 -y clean all
rm -rf /run/dnf /run/selinux-policy
rm -rf /var/lib/dnf