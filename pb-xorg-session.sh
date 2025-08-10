#!/bin/bash
set -euo pipefail
LOG=/var/log/pb-remoteink.log
exec >>"$LOG" 2>&1
echo "--- pb-xorg-session start $(date) ---"

# Ensure :0 is free
rm -f /tmp/.X11-unix/X0 2>/dev/null || true

# Auth cookie for :0
AUTH=/var/lib/pb-xorg/.Xauthority
mkdir -p /var/lib/pb-xorg
chmod 700 /var/lib/pb-xorg
touch "$AUTH"; chmod 600 "$AUTH"
COOKIE=$(hexdump -n 16 -e '16/1 "%02x"' /dev/urandom)
xauth -f "$AUTH" remove :0 2>/dev/null || true
xauth -f "$AUTH" add :0 . "$COOKIE"

# Start headless Xorg with dummy video; libinput will pick up USB HID
/usr/lib/xorg/Xorg :0   -config /etc/X11/xorg.conf.d/20-pb-dummy.conf   -nolisten tcp -noreset -verbose 3 -logfile /var/log/Xorg-pb.log   -auth "$AUTH" &
XORG_PID=$!
echo "Xorg PID=$XORG_PID"
sleep 2

# Session env
export DISPLAY=:0
export XAUTHORITY="$AUTH"

# Desktop
eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
startlxde >/var/log/lxde.log 2>&1 &

# Ensure visible pointer and dark background (helps e-ink readability)
(
  sleep 3
  DISPLAY=:0 XAUTHORITY="$AUTH" xsetroot -cursor_name left_ptr
  DISPLAY=:0 XAUTHORITY="$AUTH" xsetroot -solid '#101010'
  # Optional compositor can help some stacks render cursors
  if command -v xcompmgr >/dev/null 2>&1; then
    DISPLAY=:0 XAUTHORITY="$AUTH" xcompmgr -c -f -F >/var/log/xcompmgr.log 2>&1 &
  fi
) &

# Start RemoteInk daemon if present
if command -v /usr/local/bin/remoteinkd >/dev/null 2>&1; then
  /usr/local/bin/remoteinkd start || echo "remoteinkd start returned non-zero"
else
  echo "WARNING: /usr/local/bin/remoteinkd not found; skipping start."
fi

# Keep supervising Xorg
wait $XORG_PID