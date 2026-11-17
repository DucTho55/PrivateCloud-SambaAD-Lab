#!/bin/bash
# Khoi phuc route toi Samba AD (dc1 = 10.250.10.2 qua VM 2001 = 172.16.120.242)
# Route cu duoc them tay (ip route) nen mat khi VM 2000 reboot. Lam ca 2 viec:
#  1) them lai ngay  2) luu vinh vien bang drop-in systemd-networkd (khong sua netplan)
set -euo pipefail
exec > >(tee /tmp/fix-route.log) 2>&1
ip route replace 10.250.10.2/32 via 172.16.120.242 dev ens18
mkdir -p /etc/systemd/network/10-netplan-ens18.network.d
cat > /etc/systemd/network/10-netplan-ens18.network.d/50-ad-lab-route.conf <<'EOF'
# Route toi Samba AD dc1.ad.lab.test (netns tren VM 2001)
[Route]
Destination=10.250.10.2/32
Gateway=172.16.120.242
EOF
ip route get 10.250.10.2
for p in 389 636; do timeout 4 bash -c "</dev/tcp/10.250.10.2/$p" 2>/dev/null && echo "port $p OK" || echo "port $p FAIL"; done
timeout 5 docker exec cloud-lab-keycloak-keycloak-1 bash -c 'echo > /dev/tcp/10.250.10.2/636' && echo "KEYCLOAK -> LDAPS OK" || echo "KEYCLOAK -> LDAPS FAIL"
echo "ROUTE_DONE"
