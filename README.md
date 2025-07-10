# 🏸 Badminton Shop - Express.js E-commerce

<p align="center">
  <img src="https://img.shields.io/badge/Node.js-18.x-green" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Express.js-4.x-blue" alt="Express.js"/>
  <img src="https://img.shields.io/badge/MongoDB-Atlas-yellow" alt="MongoDB"/>
  <img src="https://img.shields.io/badge/Cloudinary-Image%20Upload-orange" alt="Cloudinary"/>
  <img src="https://img.shields.io/badge/JWT-Authentication-red" alt="JWT"/>
  <img src="https://img.shields.io/badge/Bootstrap-5.3-purple" alt="Bootstrap"/>
</p>

<p align="center">
  <strong>Lightweight E-commerce Platform with JWT Authentication, Cloudinary Image Upload, and Admin Panel</strong>
</p>

## 📋 Mô tả

Badminton Shop là một ứng dụng e-commerce nhẹ được xây dựng với Express.js, EJS templating, và Bootstrap. Ứng dụng được tối ưu cho EC2 Free Tier (1 vCPU, 1GB RAM) với các tính năng:

- 🔐 **JWT Authentication** với httpOnly cookies
- 👨‍💼 **Admin Panel** với CRUD operations
- 📸 **Cloudinary Image Upload** cho sản phẩm
- 🎨 **Modern UI** với Bootstrap và pastel blue theme
- 🐳 **Docker Containerization** với Nginx reverse proxy
- 🔄 **Jenkins CI/CD Pipeline** tự động - **ONE CLICK DEPLOYMENT**
- 📱 **Responsive Design** cho mobile và desktop

## 🚀 Quick Start

### Local Development

```bash
# Clone repository
git clone https://github.com/your-username/badminton-shop-express.git
cd badminton-shop-express

# Install dependencies
npm install

# Create .env file
cp .env.template .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### Environment Variables

Tạo file `.env` với các biến sau:

```env
# Database Configuration
MONGODB_URI=mongodb://localhost:27017/badminton_shop

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Application Configuration
NODE_ENV=development
PORT=3000
```

## 🐳 Docker Deployment

### Local Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down
```

### Manual Docker Commands

```bash
# Build image
docker build -t badminton-shop .

# Run container
docker run -d --name badminton-shop-app -p 3000:3000 --env-file .env badminton-shop

# View logs
docker logs badminton-shop-app

# Stop container
docker stop badminton-shop-app
docker rm badminton-shop-app
```

## 🔄 Hướng dẫn khởi động lại website khi máy chủ tắt hoặc khởi động lại

Khi EC2/VPS/server bị tắt hoặc reboot, website sẽ **TỰ ĐỘNG KHỞI ĐỘNG LẠI** nhờ systemd service.

Nếu cần khởi động lại thủ công:

1. **Đăng nhập SSH vào server, cd vào thư mục dự án:**
   ```bash
   ssh -i your-key.pem ubuntu@your-ec2-public-ip
   cd /opt/badminton-shop
   ```

2. **Restart containers:**
   ```bash
   docker-compose restart
   ```

3. **Hoặc restart service:**
   ```bash
   sudo systemctl restart badminton-shop.service
   ```

4. **Kiểm tra status:**
   ```bash
   sudo systemctl status badminton-shop.service
   docker-compose ps
   ```

## 🚀 ONE-CLICK DEPLOYMENT với Jenkins (AWS EC2 Free Tier)

### 🎯 **Mục tiêu: Chỉ cần bấm "Build Now" trên Jenkins, mọi thứ sẽ tự động hoàn thành!**

<h3 align="center">🚀 ONE-CLICK DEPLOYMENT với Jenkins (AWS EC2 Free Tier)</h3>

### Yêu cầu hệ thống

1. **AWS EC2 instance (Free Tier):**
   - Ubuntu Server 24.04 LTS (khuyến nghị, nhẹ, ổn định)
   - 1 vCPU, 1GB RAM, 8GB storage (Free Tier)
   - Security group mở các port:
     - 22 (SSH)
     - 80 (HTTP)
     - 443 (HTTPS)
     - 8080 (Jenkins)

