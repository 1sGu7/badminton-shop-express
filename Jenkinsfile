pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = 'latest'
        PORT = '3000'
        NODE_ENV = 'production'
        MONGODB_URI = credentials('MONGODB_URI')
        JWT_SECRET = credentials('JWT_SECRET')
        SESSION_SECRET = credentials('SESSION_SECRET')
        CLOUDINARY_CLOUD_NAME = credentials('CLOUDINARY_CLOUD_NAME')
        CLOUDINARY_API_KEY = credentials('CLOUDINARY_API_KEY')
        CLOUDINARY_API_SECRET = credentials('CLOUDINARY_API_SECRET')
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Create .env file') {
            steps {
                script {
                    sh '''
cat > .env <<EOL
PORT=${PORT}
NODE_ENV=${NODE_ENV}
MONGODB_URI=${MONGODB_URI}
JWT_SECRET=${JWT_SECRET}
SESSION_SECRET=${SESSION_SECRET}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY}
CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET}
EOL
                    '''
                }
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
                    if docker ps -a | grep -q ${DOCKER_IMAGE}; then
                        docker stop ${DOCKER_IMAGE}
                        docker rm ${DOCKER_IMAGE}
                    fi
                '''
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker run -d \
                        --name ${DOCKER_IMAGE} \
                        -p 80:3000 \
                        --env-file .env \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 30
                    if curl -f http://localhost:80 >/dev/null 2>&1; then
                        echo "App is running"
                    else
                        echo "Health check failed"
                        docker logs ${DOCKER_IMAGE} || true
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker system prune -f'
        }
    }
}