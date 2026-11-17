#!/bin/bash
# Buoc 2: hosts + cert cho mail.ad.lab.test (ky bang Cloud Lab Root CA) + dua Mailcow ra sau HAProxy
set -euo pipefail
exec > >(tee /tmp/mailcow-step2.log) 2>&1
TS=$(date +%Y%m%d-%H%M%S)
CADIR=/etc/haproxy/lab-ca
CERTS=/etc/haproxy/certs
CFG=/etc/haproxy/haproxy.cfg
MC=/opt/mailcow-dockerized

echo "== 1. /etc/hosts =="
grep -q 'mail.ad.lab.test' /etc/hosts || echo '172.16.120.243 mail.ad.lab.test autodiscover.ad.lab.test autoconfig.ad.lab.test' >> /etc/hosts
grep lab.test /etc/hosts

echo "== 2. Tim CA =="
ls -la "$CADIR"
CA_CRT=""; CA_KEY=""
for f in "$CADIR"/*; do
  [ -f "$f" ] || continue
  if openssl x509 -in "$f" -noout -subject 2>/dev/null | grep -q 'Cloud Lab Root CA'; then CA_CRT="$f"; fi
done
for f in "$CADIR"/*; do
  [ -f "$f" ] || continue
  if openssl pkey -in "$f" -noout 2>/dev/null; then
    if [ -n "$CA_CRT" ] && [ "$(openssl pkey -in "$f" -pubout 2>/dev/null)" = "$(openssl x509 -in "$CA_CRT" -noout -pubkey)" ]; then CA_KEY="$f"; fi
  fi
done
echo "CA_CRT=$CA_CRT"; echo "CA_KEY=$CA_KEY"
[ -n "$CA_CRT" ] && [ -n "$CA_KEY" ] || { echo "LOI: khong tim thay cap CA cert/key. Khong thay doi gi them."; exit 1; }

echo "== 3. Cap cert mail.ad.lab.test =="
if [ ! -f "$CERTS/mail.pem" ]; then
  WORK=$(mktemp -d)
  cat > "$WORK/ext.cnf" <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:mail.ad.lab.test,DNS:autodiscover.ad.lab.test,DNS:autoconfig.ad.lab.test
EOF
  openssl req -new -newkey rsa:2048 -nodes -keyout "$WORK/mail.key" -out "$WORK/mail.csr" -subj "/CN=mail.ad.lab.test"
  openssl x509 -req -in "$WORK/mail.csr" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial -CAserial "$WORK/ca.srl" \
    -days 825 -sha256 -extfile "$WORK/ext.cnf" -out "$WORK/mail.crt"
  install -m 644 "$WORK/mail.crt" "$CERTS/mail.crt"
  install -m 600 "$WORK/mail.key" "$CERTS/mail.key"
  cat "$WORK/mail.crt" "$WORK/mail.key" > "$CERTS/mail.pem"; chmod 600 "$CERTS/mail.pem"
  rm -rf "$WORK"
fi
openssl x509 -in "$CERTS/mail.crt" -noout -subject -issuer -enddate -ext subjectAltName

echo "== 4. Cert cho IMAP/SMTP/web cua Mailcow =="
cp -a "$MC/data/assets/ssl" "$MC/data/assets/ssl.bak-$TS"
cat "$CERTS/mail.crt" "$CA_CRT" > "$MC/data/assets/ssl/cert.pem"
cp "$CERTS/mail.key" "$MC/data/assets/ssl/key.pem"
cp "$CA_CRT" /opt/cloud-lab-ca.crt; chmod 644 /opt/cloud-lab-ca.crt
cd "$MC" && docker compose restart postfix-mailcow dovecot-mailcow nginx-mailcow

echo "== 5. HAProxy =="
if ! grep -q mailcow_backend "$CFG"; then
  cp -a "$CFG" "$CFG.bak-$TS"
  sed -i \
    -e 's|^\(\s*bind 172\.16\.120\.243:443 ssl crt /etc/haproxy/certs/lab\.pem\)\s*$|\1 crt /etc/haproxy/certs/mail.pem|' \
    -e 's|^\(\s*\)acl host_cloud hdr(host) -i cloud\.ad\.lab\.test\s*$|&\n\1acl host_mail hdr(host) -i mail.ad.lab.test autodiscover.ad.lab.test autoconfig.ad.lab.test|' \
    -e 's|http-request deny unless host_auth or host_cloud\s*$|http-request deny unless host_auth or host_cloud or host_mail|' \
    -e 's|^\(\s*\)use_backend nextcloud_backend if host_cloud\s*$|&\n\1use_backend mailcow_backend if host_mail|' \
    "$CFG"
  printf '\nbackend mailcow_backend\n    server mailcow 127.0.0.1:8090 check\n' >> "$CFG"
  if haproxy -c -f "$CFG"; then
    systemctl reload haproxy
  else
    echo "LOI cau hinh HAProxy -> khoi phuc ban cu"; cp -a "$CFG.bak-$TS" "$CFG"; exit 1
  fi
fi
grep -nE 'bind|host_mail|mailcow' "$CFG"

echo "== 6. Kiem tra =="
sleep 3
curl -s -o /dev/null -w 'mail: %{http_code}\n'  --cacert "$CA_CRT" https://mail.ad.lab.test/
curl -s -o /dev/null -w 'cloud: %{http_code}\n' --cacert "$CA_CRT" https://cloud.ad.lab.test/login
curl -s -o /dev/null -w 'auth: %{http_code}\n'  --cacert "$CA_CRT" https://auth.ad.lab.test/realms/cloud-lab
echo | openssl s_client -connect 127.0.0.1:993 -servername mail.ad.lab.test -CAfile "$CA_CRT" 2>/dev/null | grep -E 'subject=|Verify return code'
echo "STEP2_DONE"
