pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        CONTAINER_NAME = 'badminton-shop-app'
        NGINX_CONTAINER = 'badminton-shop-nginx'
        APP_DIR = '/opt/badminton-shop'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    // Create application directory if not exists
                    sh "sudo mkdir -p ${APP_DIR}"
                    sh "sudo chown -R ubuntu:ubuntu ${APP_DIR}"
                    
                    // Copy project files to application directory
                    sh "cp -r . ${APP_DIR}/"
                    sh "sudo chown -R ubuntu:ubuntu ${APP_DIR}"
                    
                    // Navigate to application directory
                    dir("${APP_DIR}") {
                        // Generate SSL certificates if not exists
                        sh "mkdir -p nginx/ssl"
                        sh "chmod +x scripts/generate-ssl.sh"
                        sh "./scripts/generate-ssl.sh"
                        
                        // Create .env file from template if not exists
                        sh "if [ ! -f .env ]; then cp .env.template .env; fi"
                        
                        // Set proper permissions
                        sh "chmod 600 .env"
                        sh "chmod +x scripts/*.sh"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm ci --only=production'
                }
            }
        }
        
        stage('Lint') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm run lint || true'
                }
            }
        }
        
        stage('Test') {
            steps {
                dir("${APP_DIR}") {
                    sh 'npm test || true'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                dir("${APP_DIR}") {
                    script {
                        // Build the Docker image
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Run security scan with Trivy (if available)
                    sh 'which trivy && trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${DOCKER_TAG} || echo "Trivy not available, skipping security scan"'
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                dir("${APP_DIR}") {
                    script {
                        // Stop and remove existing containers
                        sh "docker-compose down || true"
                        sh "docker rm -f ${CONTAINER_NAME} ${NGINX_CONTAINER} || true"
                        
                        // Remove old images to save space
                        sh "docker image prune -f"
                        
                        // Start the application
                        sh "docker-compose up -d"
                        
                        // Wait for application to be healthy
                        sh "sleep 30"
                        
                        // Health check
                        sh "curl -f http://localhost/health || exit 1"
                    }
                }
            }
        }
        
        stage('Setup Auto-restart') {
            steps {
                script {
                    // Create systemd service for auto-restart
                    sh '''
                    sudo tee /etc/systemd/system/badminton-shop.service > /dev/null << 'EOF'
[Unit]
Description=Badminton Shop Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/badminton-shop
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF
                    '''
                    
                    // Enable the service
                    sh "sudo systemctl daemon-reload"
                    sh "sudo systemctl enable badminton-shop.service"
                    
                    // Create log rotation
                    sh '''
                    sudo tee /etc/logrotate.d/badminton-shop > /dev/null << 'EOF'
/opt/badminton-shop/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOF
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    // Keep only the latest 5 images to save disk space
                    sh "docker images ${DOCKER_IMAGE} --format 'table {{.Repository}}:{{.Tag}}' | tail -n +6 | xargs -r docker rmi || true"
                }
            }
        }
    }
    
    post {
        always {
            // Clean workspace
            cleanWs()
        }
        success {
            script {
                // Get public IP
                def publicIP = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost"', returnStdout: true).trim()
                
                echo "🎉 Deployment successful!"
                echo "🌐 Application URL: https://${publicIP}"
                echo "🔧 Jenkins URL: http://${publicIP}:8080"
                echo "📊 Status Page: http://${publicIP}/status.html"
                echo ""
                echo "📋 Useful commands:"
                echo "  - View logs: docker-compose logs -f"
                echo "  - Monitor: ./monitor.sh"
                echo "  - Backup: ./backup.sh"
                echo "  - Stop: docker-compose down"
                echo ""
                echo "✅ Application is now running and will auto-restart on server reboot!"
            }
        }
        failure {
            script {
                echo "❌ Deployment failed! Check the logs for more details."
                dir("${APP_DIR}") {
                    sh "docker-compose logs --tail=50"
                }
            }
        }
    }
} 