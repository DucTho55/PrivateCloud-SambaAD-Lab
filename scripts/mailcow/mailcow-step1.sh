#!/bin/bash
# Buoc 1: cai Mailcow tren VM 2000 (cloud-lab-01)
# - Web Mailcow chi nghe tren 127.0.0.1:8090 / 8453 (HAProxy se dung truoc)
# - Tat ClamAV de tiet kiem RAM
set -euo pipefail
exec > >(tee /tmp/mailcow-step1.log) 2>&1

echo "== Cai goi can thiet =="
command -v git >/dev/null && command -v jq >/dev/null || { apt-get update -qq; apt-get install -y -qq git jq; }
docker compose version

echo "== Clone mailcow =="
if [ ! -d /opt/mailcow-dockerized ]; then
  git clone https://github.com/mailcow/mailcow-dockerized /opt/mailcow-dockerized
fi
cd /opt/mailcow-dockerized

if [ ! -f mailcow.conf ]; then
  echo "== Tao mailcow.conf =="
  export MAILCOW_HOSTNAME=mail.ad.lab.test
  export MAILCOW_TZ=Asia/Ho_Chi_Minh
  export MAILCOW_BRANCH=master
  # Tra loi mac dinh cho moi cau hoi con lai
  yes "" | ./generate_config.sh || true
fi
[ -f mailcow.conf ] || { echo "LOI: khong tao duoc mailcow.conf"; exit 1; }

setconf() { if grep -q "^$1=" mailcow.conf; then sed -i "s|^$1=.*|$1=$2|" mailcow.conf; else echo "$1=$2" >> mailcow.conf; fi; }
cp -n mailcow.conf mailcow.conf.orig
setconf MAILCOW_HOSTNAME mail.ad.lab.test
setconf HTTP_PORT 8090
setconf HTTP_BIND 127.0.0.1
setconf HTTPS_PORT 8453
setconf HTTPS_BIND 127.0.0.1
setconf HTTP_REDIRECT n
setconf SKIP_LETS_ENCRYPT y
setconf SKIP_CLAMD y

echo "== Cau hinh da dat =="
grep -E '^(MAILCOW_HOSTNAME|HTTP_PORT|HTTP_BIND|HTTPS_PORT|HTTPS_BIND|HTTP_REDIRECT|SKIP_LETS_ENCRYPT|SKIP_CLAMD|TZ)=' mailcow.conf

echo "== Tai image va khoi dong (mat vai phut) =="
docker compose pull -q
docker compose up -d
sleep 20
docker compose ps --format '{{.Service}}\t{{.State}}'
echo "STEP1_DONE"
