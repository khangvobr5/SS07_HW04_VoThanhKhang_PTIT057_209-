#!/bin/bash
# =============================================================================
# setup.sh — Triển khai cấu hình Nginx Reverse Proxy cho Spring Boot
# Chạy với quyền root hoặc dùng sudo
# =============================================================================

set -e  # Dừng ngay nếu có lỗi

echo "======================================================"
echo " Bài 4: Cấu hình Reverse Proxy Nginx – Spring Boot"
echo "======================================================"

# ── 1. Tạo thư mục web root và copy trang tĩnh ───────────────────────────────
echo "[1/5] Tạo thư mục /var/www/html và triển khai index.html..."
sudo mkdir -p /var/www/html
sudo cp index.html /var/www/html/index.html
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
echo "      ✓ index.html đã được sao chép vào /var/www/html/"

# ── 2. Copy file cấu hình vào sites-available ────────────────────────────────
echo "[2/5] Sao chép spring-proxy.conf vào /etc/nginx/sites-available/..."
sudo cp spring-proxy.conf /etc/nginx/sites-available/spring-proxy.conf
echo "      ✓ spring-proxy.conf đã được sao chép"

# ── 3. Tạo symlink sang sites-enabled ────────────────────────────────────────
echo "[3/5] Kích hoạt cấu hình (tạo symlink vào sites-enabled)..."
# Xóa symlink cũ nếu tồn tại
if [ -L /etc/nginx/sites-enabled/spring-proxy.conf ]; then
    sudo rm /etc/nginx/sites-enabled/spring-proxy.conf
fi
sudo ln -s /etc/nginx/sites-available/spring-proxy.conf \
           /etc/nginx/sites-enabled/spring-proxy.conf
echo "      ✓ Symlink đã được tạo"

# ── 4. Xóa cấu hình default nếu còn tồn tại (tránh conflict port 80) ─────────
echo "[4/5] Vô hiệu hóa site 'default' nếu đang bật..."
if [ -L /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
    echo "      ✓ Đã xóa site default khỏi sites-enabled"
else
    echo "      ✓ Không có site default cần xóa"
fi

# ── 5. Kiểm tra cú pháp và reload Nginx ──────────────────────────────────────
echo "[5/5] Kiểm tra cấu hình Nginx..."
sudo nginx -t

echo ""
echo "Reload dịch vụ Nginx..."
sudo systemctl reload nginx

echo ""
echo "======================================================"
echo " Triển khai hoàn tất!"
echo "======================================================"
echo ""
echo "Kiểm tra nhanh:"
echo "  curl -I http://localhost/          → Trang tĩnh (200 OK)"
echo "  curl -I http://localhost/api/health → Spring Boot backend"
