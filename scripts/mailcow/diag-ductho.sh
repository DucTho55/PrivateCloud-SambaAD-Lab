#!/bin/bash
# Chan doan vi sao ductho khong dang nhap duoc Keycloak (chi doc, khong thay doi)
exec > >(tee /tmp/diag-ductho.log) 2>&1
KC=cloud-lab-keycloak-keycloak-1
echo "== Keycloak log 15 phut (login/ldap) =="
docker logs --since 15m "$KC" 2>&1 | grep -iE 'LOGIN_ERROR|ldap|ductho|user_not_found|invalid_user|credential|Exception' | grep -v full-scope | tail -40
echo "== Ten dc1 tu trong container =="
docker exec "$KC" getent hosts dc1.ad.lab.test 2>&1 || docker exec "$KC" sh -c 'cat /etc/hosts' 2>&1 | tail -5
echo
echo "== Thu bind LDAP truc tiep bang ductho =="
if ! command -v ldapwhoami >/dev/null; then apt-get install -y -qq ldap-utils >/dev/null 2>&1; fi
DCIP=$(docker exec "$KC" getent hosts dc1.ad.lab.test 2>/dev/null | awk '{print $1}')
echo "dc1 IP (tu container): ${DCIP:-khong tim thay}"
echo ">>> Nhap MAT KHAU AD cua ductho (khong hien ky tu):"
LDAPTLS_REQCERT=never ldapwhoami -x -H "ldaps://${DCIP:-dc1.ad.lab.test}:636" -D 'ductho@ad.lab.test' -W 2>&1
echo "DIAG2_DONE"
