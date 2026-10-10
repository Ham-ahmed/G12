#!/bin/sh
PORT=8765
HDIR=/usr/script
WDIR=/usr/script/mpm_web
REPO=https://raw.githubusercontent.com/Ham-ahmed/MagicPanelMax-Web/main

echo "=== MagicPanelMax Setup ==="

echo "[1] Stop mpm_helper only..."
pkill -9 -f mpm_helper.py 2>/dev/null
sleep 2
echo OK

echo "[2] Dirs..."
mkdir -p $HDIR $WDIR
echo OK

echo "[3] Download..."
wget -O $HDIR/mpm_helper.py "$REPO/mpm_helper.py"
wget -O $WDIR/index.html "$REPO/index.html"
chmod 755 $HDIR/mpm_helper.py
ls -l $HDIR/mpm_helper.py $WDIR/index.html

echo "[4] Start with python3..."
python3 $HDIR/mpm_helper.py $PORT > /tmp/mpm_helper.log 2>&1 &
sleep 3

echo "[5] Check..."
pgrep -af mpm_helper
wget -qO- http://127.0.0.1:$PORT/status
echo ""
cat /tmp/mpm_helper.log
echo ""
echo "Open: http://192.168.1.10:$PORT/"
