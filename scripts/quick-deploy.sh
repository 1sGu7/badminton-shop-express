#!/bin/bash

# Quick deployment script for Badminton Shop
# This script can be used for manual deployment or as a fallback

set -e

echo "🚀 Quick deployment for Badminton Shop..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose is not installed. Please install it first."
    exit 1
fi

print_status "Starting deployment process..."

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down || true

# Clean up old images to save space
print_status "Cleaning up old Docker images..."
docker image prune -f

# Generate SSL certificates if they don't exist
if [ ! -f "nginx/ssl/cert.pem" ]; then
    print_status "Generating SSL certificates..."
    chmod +x scripts/generate-ssl.sh
    ./scripts/generate-ssl.sh
fi

# Build and start containers
print_status "Building Docker images..."
docker-compose build --no-cache

print_status "Starting containers..."
docker-compose up -d

# Wait for application to be ready
print_status "Waiting for application to start..."
sleep 30

# Health check
print_status "Performing health check..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    print_status "✅ Deployment successful!"
    
    # Get public IP
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    
    echo ""
    echo "🎉 Application is now running!"
    echo "🌐 Application URL: https://$PUBLIC_IP"
    echo "🔧 Jenkins URL: http://$PUBLIC_IP:8080"
    echo "📊 Status Page: http://$PUBLIC_IP/status.html"
    echo ""
    echo "📋 Useful commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Monitor: ./monitor.sh"
    echo "  - Backup: ./backup.sh"
    echo "  - Stop: docker-compose down"
    echo ""
else
    print_error "❌ Deployment failed! Application is not responding."
    echo ""
    echo "🔍 Troubleshooting:"
    echo "1. Check logs: docker-compose logs"
    echo "2. Check if ports are available: sudo netstat -tulpn | grep :80"
    echo "3. Check Docker status: docker ps"
    echo "4. Restart Docker: sudo systemctl restart docker"
    echo ""
    exit 1
fi

# Show container status
print_status "Container status:"
docker-compose ps

# Show system resources
print_status "System resources:"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $5}')"

print_status "Deployment completed successfully!" 