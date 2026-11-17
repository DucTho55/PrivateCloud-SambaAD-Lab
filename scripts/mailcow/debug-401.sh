#!/bin/bash
# Bat log DEBUG tam thoi cho Keycloak, tai hien loi 401, roi TU KHOI PHUC lai nhu cu.
# Keycloak se restart 2 lan (SSO ngung khoang 1-2 phut tong cong).
exec > >(tee /tmp/debug-401.log) 2>&1
KCDIR=/opt/cloud-lab/keycloak
OVR=$KCDIR/compose.override.yaml
CA=/etc/haproxy/lab-ca/root-ca.crt
[ -e "$OVR" ] && { echo "Da co $OVR - dung lai de khong ghi de"; exit 1; }

wait_kc() { for i in $(seq 1 60); do curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/realms/cloud-lab | grep -q 200 && { echo "Keycloak san sang sau ${i}x2s"; return; }; sleep 2; done; echo "Keycloak chua len!"; }

cat > "$OVR" <<'EOF'
services:
  keycloak:
    environment:
      KC_LOG_LEVEL: "INFO,org.keycloak.services.managers:debug,org.keycloak.services.resources.admin:debug,org.keycloak.protocol.oidc:debug"
EOF
cd $KCDIR && docker compose up -d keycloak && wait_kc
START=$(date -u +%Y-%m-%dT%H:%M:%S)

cd /opt/mailcow-dockerized && source mailcow.conf
SECRET=$(docker compose exec -T mysql-mailcow mysql -N -u"$DBUSER" -p"$DBPASS" "$DBNAME" -e "SELECT \`value\` FROM identity_provider WHERE \`key\`='client_secret';" 2>/dev/null)
TOK=$(curl -s --cacert $CA https://auth.ad.lab.test/realms/cloud-lab/protocol/openid-connect/token \
  -d grant_type=client_credentials -d client_id=mailcow --data-urlencode "client_secret=$SECRET" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
echo "token length: ${#TOK}"
echo -n "GET /users -> "; curl -s -o /dev/null -w '%{http_code}\n' --cacert $CA -H "Authorization: Bearer $TOK" "https://auth.ad.lab.test/admin/realms/cloud-lab/users?max=1"
sleep 2
echo "== DEBUG log lien quan =="
docker logs --since "$START" cloud-lab-keycloak-keycloak-1 2>&1 | grep -iE 'admin|token|bearer|session|verif|401|unauthor|not.?before|inactive|expired' | grep -viE 'full-scope' | tail -40

echo "== Khoi phuc cau hinh cu =="
rm -f "$OVR"
cd $KCDIR && docker compose up -d keycloak && wait_kc
docker inspect cloud-lab-keycloak-keycloak-1 --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -c KC_LOG_LEVEL | sed 's/^/KC_LOG_LEVEL con lai: /'
echo "DEBUG401_DONE"
