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

Khi EC2/VPS/server bị tắt hoặc reboot, bạn cần khởi động lại website thủ công như sau:

1. Đăng nhập SSH vào server, cd vào thư mục dự án.
2. Nếu container cũ còn, xóa trước:
   ```bash
   docker rm -f badminton-web
   ```
3. Chạy lại container:
   ```bash
   docker run -d --name badminton-web -p 80:80 -p 443:443 --env-file .env badminton-web:latest
   ```
4. Nếu cần build lại image:
   ```bash
   docker build -t badminton-web:latest .
   docker run -d --name badminton-web -p 80:80 -p 443:443 --env-file .env badminton-web:latest
   ```
5. Kiểm tra log:
   ```bash
   docker logs badminton-web
   ```
6. Truy cập lại web qua IP hoặc domain.

**Khuyến nghị:** Nên dùng Docker restart policy (`--restart unless-stopped`) để container tự khởi động lại khi máy chủ reboot.

---

# 🚀 CI/CD Setup Guide with Jenkins (AWS EC2 Free Tier)

## Yêu cầu hệ thống

1. AWS EC2 instance (Free Tier):
   - Ubuntu Server 24.04 LTS (khuyến nghị, nhẹ, ổn định)
   - 1 vCPU, 1GB RAM, 8GB storage (Free Tier)
   - Security group mở các port:
     - 22 (SSH)
     - 80 (HTTP)
     - 443 (HTTPS)
     - 8080 (Jenkins)

2. GitHub repository với mã nguồn project

## Các bước cài đặt

### 1. Install Jenkins & Java (latest stable)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install latest OpenJDK (JDK 21 LTS)
sudo apt install openjdk-21-jdk -y

# Verify Java version
java -version

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 2. Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add both ubuntu and jenkins user vào group docker (fix lỗi permission)
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# Đăng xuất SSH và đăng nhập lại để group có hiệu lực (hoặc reboot)
exit
# Sau đó SSH lại vào EC2

# Restart Jenkins để nhận quyền docker
sudo systemctl restart jenkins
```

### 3. Configure Jenkins

- Truy cập Jenkins tại http://your-ec2-ip:8080
- Lấy mật khẩu admin lần đầu:
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
- Cài đặt plugin đề xuất
- Tạo user admin
- Cài thêm các plugin:
  - Docker Pipeline
  - GitHub Integration
  - Credentials Plugin

### 4. Thêm Jenkins Credentials (biến môi trường bảo mật)

**Hướng dẫn chi tiết:**

1. Truy cập Jenkins Dashboard > Manage Jenkins > Manage Credentials
2. Chọn (hoặc tạo) domain Global (nếu chưa có, chọn (global) hoặc Global credentials (unrestricted))
3. Nhấn Add Credentials (Thêm thông tin xác thực)
4. Ở mục Kind, chọn Secret text
5. Ở mục Secret, nhập giá trị tương ứng với biến môi trường (ví dụ: connection string MongoDB, JWT secret, v.v.)
6. Ở mục ID, nhập đúng tên biến môi trường (ví dụ: MONGODB_URI, JWT_SECRET, ...)
7. Nhấn OK để lưu lại

Lặp lại các bước trên cho từng biến sau:

| ID (tên biến)           | Giá trị cần nhập (Secret)                  |
|-------------------------|--------------------------------------------|
| MONGODB_URI             | MongoDB Atlas connection string            |
| SESSION_SECRET          | Chuỗi bí mật cho session (bắt buộc)        |
| CLOUDINARY_CLOUD_NAME   | Cloudinary cloud name                      |
| CLOUDINARY_API_KEY      | Cloudinary API key                         |
| CLOUDINARY_API_SECRET   | Cloudinary API secret                      |
| JWT_SECRET              | JWT secret key                             |
| PORT                    | 3000 (hoặc để trống nếu dùng mặc định)     |

**Lưu ý:**
- Phải nhập đúng ID (không có dấu cách, không thêm ký tự thừa)
- Không public các giá trị này lên GitHub
- Sau khi tạo xong, Jenkinsfile sẽ tự động lấy các giá trị này để build .env cho ứng dụng

### 5. Configure GitHub Webhook

1. Go to your GitHub repository > Settings > Webhooks
2. Add webhook:
   - Payload URL: http://your-ec2-ip:8080/github-webhook/
   - Content type: application/json
   - Select: Just the push event
   - Active: ✓

### 6. Create Jenkins Pipeline

1. Go to Jenkins Dashboard > New Item
2. Enter name and select "Pipeline"
3. Configure:
   - GitHub project: [Your repository URL]
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline: Pipeline script from SCM
   - SCM: Git
   - Repository URL: [Your repository URL]
   - Credentials: Add your GitHub credentials
   - Branch Specifier: */main
   - Script Path: Jenkinsfile

### 7. Lưu ý tối ưu cho EC2 Free Tier
- Dockerfile đã tối ưu, chỉ cài production dependencies.
- Nếu gặp lỗi thiếu RAM, hãy bật swap:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

- Chỉ chạy 2 container: app (Node.js) và nginx (proxy).
- Không chạy thêm database, CI/CD tool hoặc service nào khác trên cùng máy.

---

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