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
        stage('Cleanup') {
            steps {
                sh '''
                    # Dọn dẹp để giải phóng tài nguyên
                    docker system prune -af
                    docker volume prune -f
                    rm -rf ${WORKSPACE}/ssl/* || true
                '''
            }
        }

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

        stage('Setup SSL') {
            steps {
                sh '''
                    # Tạo thư mục SSL
                    mkdir -p ssl/certbot/conf
                    mkdir -p ssl/certbot/www

                    # Stop các container đang chạy để giải phóng port và tài nguyên
                    docker stop $(docker ps -aq) || true
                    docker rm $(docker ps -aq) || true
                    
                    # Chạy certbot với resource limits
                    docker run --rm \
                    --memory=256m \
                    --memory-swap=256m \
                    --cpus=0.5 \
                    -v "${WORKSPACE}/ssl/certbot/conf:/etc/letsencrypt" \
                    -v "${WORKSPACE}/ssl/certbot/www:/var/www/certbot" \
                    -p 80:80 \
                    certbot/certbot certonly \
                    --standalone \
                    --preferred-challenges http \
                    --non-interactive \
                    --agree-tos \
                    --email ${EMAIL} \
                    --domains ${DOMAIN} \
                    --keep-until-expiring \
                    --staging # Xóa flag này khi chạy production
                '''
            }
        }

        stage('Build and Deploy') {
            steps {
                sh '''
                    # Build với resource limits
                    docker build --memory=512m --memory-swap=512m -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

                    # Tạo network nếu chưa tồn tại
                    docker network create badminton-net || true

                    # Chạy ứng dụng với resource limits
                    docker run -d \
                        --name ${DOCKER_IMAGE} \
                        --network badminton-net \
                        --memory=200m \
                        --memory-swap=200m \
                        --cpus=0.3 \
                        --env-file .env \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}

                    # Chạy Nginx với resource limits
                    docker run -d \
                        --name nginx \
                        --network badminton-net \
                        --memory=128m \
                        --memory-swap=128m \
                        --cpus=0.2 \
                        -p 80:80 \
                        -p 443:443 \
                        -v ${WORKSPACE}/ssl/certbot/conf:/etc/letsencrypt:ro \
                        -v ${WORKSPACE}/ssl/certbot/www:/var/www/certbot:ro \
                        -v ${WORKSPACE}/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    # Đợi services khởi động
                    sleep 15
                    
                    # Kiểm tra container status
                    docker ps --filter "name=${DOCKER_IMAGE}" --format "{{.Status}}"
                    docker ps --filter "name=nginx" --format "{{.Status}}"
                    
                    # Kiểm tra logs nếu có lỗi
                    docker logs --tail 10 ${DOCKER_IMAGE}
                    docker logs --tail 10 nginx
                    
                    # Test endpoints
                    curl -k -I http://${DOMAIN} || echo "HTTP endpoint not ready"
                    curl -k -I https://${DOMAIN} || echo "HTTPS endpoint not ready"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                # Dọn dẹp images không sử dụng để giải phóng disk space
                docker image prune -f
                docker container prune -f
            '''
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
            sh '''
                # Log lỗi khi fail
                docker logs ${DOCKER_IMAGE} || true
                docker logs nginx || true
            '''
        }
    }
}
