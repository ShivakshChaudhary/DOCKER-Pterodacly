#!/usr/bin/env bash
set -e

export USER=${USER:-container}
export HOME=/home/container
export DISPLAY=${DISPLAY:-:1}
export RESOLUTION=${RESOLUTION:-1280x720}
export VNC_PORT=${VNC_PORT:-5901}
export NOVNC_PORT=${NOVNC_PORT:-6080}
export VNC_PASSWORD=${VNC_PASSWORD:-pterodactyl}

mkdir -p /run/dbus
mkdir -p "$HOME/.vnc"

rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1
rm -rf "$HOME/.vnc"/*.pid
rm -rf "$HOME/.vnc"/*.log

if [ ! -f "$HOME/.vnc/passwd" ]; then
    mkdir -p "$HOME/.vnc"
    echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd"
fi

cat > "$HOME/.vnc/xstartup" <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xrdb \$HOME/.Xresources
startxfce4 &
EOF

chmod +x "$HOME/.vnc/xstartup"
chown -R container:container "$HOME"

dbus-daemon --system --fork || true

su - container -c "vncserver ${DISPLAY} \
-geometry ${RESOLUTION} \
-depth 24 \
-rfbport ${VNC_PORT} \
localhost no"

if [ ! -f /etc/ssl/novnc.pem ]; then
openssl req \
-x509 \
-nodes \
-newkey rsa:2048 \
-keyout /etc/ssl/novnc.pem \
-out /etc/ssl/novnc.pem \
-days 3650 \
-subj "/C=US/ST=None/L=None/O=Pterodactyl/CN=localhost"
fi

websockify \
--web=/usr/share/novnc \
--cert=/etc/ssl/novnc.pem \
${NOVNC_PORT} \
localhost:${VNC_PORT} &

echo ""
echo "========================================"
echo "Desktop Started"
echo "DISPLAY      : ${DISPLAY}"
echo "Resolution   : ${RESOLUTION}"
echo "VNC Port     : ${VNC_PORT}"
echo "noVNC Port   : ${NOVNC_PORT}"
echo "========================================"

trap "su - container -c 'vncserver -kill ${DISPLAY}' || true; exit 0" SIGTERM SIGINT

while true
do
    if ! pgrep Xtigervnc >/dev/null; then
        echo "VNC server stopped."
        exit 1
    fi
    sleep 5
done
