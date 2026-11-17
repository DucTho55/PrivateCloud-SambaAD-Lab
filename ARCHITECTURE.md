# Kiến trúc hai dự án

## Phạm vi

**Dự án 01 — Samba AD LAB:** Máy `dc1` được xây dựng trên môi trường Proxmox, namespace `samba-lab`, cơ sở dữ liệu được provision vào `/opt/samba-ad-lab/host-provision`, DNS AD `10.250.10.2`, domain `ad.lab.test`. Máy Windows Server trong LAB dùng RSAT/ADUC để thao tác OU, group và user.

**Dự án 02 — Private Cloud:** `cloud-lab-01` cung cấp Nextcloud, Keycloak, Postgres, Redis qua Docker; HAProxy lắng nghe `172.16.120.243:443` và chuyển đến `127.0.0.1:8080` (Nextcloud), `127.0.0.1:8081` (Keycloak), sử dụng chứng chỉ cấp bởi `Cloud Lab Root CA`.

## Cấu trúc đường đi

```text
Người dùng trình duyệt
        |
        v
cloud.ad.lab.test  ---> HAProxy :443 ---> Nextcloud app :8080 (Docker)
        |                                           |
        |                  Social Login / OIDC      |
        +-------------------------------------------+
                             |
                             v
                  auth.ad.lab.test
                         HAProxy ---> Keycloak :8081 (Docker)
                                          |
                                     LDAPS/LDAP
                                          |
                                          v
                                Samba AD (dc1)
                                  ad.lab.test
```

| Dịch vụ | Địa chỉ / đường dẫn | Ghi chú |
|---|---|---|
| LDAP/DC | `dc1` / `10.250.10.2` | Namespace `samba-lab`; địa chỉ đã ghi nhận khi kiểm tra DNS |
| SSO | `https://auth.ad.lab.test` | OIDC Realm `cloud-lab` |
| Cloud | `https://cloud.ad.lab.test` | Nextcloud Social Login |
| HAProxy config | `/etc/haproxy/haproxy.cfg` | Có cấu hình `X-Forwarded-For` |
| Root CA | `/etc/haproxy/lab-ca/root-ca.crt` | CA công khai, không phải private key |
| HAProxy certificate | `/etc/haproxy/certs/lab.crt` và `lab.pem` | `lab.pem` có thể chứa private key, không copy công khai |
| Nextcloud Compose | `/opt/cloud-lab/nextcloud/compose.yaml` | `app`, `cron`, `db`, `redis` |
| Keycloak Compose | `/opt/cloud-lab/keycloak/compose.yaml` | Keycloak + PostgreSQL |

## Bằng chứng ảnh chụp

Các ảnh được sắp xếp trong [gallery](gallery/README.md) theo ngày. Tài liệu từng dự án cũng nhúng ảnh quan trọng sát các bước thao tác.
