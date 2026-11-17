# Đưa bộ tài liệu lên GitHub

1. **Tạo repository PRIVATE** trên GitHub và chỉ mở quyền truy cập cho người có trách nhiệm.
2. Giải nén ZIP, mở thư mục `PrivateCloud-SambaAD-GitHub`, kiểm tra [Security Notes](docs/SECURITY.md) và từng ảnh cần công bố.
3. Trên PowerShell tại thư mục vừa giải nén:

```powershell
git init
git add .
git commit -m "docs: add samba ad and private cloud lab guides"
git branch -M main
git remote add origin https://github.com/YOUR_ORG/YOUR_PRIVATE_REPO.git
git push -u origin main
```

Nếu repository đã tồn tại, copy nội dung vào bản clone và dùng `git add`, `git commit`, `git push` trên nhánh phù hợp; không chạy `git init` một lần nữa. Nếu chính sách công ty yêu cầu GitLab nội bộ, làm tương tự với remote GitLab thay vì GitHub.

**Lưu ý:** Bộ ảnh có dung lượng lớn và có thể chứa thông tin nội bộ. Không up trước khi kiểm tra phân quyền repository và dữ liệu nhạy cảm.
