# Troubleshooting — các lỗi ghi nhận bằng ảnh

| Lỗi / triệu chứng | Nguyên nhân kiểm tra được | Xử lý đã thực hiện hoặc hướng kiểm tra |
|---|---|---|
| `Client nextcloud already exists` | Client tồn tại trong Realm `cloud-lab` | Mở Client cũ, không tạo mới |
| `localhost:8080` trong Root/Redirect URI | Cấu hình cũ không đúng DNS LAB | Sửa Root/Home/Redirect thành HTTPS `cloud.ad.lab.test` |
| `Access forbidden` ở Social Login | `sociallogin` chưa cài | `occ app:install sociallogin` + kiểm tra app:enabled |
| `permission denied /var/run/docker.sock` | User `cloudadmin` chưa có quyền Docker | Dùng `sudo docker ...` |
| `No such container: TEN_CONTAINER` | Gõ nguyên tên mẫu | Dùng tên thật `cloud-lab-nextcloud-app-1` |
| `curl: (60) SSL certificate problem` | Nextcloud thiếu `Cloud Lab Root CA` | Xác minh CA, thêm vào image và cập nhật kho tin cậy |
| `unable to verify the first certificate` | Trust chain thiếu Root CA | Đối chiếu issuer và verify với `root-ca.crt` |
| `Too many requests` / HTTP 429 | Nhiều lần thử, lệch IP reverse proxy | Kiểm tra `trusted_proxies`, XFF, bộ đếm; reset đúng IP sau kiểm tra |
| `LDAP error code 49 ... data 52e` | Sai LDAP bind credentials sau đổi mật khẩu `test.lab01` | Đổi **Bind credentials** của provider cũ, Test authentication |
| `Unexpected error ... identity provider` | Log Keycloak cho thấy LDAP query/bind thất bại | Đọc log và sửa Bind credentials, không thay OIDC client nếu không cần |
| `Unable to open /var/lib/samba/private/sam.ldb` | Chạy samba-tool thiếu file config/namespace LAB | `sudo ip netns exec samba-lab samba-tool ... --configfile=/opt/samba-ad-lab/host-provision/etc/smb.conf` |
| `samba-tool: command not found` trên cloud-lab-01 | Chạy lệnh Samba trên nhầm VM | Sang `labadmin@dc1` và dùng namespace |
| HAProxy `backend nextcloud_backend has no server available!` | App container đang recreate, có thể gián đoạn tạm thời | Kiểm tra `docker compose ps`, `curl localhost:8080/status.php` |

## Lệnh chẩn đoán gọn

```bash
# Trên cloud-lab-01
sudo docker ps --format 'table {{.Names}}\t{{.Image}}'
sudo docker logs --since 30m cloud-lab-keycloak-keycloak-1 2>&1 | tail -n 120
sudo docker exec -u www-data cloud-lab-nextcloud-app-1 php occ status
sudo docker exec cloud-lab-nextcloud-app-1 curl -Iv --max-time 15 https://auth.ad.lab.test
curl -i --max-time 15 http://127.0.0.1:8080/status.php
```

```bash
# Trên dc1 — xem user trong namespace/provision riêng
sudo ip netns exec samba-lab samba-tool user show test.lab01 \
 --configfile=/opt/samba-ad-lab/host-provision/etc/smb.conf
```

## Tránh các cách sửa gây rủi ro

- Không dùng `curl -k` làm giải pháp cuối cho SSO.
- Không tắt bảo vệ brute force toàn bộ ứng dụng.
- Không chạy `docker compose down -v` vì sẽ xóa named volumes.
- Không xóa user LDAP rồi import lại nếu chưa xác định lỗi.
- Không copy `lab.pem` hoặc `lab.key` vào thư mục CA dùng chung.
