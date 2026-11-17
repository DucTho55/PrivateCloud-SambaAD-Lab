#!/bin/bash
# Buoc cuoi: chuan bi Nextcloud de dung app Mail voi Mailcow
#  - kiem tra hop thu da tao trong Mailcow
#  - dam bao container Nextcloud phan giai duoc mail.ad.lab.test va tin cert
#  - cai/bat app Mail
set -uo pipefail
exec > >(tee /tmp/nc-mail.log) 2>&1
NC=/opt/cloud-lab/nextcloud
APP=$(docker ps --format '{{.Names}}' | grep -E 'nextcloud-app' | head -1)
echo "Nextcloud container: $APP"

echo "== Hop thu trong Mailcow =="
cd /opt/mailcow-dockerized && source mailcow.conf
docker compose exec -T mysql-mailcow mysql -u"$DBUSER" -p"$DBPASS" "$DBNAME" -e "SELECT username,authsource,active FROM mailbox;" 2>/dev/null
docker compose exec -T redis-mailcow redis-cli -a "$REDISPASS" --no-auth-warning LRANGE CRON_LOG 0 3 2>/dev/null

echo "== Ten mien tu trong Nextcloud =="
docker exec "$APP" getent hosts auth.ad.lab.test mail.ad.lab.test || true
if ! docker exec "$APP" getent hosts mail.ad.lab.test >/dev/null; then
  echo "-> Them extra_hosts cho Nextcloud (app + cron)"
  cp -a $NC/compose.yaml $NC/compose.yaml.bak-$(date +%Y%m%d-%H%M%S)
  python3 - "$NC/compose.yaml" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
block='    extra_hosts:\n      - "auth.ad.lab.test:172.16.120.243"\n      - "cloud.ad.lab.test:172.16.120.243"\n      - "mail.ad.lab.test:172.16.120.243"\n'
for svc in ('app','cron'):
    m=re.search(r'(?m)^  %s:\n((?:    .*\n|\s*\n)*?)(?=^  \S|^\S|\Z)'%svc, s)
    if m and 'extra_hosts' not in m.group(0):
        s=s[:m.end()]+block+s[m.end():] if s[m.end()-1]=='\n' else s
open(p,'w').write(s)
PY
  cd $NC && docker compose config -q && docker compose up -d app cron
  sleep 10
  APP=$(docker ps --format '{{.Names}}' | grep -E 'nextcloud-app' | head -1)
  docker exec "$APP" getent hosts auth.ad.lab.test mail.ad.lab.test
fi

echo "== TLS IMAP/SMTP tu Nextcloud =="
docker exec "$APP" bash -c 'echo | openssl s_client -connect mail.ad.lab.test:993 -servername mail.ad.lab.test 2>/dev/null | grep -E "Verify return code"'
docker exec "$APP" bash -c 'echo | openssl s_client -connect mail.ad.lab.test:465 -servername mail.ad.lab.test 2>/dev/null | grep -E "Verify return code"'

echo "== App Mail =="
docker exec -u www-data "$APP" php occ app:install mail 2>&1 | tail -2
docker exec -u www-data "$APP" php occ app:enable mail 2>&1 | tail -2
docker exec -u www-data "$APP" php occ app:list --shipped=false 2>/dev/null | grep -iE 'mail|sociallogin'
echo "NCMAIL_DONE"
