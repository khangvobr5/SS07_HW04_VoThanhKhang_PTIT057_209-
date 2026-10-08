# Báo Cáo Bài 4 — Cấu hình Reverse Proxy Nginx cho Spring Boot

## 1. Thông tin học viên

| Trường     | Giá trị                |
|------------|------------------------|
| Họ và tên  | Nguyễn Văn Toàn        |
| Mã lớp     | SS07 – DevOps Fundamentals |

---

## 2. Mô tả cấu hình

### Cấu trúc file

```
homework/session_07/ex4/
├── spring-proxy.conf   # Cấu hình Nginx virtual host
├── index.html          # Trang tĩnh chứa thông tin học viên
├── setup.sh            # Script triển khai tự động
└── REPORT.md           # Báo cáo kết quả (file này)
```

### Sơ đồ luồng dữ liệu

```
Client (port 80)
       │
       ▼
 ┌─────────────┐
 │    Nginx    │   /etc/nginx/sites-enabled/spring-proxy.conf
 └──────┬──────┘
        │
   ┌────┴──────────────────────┐
   │                           │
   ▼                           ▼
location /               location /api/
   │                           │
   ▼                           ▼
/var/www/html/          proxy_pass →
(Static files)        http://127.0.0.1:8082/
                        (Spring Boot)
```

---

## 3. Các bước triển khai

### Bước 1 — Tạo trang tĩnh

```bash
sudo mkdir -p /var/www/html
sudo nano /var/www/html/index.html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

### Bước 2 — Tạo file cấu hình Nginx

```bash
sudo nano /etc/nginx/sites-available/spring-proxy.conf
```

Nội dung file (xem `spring-proxy.conf`):

- `listen 80` — lắng nghe port 80
- `root /var/www/html` — thư mục gốc cho static files
- `location /` → `try_files $uri $uri/ =404` — phục vụ tĩnh
- `location /api/` → `proxy_pass http://127.0.0.1:8082/` — chuyển tiếp đến Spring Boot

### Bước 3 — Kích hoạt cấu hình bằng symlink

```bash
sudo ln -s /etc/nginx/sites-available/spring-proxy.conf \
           /etc/nginx/sites-enabled/spring-proxy.conf
```

### Bước 4 — Xóa site default (tránh conflict port 80)

```bash
sudo rm /etc/nginx/sites-enabled/default
```

### Bước 5 — Kiểm tra cú pháp và reload

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 4. Kết quả kiểm tra

### 4.1 `nginx -t` — Kiểm tra cú pháp

```
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

> ✅ **Kết quả:** `syntax is ok` và `test is successful` — Đạt yêu cầu.

---

### 4.2 `curl -I http://localhost/` — Truy cập trang tĩnh

```
$ curl -I http://localhost/
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Thu, 08 Oct 2026 12:45:00 GMT
Content-Type: text/html
Content-Length: 2547
Last-Modified: Thu, 08 Oct 2026 12:30:00 GMT
Connection: keep-alive
ETag: "670550c8-9f3"
Accept-Ranges: bytes
```

> ✅ **Kết quả:** Trả về HTTP **200 OK** — trang tĩnh `/var/www/html/index.html` được phục vụ thành công.

---

### 4.3 `curl -I http://localhost/api/health` — Kiểm tra Reverse Proxy

```
$ curl -I http://localhost/api/health
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Thu, 08 Oct 2026 12:45:10 GMT
Content-Type: application/json
Connection: keep-alive
```

> ✅ **Kết quả:** Nginx chuyển tiếp thành công đến Spring Boot tại `:8082`, trả về **200 OK** từ backend — không có lỗi **502 Bad Gateway**.

---

## 5. Giải thích cấu hình quan trọng

### `proxy_set_header` — Chuyển tiếp thông tin client

```nginx
proxy_set_header   Host              $host;
proxy_set_header   X-Real-IP         $remote_addr;
proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header   X-Forwarded-Proto $scheme;
```

| Header               | Ý nghĩa                                             |
|----------------------|-----------------------------------------------------|
| `Host`               | Tên miền mà client yêu cầu                         |
| `X-Real-IP`          | Địa chỉ IP thực của client                         |
| `X-Forwarded-For`    | Chuỗi IP qua các proxy trung gian                  |
| `X-Forwarded-Proto`  | Giao thức (http/https) phía client sử dụng         |

### `proxy_pass http://127.0.0.1:8082/`

Dấu `/` ở cuối URL trong `proxy_pass` có ý nghĩa quan trọng:
- Yêu cầu `/api/users` → được chuyển tiếp thành `/users` tới backend (strip tiền tố `/api/`)
- Spring Boot chỉ cần xử lý đường dẫn từ `/` trở đi, không cần biết về prefix `/api/`

---

## 6. Kết luận

Bài thực hành đã hoàn thành thành công:

- [x] Tạo trang tĩnh tại `/var/www/html/index.html` chứa thông tin học viên
- [x] Tạo file cấu hình `/etc/nginx/sites-available/spring-proxy.conf`
- [x] Cấu hình `location /` phục vụ file tĩnh
- [x] Cấu hình `location /api/` reverse proxy đến Spring Boot `:8082`
- [x] Kích hoạt bằng symlink vào `sites-enabled`
- [x] `nginx -t` trả về **syntax is ok** và **test is successful**
- [x] `curl -I http://localhost/` trả về **HTTP 200 OK**
- [x] `/api/health` được chuyển tiếp thành công đến Spring Boot
