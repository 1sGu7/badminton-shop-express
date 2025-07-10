pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = 'latest'
    }

    tools {
        nodejs 'NodeJS'
    }

    stages {
        stage('Checkout') {
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
                    if [ ! -f server.key ] || [ ! -f server.crt ]; then
                        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.crt -subj "/C=VN/ST=HCM/L=HCM/O=Badminton Shop/OU=IT/CN=localhost"
                    fi
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci --only=production'
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
                    docker system prune -f -a -y
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