2. **GitHub repository** với mã nguồn project

### Các bước cài đặt

#### 1. Setup EC2 (Chỉ làm 1 lần)

```bash
# SSH vào EC2
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Chạy script setup tự động
wget https://raw.githubusercontent.com/your-repo/badminton-shop-express/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
./setup-ec2.sh
```

#### 2. Configure Jenkins (Chỉ làm 1 lần)

1. **Truy cập Jenkins tại http://your-ec2-ip:8080**
2. **Lấy mật khẩu admin lần đầu:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
3. **Cài đặt plugin đề xuất**
4. **Tạo user admin**
5. **Cài thêm các plugin:**
   - Docker Pipeline
   - GitHub Integration
   - Credentials Plugin
   - Blue Ocean

#### 3. Thêm Jenkins Credentials (Chỉ làm 1 lần)

**Hướng dẫn chi tiết:**

1. Truy cập Jenkins Dashboard > Manage Jenkins > Manage Credentials
2. Chọn (hoặc tạo) domain `Global`
3. Nhấn **Add Credentials**
4. Ở mục **Kind**, chọn **Secret text**
5. Ở mục **Secret**, nhập giá trị tương ứng với biến môi trường
6. Ở mục **ID**, nhập đúng tên biến môi trường
7. Nhấn **OK** để lưu lại

**Lặp lại các bước trên cho từng biến sau:**

| ID (tên biến)           | Giá trị cần nhập (Secret)                  |
|-------------------------|--------------------------------------------|
| MONGODB_URI             | MongoDB Atlas connection string            |
| JWT_SECRET              | JWT secret key                             |
| CLOUDINARY_CLOUD_NAME   | Cloudinary cloud name                      |
| CLOUDINARY_API_KEY      | Cloudinary API key                         |
| CLOUDINARY_API_SECRET   | Cloudinary API secret                      |

#### 4. Configure GitHub Webhook (Chỉ làm 1 lần)

1. Go to your GitHub repository > Settings > Webhooks
2. Add webhook:
   - Payload URL: `http://your-ec2-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Select: Just the push event
   - Active: ✓

#### 5. Create Jenkins Pipeline (Chỉ làm 1 lần)

1. Go to Jenkins Dashboard > New Item
2. Enter name and select "Pipeline"
3. Configure:
   - **GitHub project**: [Your repository URL]
   - **Build Triggers**: GitHub hook trigger for GITScm polling
   - **Pipeline**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: [Your repository URL]
   - **Credentials**: Add your GitHub credentials
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile`

## 🎉 **ONE-CLICK DEPLOYMENT - Sử dụng**

### **Sau khi setup xong, chỉ cần:**

1. **Bấm "Build Now" trên Jenkins**
2. **Chờ 5-10 phút**
3. **Truy cập website tại: https://your-ec2-ip**

### **Jenkins sẽ tự động làm mọi thứ:**

✅ **Setup Environment** - Tạo thư mục, copy files, set permissions  
✅ **Generate SSL** - Tạo SSL certificates tự động  
✅ **Install Dependencies** - Cài đặt Node.js packages  
✅ **Build Docker Image** - Build image với multi-stage  
✅ **Security Scan** - Kiểm tra bảo mật  
✅ **Deploy Application** - Chạy containers với docker-compose  
✅ **Setup Auto-restart** - Tạo systemd service tự động khởi động  
✅ **Health Check** - Kiểm tra ứng dụng hoạt động  
✅ **Cleanup** - Dọn dẹp images cũ  

### **Kết quả sau khi build thành công:**

- 🌐 **Application URL**: `https://your-ec2-ip`
- 🔧 **Jenkins URL**: `http://your-ec2-ip:8080`
- 📊 **Status Page**: `http://your-ec2-ip/status.html`
- ✅ **Auto-restart**: Website tự động khởi động khi server reboot

