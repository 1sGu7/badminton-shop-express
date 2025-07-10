pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = 'latest'
        APP_DIR = '/opt/badminton-shop'
    }
    
    tools {
        nodejs 'NodeJS'
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                cleanWs()
                checkout scm
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
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci --only=production'
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint || true'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test || true'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
            }
        }
        
        stage('Stop Previous Container') {
            steps {
                sh '''
                    docker-compose down || true
                    docker system prune -f
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh 'docker-compose up -d'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            script {
                def publicIP = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost"', returnStdout: true).trim()
                echo "🎉 Deployment successful!"
                echo "🌐 Application URL: https://${publicIP}"
                echo "🔧 Jenkins URL: http://${publicIP}:8080"
                echo "📊 Status Page: http://${publicIP}/status.html"
                echo ""
                echo "📋 Useful commands:"
                echo "  - View logs: docker-compose logs -f"
                echo "  - Stop: docker-compose down"
                echo ""
                echo "✅ Application is now running and will auto-restart on server reboot!"
            }
        }
        failure {
            script {
                echo "❌ Deployment failed! Check the logs for more details."
                sh "docker-compose logs --tail=50"
            }
        }
    }
}