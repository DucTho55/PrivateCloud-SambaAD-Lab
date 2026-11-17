#!/bin/bash
# Buoc 3: cho container php-fpm cua Mailcow goi duoc https://auth.ad.lab.test (Keycloak)
#  - them ten auth.ad.lab.test -> 172.16.120.243
#  - tin Cloud Lab Root CA
set -euo pipefail
exec > >(tee /tmp/mailcow-step3.log) 2>&1
MC=/opt/mailcow-dockerized
CA=/etc/haproxy/lab-ca/root-ca.crt
cd "$MC"

echo "== Tao CA bundle co them Cloud Lab Root CA =="
mkdir -p data/conf/custom-ca
docker compose exec -T php-fpm-mailcow cat /etc/ssl/certs/ca-certificates.crt > data/conf/custom-ca/ca-certificates.crt
grep -q "Cloud Lab Root CA" data/conf/custom-ca/ca-certificates.crt || { echo "# Cloud Lab Root CA"; cat "$CA"; } >> data/conf/custom-ca/ca-certificates.crt
chmod 644 data/conf/custom-ca/ca-certificates.crt

echo "== docker-compose.override.yml =="
if [ -f docker-compose.override.yml ]; then cp -a docker-compose.override.yml "docker-compose.override.yml.bak-$(date +%s)"; cat docker-compose.override.yml; fi
cat > docker-compose.override.yml <<'EOF'
services:
  php-fpm-mailcow:
    extra_hosts:
      - "auth.ad.lab.test:172.16.120.243"
      - "cloud.ad.lab.test:172.16.120.243"
    volumes:
      - ./data/conf/custom-ca/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro
EOF
docker compose config -q && echo "compose OK"
docker compose up -d php-fpm-mailcow
sleep 8

echo "== Kiem tra tu trong container =="
docker compose exec -T php-fpm-mailcow php -r '$c=curl_init("https://auth.ad.lab.test/realms/cloud-lab/.well-known/openid-configuration");curl_setopt($c,CURLOPT_RETURNTRANSFER,1);$r=curl_exec($c);echo "HTTP ".curl_getinfo($c,CURLINFO_HTTP_CODE)." ".(curl_error($c)?:"tls ok").PHP_EOL;'
echo "STEP3_DONE"
