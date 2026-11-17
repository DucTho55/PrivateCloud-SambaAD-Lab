# Security Notes — kiểm tra trước khi đưa lên GitHub

> **Chỉ dùng cho GitHub private repository**. Toàn bộ ảnh là dữ liệu LAB thực tế, có thông tin mạng nội bộ, giao diện quản trị, user names, domain và lịch sử lỗi.

- Kiểm tra từng ảnh trong `assets/` trước khi xuất bản. Nếu screenshot có mật khẩu, token OIDC, URL đăng nhập một lần, Client Secret, khóa riêng, biến môi trường bí mật, hay địa chỉ email cá nhân, **xóa hoặc làm mờ bản sao ảnh trước khi commit**.
- Không commit file `.env`, `/etc/haproxy/certs/lab.key`, `lab.pem`, bất kỳ file `*.key` nào hoặc dữ liệu Samba `sam.ldb`.
- Giá trị `root-ca.crt` là chứng chỉ công khai nhưng vẫn là nội dung PKI nội bộ; không cần đưa file CA vào GitHub công khai. Bộ hướng dẫn **không chứa CA/secret thực tế**.
- Với cấu hình `trusted_proxies`, chỉ tin cậy địa chỉ reverse proxy đã xác minh; không cho phép người dùng tự gửi header X-Forwarded-For giả.
- Build lại image Nextcloud trong tương lai phải pin version/digest và backup DB/volume để tránh auto-upgrade từ tag động `nextcloud:apache`.
- Đổi tài khoản LDAP bind sang service account có quyền đọc tối thiểu, không dùng user `test.lab01` làm bind lâu dài.
- Tạo admin Keycloak vĩnh viễn và xóa bootstrap temporary admin sau khi xác minh quyền.

## .gitignore gợi ý

```gitignore
.env
.env.*
*.key
*.p12
*.pfx
secrets/
backups/
*.sql
*.dump
```

Để đảm bảo không vô tình phát hành ảnh nhạy cảm, nên tạo repository PRIVATE ngay từ đầu; không public sau đó mà chưa kiểm duyệt lại ảnh.
