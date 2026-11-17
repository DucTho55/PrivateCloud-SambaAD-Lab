# Script dùng trong LAB (Mailcow / Keycloak / Nextcloud)

Chạy trên **cloud-lab-01** (`172.16.120.243`) bằng `sudo bash <script>`. Mỗi script ghi log vào `/tmp/<tên>.log`.

| Script | Việc làm | Hướng dẫn tương ứng |
|---|---|---|
| `mailcow-step1.sh` | Clone + cấu hình + khởi động Mailcow (web `127.0.0.1:8090`, tắt ClamAV) | [06-MailCow §1–2](../../Huong-dan-cau-hinh-Private-Cloud-SSO/06-MailCow.md) |
| `mailcow-step2.sh` | `/etc/hosts`, cấp cert `mail.ad.lab.test` bằng Cloud Lab Root CA, thêm vào HAProxy (tự sao lưu và khôi phục nếu lỗi) | [06-MailCow §3–5](../../Huong-dan-cau-hinh-Private-Cloud-SSO/06-MailCow.md) |
| `mailcow-step3.sh` | Cho `php-fpm-mailcow` phân giải `auth.ad.lab.test` và tin CA | [06-MailCow §6](../../Huong-dan-cau-hinh-Private-Cloud-SSO/06-MailCow.md) |
| `fix-route.sh` | Thêm và lưu vĩnh viễn route `10.250.10.2` qua dc1 | [05-Keycloak §2](../../Huong-dan-cau-hinh-Private-Cloud-SSO/05-Keycloak.md) |
| `nc-mail.sh` | Kiểm tra hộp thư, TLS IMAP/SMTP từ Nextcloud, cài app Mail | [07-Liên kết §5](../../Huong-dan-cau-hinh-Private-Cloud-SSO/07-Lien-ket-Mail-Keycloak-Nextcloud.md) |
| `diag-*.sh` | Chẩn đoán (chỉ đọc log, không thay đổi gì, không in secret) | Phần *Lỗi thường gặp* |
| `debug-401.sh` | Bật log DEBUG Keycloak tạm thời, tái hiện lỗi 401, rồi **tự khôi phục** (restart Keycloak 2 lần) | [07-Liên kết §1.4](../../Huong-dan-cau-hinh-Private-Cloud-SSO/07-Lien-ket-Mail-Keycloak-Nextcloud.md) |

> Script viết cho đúng môi trường LAB này (đường dẫn, IP, tên container). Đọc kỹ trước khi chạy ở nơi khác.
