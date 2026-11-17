# Checklist kiểm chứng sau triển khai

## VM và Samba AD

- [ ] Proxmox VM `dc1`/VM Windows được gán NIC đúng VLAN/IP.
- [ ] `sudo ip netns exec samba-lab ...` truy cập được dịch vụ Samba.
- [ ] DNS `auth.ad.lab.test`, `cloud.ad.lab.test` về đúng `172.16.120.243`.
- [ ] ADUC truy vấn được `OU=LAB-TEST` và user `test.lab01`.
- [ ] `samba-tool user show test.lab01 --configfile=...` trả đúng DN.

## Keycloak + LDAP

- [ ] Đúng Realm `cloud-lab`, không phải `master`.
- [ ] LDAP Provider cũ đã cập nhật Bind credentials sau khi reset `test.lab01`.
- [ ] Test connection thành công.
- [ ] Test authentication thành công.
- [ ] Không còn `LDAP error 49 / data 52e` ở lần đăng nhập mới.

## Nextcloud + HTTPS

- [ ] `docker compose ps` app/cron/db/redis đều Up.
- [ ] `/status.php` trả HTTP 200, `installed=true`, `maintenance=false`.
- [ ] Docker image App và Cron đều `cloud-lab-nextcloud:ca-v1`.
- [ ] CA có trong image mới; `curl` verify ok không dùng `-k`.
- [ ] Social Login `sociallogin` được bật.
- [ ] Client `nextcloud` OIDC redirect URI chính xác.
- [ ] Người dùng thử nghiệm đăng nhập bằng InPrivate và vào Files.
- [ ] Kiểm tra user ID Nextcloud tránh tạo hai tài khoản trùng.

## Bảo mật vận hành

- [ ] Repo GitHub đặt PRIVATE và screenshot được duyệt.
- [ ] Admin Keycloak không còn là temporary bootstrap admin.
- [ ] Mật khẩu tài khoản LDAP bind tách khỏi người dùng test.
- [ ] Backup Docker named volumes và database trước khi thay image.
- [ ] Ghi lịch kiểm tra certificate expiration và log ứng dụng.
