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
                    docker system prune -af || true
                    docker volume prune -f || true
                    rm -rf ${WORKSPACE}/ssl/* || true

                    # Kill tất cả process đang sử dụng port 80 và 443
                    sudo lsof -ti:80,443 | xargs -r kill -9 || true
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

        stage('Check Domain') {
            steps {
                sh '''
                    # Kiểm tra DNS record
                    echo "Checking DNS for ${DOMAIN}..."
                    host ${DOMAIN} || echo "Warning: DNS not configured yet"
                    
                    # Kiểm tra port 80
                    echo "Checking if port 80 is available..."
                    if lsof -i:80; then
                        echo "Port 80 is in use. Attempting to free it..."
                        sudo lsof -ti:80 | xargs -r kill -9
                    fi
                    
                    # Đợi port được giải phóng
                    sleep 5
                '''
            }
        }

        stage('Setup SSL Directory') {
            steps {
                sh '''
                    mkdir -p ${WORKSPACE}/ssl/certbot/conf
                    mkdir -p ${WORKSPACE}/ssl/certbot/www
                    chmod -R 755 ${WORKSPACE}/ssl
                '''
            }
        }

        stage('Setup SSL Certificate') {
            steps {
                sh '''
                    # Dừng tất cả container đang chạy
                    docker ps -q | xargs -r docker stop
                    docker ps -aq | xargs -r docker rm
                    
                    # Chạy nginx tạm thời để xác thực certbot
                    docker run -d \
                        --name nginx-temp \
                        -v ${WORKSPACE}/ssl/certbot/www:/usr/share/nginx/html/.well-known/acme-challenge \
                        -p 80:80 \
                        nginx:alpine

                    # Đợi nginx khởi động
                    sleep 5
                    
                    # Chạy certbot
                    docker run --rm \
                        -v ${WORKSPACE}/ssl/certbot/conf:/etc/letsencrypt \
                        -v ${WORKSPACE}/ssl/certbot/www:/var/www/certbot \
                        certbot/certbot certonly \
                        --webroot \
                        --webroot-path=/var/www/certbot \
                        --non-interactive \
                        --agree-tos \
                        --email ${EMAIL} \
                        --domains ${DOMAIN} \
                        --keep-until-expiring \
                        --staging

                    # Dừng nginx tạm thời
                    docker stop nginx-temp
                    docker rm nginx-temp
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

        stage('Verify Deployment') {
            steps {
                sh '''
                    # Đợi services khởi động
                    sleep 15
                    
                    # Kiểm tra certificates
                    ls -la ${WORKSPACE}/ssl/certbot/conf/live/${DOMAIN} || echo "Certificates not found"
                    
                    # Kiểm tra container logs
                    docker logs ${DOCKER_IMAGE} 2>&1 | tail -n 10
                    docker logs nginx 2>&1 | tail -n 10
                    
                    # Test endpoints
                    curl -I http://${DOMAIN} || echo "HTTP endpoint not ready"
                    sleep 5
                    curl -k -I https://${DOMAIN} || echo "HTTPS endpoint not ready"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                # Cleanup
                docker image prune -f
                docker container prune -f
                
                # Lưu logs để debug
                mkdir -p ${WORKSPACE}/logs
                docker logs ${DOCKER_IMAGE} > ${WORKSPACE}/logs/app.log 2>&1 || true
                docker logs nginx > ${WORKSPACE}/logs/nginx.log 2>&1 || true
            '''
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed!'
            sh '''
                # Show error logs
                tail -n 50 ${WORKSPACE}/logs/app.log || true
                tail -n 50 ${WORKSPACE}/logs/nginx.log || true
            '''
        }
    }
}
