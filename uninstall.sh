#!/bin/bash
# Uninstall PocketBook RemoteInk headless Xorg setup
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo ./uninstall.sh"; exit 1
fi

SERVICE_UNIT="/etc/systemd/system/pb-remoteink.service"

systemctl disable --now pb-remoteink || true
rm -f "$SERVICE_UNIT"
rm -f /usr/local/bin/pb-xorg-session.sh
rm -f /usr/local/bin/pb-usb0.sh
rm -f /etc/udev/rules.d/90-pb-usb0.rules
rm -f /etc/X11/xorg.conf.d/20-pb-dummy.conf
rm -rf /var/lib/pb-xorg

systemctl daemon-reload
udevadm control --reload || true

echo "Uninstalled. Note: /root/.Xresources was left in place."