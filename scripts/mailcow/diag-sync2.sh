#!/bin/bash
# Khoanh vung loi 401 cua Admin API (chi doc, khong in secret/token)
exec > >(tee /tmp/diag-sync2.log) 2>&1
cd /opt/mailcow-dockerized && source mailcow.conf
CA=/etc/haproxy/lab-ca/root-ca.crt
SECRET=$(docker compose exec -T mysql-mailcow mysql -N -u"$DBUSER" -p"$DBPASS" "$DBNAME" -e "SELECT \`value\` FROM identity_provider WHERE \`key\`='client_secret';" 2>/dev/null)
TOK=$(curl -s --cacert $CA https://auth.ad.lab.test/realms/cloud-lab/protocol/openid-connect/token \
  -d grant_type=client_credentials -d client_id=mailcow --data-urlencode "client_secret=$SECRET" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
echo "token length: ${#TOK}"
echo "$TOK" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | python3 -c 'import sys,json;d=json.loads(sys.stdin.read()+"" if True else "");print({k:d.get(k) for k in ["iss","typ","azp","sid","aud","scope"]})' 2>/dev/null \
 || echo "$TOK" | cut -d. -f2 | tr '_-' '/+' | (cat; echo '==') | base64 -d 2>/dev/null | head -c 600; echo

t() { printf '%-60s -> ' "$1"; shift; curl -s -o /tmp/resp.txt -w '%{http_code}' "$@"; echo " $(head -c 120 /tmp/resp.txt)"; }
echo "== 1. Qua HAProxy =="
t "HAProxy /admin/realms/cloud-lab/users" --cacert $CA -H "Authorization: Bearer $TOK" "https://auth.ad.lab.test/admin/realms/cloud-lab/users?max=1"
t "HAProxy userinfo" --cacert $CA -H "Authorization: Bearer $TOK" "https://auth.ad.lab.test/realms/cloud-lab/protocol/openid-connect/userinfo"
echo "== 2. Goi thang Keycloak 127.0.0.1:8081 (bo qua HAProxy) =="
t "Direct + X-Forwarded https" -H "Host: auth.ad.lab.test" -H "X-Forwarded-Proto: https" -H "X-Forwarded-Host: auth.ad.lab.test" -H "X-Forwarded-Port: 443" -H "Authorization: Bearer $TOK" "http://127.0.0.1:8081/admin/realms/cloud-lab/users?max=1"
t "Direct khong header" -H "Authorization: Bearer $TOK" "http://127.0.0.1:8081/admin/realms/cloud-lab/users?max=1"
echo "== 3. Cau hinh client mailcow lien quan =="
echo "== Keycloak log 2 phut =="
docker logs --since 2m cloud-lab-keycloak-keycloak-1 2>&1 | grep -vE 'full-scope' | grep -E 'WARN|ERROR' | tail -10
echo "== Keycloak version =="
docker exec cloud-lab-keycloak-keycloak-1 /opt/keycloak/bin/kc.sh --version 2>/dev/null | head -3
rm -f /tmp/resp.txt
echo "DIAG_SYNC2_DONE"
