#!/bin/bash

# EC2 Ubuntu 24.04 LTS Setup Script for Badminton Shop
# This script sets up a complete CI/CD environment with Jenkins, Docker, and Nginx
# Designed for one-click deployment from Jenkins

set -e

echo "🚀 Starting EC2 setup for Badminton Shop..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    tree \
    vim \
    ufw \
    openssl

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Java (required for Jenkins)
echo "☕ Installing Java..."
sudo apt install -y openjdk-17-jdk

# Install Jenkins
echo "🔧 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Node.js and npm
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 for process management
sudo npm install -g pm2

# Install Nginx
echo "🌐 Installing Nginx..."
sudo apt install -y nginx

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8080  # Jenkins
sudo ufw allow 3000  # Application (if needed)

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/badminton-shop
sudo chown $USER:$USER /opt/badminton-shop

# Create environment file template
echo "📝 Creating environment file template..."
cat > /opt/badminton-shop/.env.template << 'EOF'
# Database Configuration
MONGODB_URI=mongodb://localhost:27017/badminton_shop

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Application Configuration
NODE_ENV=production
PORT=3000
EOF

# Create monitoring script
echo "📝 Creating monitoring script..."
cat > /opt/badminton-shop/monitor.sh << 'EOF'
#!/bin/bash

# Monitoring script for Badminton Shop

echo "📊 System Status:"
echo "=================="

# Docker containers
echo "🐳 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# System resources
echo "💻 System Resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"

echo ""

# Application health
echo "🏥 Application Health:"
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✅ Application is healthy"
else
    echo "❌ Application is not responding"
fi

echo ""

# Jenkins status
echo "🔧 Jenkins Status:"
if sudo systemctl is-active --quiet jenkins; then
    echo "✅ Jenkins is running"
else
    echo "❌ Jenkins is not running"
fi
EOF

chmod +x /opt/badminton-shop/monitor.sh

# Create backup script
echo "📝 Creating backup script..."
cat > /opt/badminton-shop/backup.sh << 'EOF'
#!/bin/bash

# Backup script for Badminton Shop

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "💾 Creating backup..."

# Backup application files
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C /opt badminton-shop

# Backup Docker volumes (if any)
docker run --rm -v badminton-shop_data:/data -v $BACKUP_DIR:/backup alpine tar -czf /backup/data_$DATE.tar.gz -C /data .

echo "✅ Backup created: $BACKUP_DIR/app_$DATE.tar.gz"
echo "✅ Data backup created: $BACKUP_DIR/data_$DATE.tar.gz"

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/badminton-shop/backup.sh

# Create a simple status page
echo "📝 Creating status page..."
sudo tee /var/www/html/status.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Badminton Shop - Server Status</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .healthy { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .unhealthy { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏸 Badminton Shop - Server Status</h1>
        <div class="status info">
            <strong>Server:</strong> EC2 Ubuntu 24.04 LTS<br>
            <strong>Last Updated:</strong> <span id="timestamp"></span>
        </div>
        <div id="status-content">
            <p>Loading status...</p>
        </div>
    </div>
    <script>
        function updateStatus() {
            fetch('/health')
                .then(response => {
                    if (response.ok) {
                        document.getElementById('status-content').innerHTML = 
                            '<div class="status healthy">✅ Application is running normally</div>';
                    } else {
                        throw new Error('Application not responding');
                    }
                })
                .catch(error => {
                    document.getElementById('status-content').innerHTML = 
                        '<div class="status unhealthy">❌ Application is not responding</div>';
                });
            
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        }
        
        updateStatus();
        setInterval(updateStatus, 30000); // Update every 30 seconds
    </script>
</body>
</html>
EOF

# Set up automatic updates
echo "📝 Setting up automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Get Jenkins initial admin password
echo "🔑 Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo ""
echo "🎉 EC2 setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "2. Install suggested plugins in Jenkins"
echo "3. Create admin user in Jenkins"
echo "4. Create a new pipeline job pointing to your Git repository"
echo "5. Configure environment variables in Jenkins"
echo ""
echo "📁 Application directory: /opt/badminton-shop"
echo "🔧 Monitoring script: /opt/badminton-shop/monitor.sh"
echo "💾 Backup script: /opt/badminton-shop/backup.sh"
echo ""
echo "⚠️  Don't forget to:"
echo "- Configure your environment variables in /opt/badminton-shop/.env"
echo "- Set up your Git repository credentials in Jenkins"
echo "- Configure your domain name and SSL certificates for production"
echo ""
echo "🔄 You may need to log out and log back in for Docker group permissions to take effect." 