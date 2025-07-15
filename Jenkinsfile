pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'badminton-shop'
        DOCKER_TAG = 'latest'
        PORT = '3000'
        NODE_ENV = 'production'
        DOMAIN = 'www.phgbao.id.vn'
        MONGODB_URI = credentials('MONGODB_URI')
        JWT_SECRET = credentials('JWT_SECRET')
        SESSION_SECRET = credentials('SESSION_SECRET')
        CLOUDINARY_CLOUD_NAME = credentials('CLOUDINARY_CLOUD_NAME')
        CLOUDINARY_API_KEY = credentials('CLOUDINARY_API_KEY')
        CLOUDINARY_API_SECRET = credentials('CLOUDINARY_API_SECRET')
        EMAIL = credentials('LETS_ENCRYPT_EMAIL')
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

        stage('Setup SSL Directory') {
            steps {
                sh '''
                    # Create directories for SSL
                    mkdir -p ssl/certbot/conf
                    mkdir -p ssl/certbot/www
                '''
            }
        }

        stage('Setup SSL Certificate') {
            steps {
                sh '''
                    # Run certbot in Docker
                    docker run -it --rm \
                    -v "${WORKSPACE}/ssl/certbot/conf:/etc/letsencrypt" \
                    -v "${WORKSPACE}/ssl/certbot/www:/var/www/certbot" \
                    -p 80:80 \
                    certbot/certbot certonly \
                    --standalone \
                    --non-interactive \
                    --agree-tos \
                    --email ${EMAIL} \
                    --domains ${DOMAIN}
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
            }
        }

        stage('Stop Previous Containers') {
            steps {
                sh '''
                    if docker ps -a | grep -q ${DOCKER_IMAGE}; then
                        docker stop ${DOCKER_IMAGE}
                        docker rm ${DOCKER_IMAGE}
                    fi
                    if docker ps -a | grep -q nginx; then
                        docker stop nginx
                        docker rm nginx
                    fi
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    # Create docker network if it doesn't exist
                    docker network create badminton-net || true

                    # Run Node.js application
                    docker run -d \
                        --name ${DOCKER_IMAGE} \
                        --network badminton-net \
                        --env-file .env \
                        --memory=350m --memory-swap=350m \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}

                    # Run Nginx with SSL
                    docker run -d \
                        --name nginx \
                        --network badminton-net \
                        -p 80:80 \
                        -p 443:443 \
                        -v ${WORKSPACE}/ssl/certbot/conf:/etc/letsencrypt:ro \
                        -v ${WORKSPACE}/ssl/certbot/www:/var/www/certbot:ro \
                        -v ${WORKSPACE}/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    # Wait for services to start
                    sleep 10
                    
                    # Check if services are running
                    docker ps | grep ${DOCKER_IMAGE}
                    docker ps | grep nginx
                    
                    # Test HTTPS endpoint
                    curl -k -I https://${DOMAIN} || echo "Website is starting up..."
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
