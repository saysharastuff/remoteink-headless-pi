#!/bin/bash
# Install PocketBook RemoteInk headless Xorg setup
set -euo pipefail

# root check
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./install.sh"; exit 1
fi

REMOTEINK_BIN="/usr/local/bin/remoteinkd"
XORG_CONF_SRC="20-pb-dummy.conf"
XORG_CONF_DST="/etc/X11/xorg.conf.d/20-pb-dummy.conf"
SESSION_SRC="pb-xorg-session.sh"
SESSION_DST="/usr/local/bin/pb-xorg-session.sh"
SERVICE_UNIT="/etc/systemd/system/pb-remoteink.service"
XRDB_SRC=".Xresources"
XRDB_DST="/root/.Xresources"

echo "Installing packages…"
apt-get update -y
apt-get install -y \
  xserver-xorg xserver-xorg-video-dummy xserver-xorg-input-libinput \  lxde-core lxsession dbus-x11 x11-apps xauth xinput dmz-cursor-theme \  xcompmgr

echo "Deploying Xorg config…"
mkdir -p /etc/X11/xorg.conf.d
install -m 0644 "$XORG_CONF_SRC" "$XORG_CONF_DST"

echo "Deploying session wrapper…"
install -m 0755 "$SESSION_SRC" "$SESSION_DST"

echo "Deploying Xresources…"
install -m 0644 "$XRDB_SRC" "$XRDB_DST"

echo "Writing systemd unit…"
cat > "$SERVICE_UNIT" <<'EOF'
[Unit]
Description=PocketBook headless Xorg (dummy) + RemoteInk session
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pb-xorg-session.sh
Restart=on-failure
RestartSec=2
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
EOF

echo "Writing USBNet helper and udev rule…"
cat > /usr/local/bin/pb-usb0.sh <<'EOF'
#!/bin/sh
set -eu
IF=${1:-usb0}
ip link set "$IF" up || true
ip addr add 169.254.0.2/16 dev "$IF" 2>/dev/null || true
exit 0
EOF
chmod +x /usr/local/bin/pb-usb0.sh

cat > /etc/udev/rules.d/90-pb-usb0.rules <<'EOF'
ACTION=="add", SUBSYSTEM=="net", KERNEL=="usb0", RUN+="/usr/local/bin/pb-usb0.sh"
EOF
udevadm control --reload

echo "Enabling and starting service…"
systemctl daemon-reload
systemctl enable --now pb-remoteink

if [[ ! -x "$REMOTEINK_BIN" ]]; then
  echo "NOTE: /usr/local/bin/remoteinkd not found."
  echo "      Install RemoteInk server and run: sudo /usr/local/bin/remoteinkd passwd"
else
  echo "If not already set, run: sudo /usr/local/bin/remoteinkd passwd"
fi
echo "Connect from PocketBook RemoteInk app to 169.254.0.2:9312"