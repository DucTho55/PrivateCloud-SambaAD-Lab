#!/bin/bash
# Chan doan dang nhap Mailcow qua Keycloak (chi doc log, khong thay doi gi)
exec > >(tee /tmp/diag-login.log) 2>&1
echo "== Containers =="
docker ps --format '{{.Names}}' | grep -viE 'mailcow'
KC=$(docker ps --format '{{.Names}}' | grep -iE 'keycloak' | grep -viE 'db|postgres' | head -1)
echo "Keycloak container: $KC"
echo "== Keycloak log 20 phut (WARN/ERROR) =="
docker logs --since 20m "$KC" 2>&1 | grep -E 'WARN|ERROR' | tail -40
cd /opt/mailcow-dockerized
echo "== Mailcow php-fpm log =="
docker compose logs --since 20m php-fpm-mailcow 2>&1 | grep -viE 'GET /api|ping' | tail -40
echo "== Mailcow nginx log (iam/sso) =="
docker compose logs --since 20m nginx-mailcow 2>&1 | grep -iE 'iam|sso|code=|error' | tail -20
echo "== Mailcow logs trong DB (ui/iam) =="
source mailcow.conf
docker compose exec -T mysql-mailcow mysql -u"$DBUSER" -p"$DBPASS" "$DBNAME" -e "SELECT username,authsource,active,created FROM mailbox; SELECT * FROM logs ORDER BY id DESC LIMIT 15;" 2>&1 | tail -30
docker compose exec -T redis-mailcow redis-cli -a "$REDISPASS" --no-auth-warning LRANGE CRON_LOG 0 15 2>&1 | tail -15
echo "DIAG_DONE"
