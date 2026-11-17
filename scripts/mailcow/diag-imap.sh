#!/bin/bash
# Chan doan IMAP login cua ductho (chi doc log)
exec > >(tee /tmp/diag-imap.log) 2>&1
cd /opt/mailcow-dockerized
echo "== Dovecot (15 phut) =="
docker compose logs --since 15m dovecot-mailcow 2>&1 | grep -iE 'ductho|auth|fail|login' | tail -25
echo "== php-fpm auth (15 phut) =="
docker compose logs --since 15m php-fpm-mailcow 2>&1 | grep -iE 'ductho|auth|imap|app_?pass' | tail -15
echo "== Netfilter (ban IP) =="
docker compose logs --since 30m netfilter-mailcow 2>&1 | tail -10
echo "DIAG_IMAP_DONE"
