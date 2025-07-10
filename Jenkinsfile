pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = 'latest'
    }
    
    tools {
        nodejs 'NodeJS'
        jdk 'JDK21'
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Generate SSL Certificate') {
            steps {
                sh '''
                    mkdir -p nginx/ssl
                    cd nginx/ssl
                    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt -subj "/C=VN/ST=HCM/L=HCM/O=Badminton Shop/OU=IT/CN=localhost"
                '''
            }
        }
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
                script {
                    sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
                }
            }
        }
        
        stage('Stop Previous Container') {
            steps {
                script {
                    sh '''
                        docker-compose down || true
                        docker system prune -f
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    sh '''
                        docker-compose up -d
                    '''
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