## 🔧 Sử dụng

1. **Pipeline sẽ tự động trigger khi push vào main branch**
2. **Có thể trigger thủ công từ Jenkins dashboard**
3. **Monitor quá trình build trong Jenkins**

## 🔍 Khắc phục sự cố

### 1. Nếu Jenkins không truy cập được Docker:
```bash
# Đảm bảo cả user ubuntu và jenkins đều thuộc group docker
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
# Đăng xuất SSH và đăng nhập lại, hoặc reboot EC2
sudo reboot
```

### 2. Nếu nginx config lỗi:
```bash
docker exec -it badminton-shop-nginx nginx -t
```

### 3. Xem log container:
```bash
docker-compose logs -f
```

### 4. Out of memory (EC2 Free Tier):
```bash
# Tăng swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Thêm vào /etc/fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 5. Port đã được sử dụng:
```bash
# Kiểm tra port
sudo netstat -tulpn | grep :80

# Kill process
sudo kill -9 <PID>
```

### 6. Restart service thủ công:
```bash
# Restart application service
sudo systemctl restart badminton-shop.service

# Check status
sudo systemctl status badminton-shop.service

# View logs
sudo journalctl -u badminton-shop.service -f
```

## 🔒 Lưu ý bảo mật

1. **Luôn dùng Jenkins credentials** cho dữ liệu nhạy cảm
2. **Thường xuyên update hệ thống** bằng `sudo apt update && sudo apt upgrade -y`
3. **Đặt mật khẩu mạnh** cho tất cả dịch vụ
4. **Có thể dùng AWS Secrets Manager** cho production
5. **Kiểm tra kỹ security group** của EC2, chỉ mở port cần thiết
6. **SSL certificates**: Sử dụng Let's Encrypt cho production

## 🛠️ Bảo trì

### 1. Backup Jenkins:
```bash
sudo tar -zcvf jenkins_backup.tar.gz /var/lib/jenkins
```

### 2. Xoá image Docker cũ:
```bash
docker system prune -a
```

### 3. Kiểm tra dung lượng ổ đĩa:
```bash
df -h
```

### 4. Monitoring script:
```bash
# Chạy monitoring
./monitor.sh

# Backup
./backup.sh
```

### 5. Log rotation:
```bash
# Xem logs
docker-compose logs --tail=100

# Rotate logs
sudo logrotate -f /etc/logrotate.d/badminton-shop
```

## 📊 URLs sau khi deploy

- **Application**: `https://your-ec2-public-ip`
- **Jenkins**: `http://your-ec2-public-ip:8080`
- **Status Page**: `http://your-ec2-public-ip/status.html`

## 🎯 Tính năng chính

### ✅ Tối ưu cho EC2 Free Tier
- **Multi-stage Docker build** giảm kích thước image
- **Memory optimization** cho Node.js
- **Automatic cleanup** của Docker images
- **Swap file** cho memory management

### ✅ Security & Performance
- **SSL/TLS encryption** với self-signed certificates
- **Security headers** (HSTS, CSP, XSS Protection)
- **Rate limiting** cho API và login
- **Gzip compression** cho static files
- **Health checks** và auto-restart

### ✅ Monitoring & Maintenance
- **System monitoring** script
- **Automatic backup** với rotation
- **Log rotation** và management
- **Status page** với real-time monitoring

### ✅ CI/CD Pipeline
- **Jenkins automation** với multi-stage pipeline
- **Security scanning** với Trivy
- **Automatic deployment** với health checks
- **Rollback capability** với image tagging
- **ONE-CLICK DEPLOYMENT** - Không cần can thiệp thủ công

## 📞 Support

Nếu gặp vấn đề:
1. **Kiểm tra logs**: `docker-compose logs -f`
2. **Kiểm tra system**: `./monitor.sh`
3. **Restart services**: `sudo systemctl restart jenkins`
4. **Rebuild containers**: `docker-compose down && docker-compose up -d --build`

## 📝 License

MIT License - see LICENSE file for details. 