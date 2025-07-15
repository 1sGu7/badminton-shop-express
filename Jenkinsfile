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
        stage('Initial Cleanup') {
            steps {
                sh '''
                    # Dọn dẹp containers cũ
                    docker ps -q | xargs -r docker stop
                    docker ps -aq | xargs -r docker rm
                    docker system prune -af || true
                    
                    # Dọn workspace
                    rm -rf ${WORKSPACE}/ssl
                    mkdir -p ${WORKSPACE}/ssl/certbot/www/.well-known/acme-challenge
                    mkdir -p ${WORKSPACE}/ssl/certbot/conf
                    
                    # Tạo test file
                    echo "acme challenge test" > ${WORKSPACE}/ssl/certbot/www/.well-known/acme-challenge/test.txt
                    chmod -R 755 ${WORKSPACE}/ssl
                '''
            }
        }

        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Setup HTTP Server') {
            steps {
                script {
                    sh '''
                        # Tạo nginx config tạm thời
                        cat > ${WORKSPACE}/nginx-temp.conf <<-EOF
events {
    worker_connections 512;
}
http {
    server {
        listen 80;
        server_name ${DOMAIN};
        
        location ^~ /.well-known/acme-challenge/ {
            root /usr/share/nginx/html;
            default_type text/plain;
            allow all;
        }
        
        location = /.well-known/acme-challenge/ {
            return 404;
        }
        
        location / {
            return 200 "Waiting for SSL setup...";
        }
    }
}
EOF
                        
                        # Chạy nginx tạm thời
                        docker run -d \
                            --name nginx-temp \
                            -p 80:80 \
                            -v ${WORKSPACE}/ssl/certbot/www:/usr/share/nginx/html \
                            -v ${WORKSPACE}/nginx-temp.conf:/etc/nginx/nginx.conf:ro \
                            nginx:alpine

                        # Kiểm tra nginx đã chạy chưa
                        sleep 5
                        curl -v http://${DOMAIN}/.well-known/acme-challenge/test.txt
                    '''
                }
            }
        }

        stage('Get SSL Certificate') {
            steps {
                sh '''
                    # Chạy certbot để lấy certificate
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
                        --staging \
                        --verbose \
                        --debug
                        
                    # Kiểm tra certificate đã được tạo chưa
                    ls -la ${WORKSPACE}/ssl/certbot/conf/live/${DOMAIN} || echo "Certificate not generated"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    # Dừng nginx tạm thời
                    docker stop nginx-temp
                    docker rm nginx-temp

                    # Tạo .env file
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

                    # Tạo network
                    docker network create badminton-net || true

                    # Build và chạy application
                    docker build --memory=512m --memory-swap=512m -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker run -d \
                        --name ${DOCKER_IMAGE} \
                        --network badminton-net \
                        --memory=200m \
                        --memory-swap=200m \
                        --cpus=0.3 \
                        --env-file .env \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}

                    # Chạy nginx với SSL
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
                    sleep 10
                    
                    # Kiểm tra logs
                    echo "=== Application Logs ==="
                    docker logs ${DOCKER_IMAGE}
                    
                    echo "=== Nginx Logs ==="
                    docker logs nginx
                    
                    # Test endpoints
                    echo "=== Testing HTTP ==="
                    curl -v http://${DOMAIN}
                    
                    echo "=== Testing HTTPS ==="
                    curl -k -v https://${DOMAIN} || echo "HTTPS not ready yet"
                    
                    # Kiểm tra certificate
                    echo "=== SSL Certificate Info ==="
                    echo | openssl s_client -showcerts -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -inform pem -noout -text || echo "Certificate not accessible"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                # Lưu logs để debug
                mkdir -p ${WORKSPACE}/logs
                docker logs ${DOCKER_IMAGE} > ${WORKSPACE}/logs/app.log 2>&1 || true
                docker logs nginx > ${WORKSPACE}/logs/nginx.log 2>&1 || true
                
                # Lưu nginx config đang sử dụng
                docker cp nginx:/etc/nginx/nginx.conf ${WORKSPACE}/logs/nginx.conf || true
                
                # Lưu thông tin certbot
                cp -r ${WORKSPACE}/ssl/certbot/conf/live/${DOMAIN}/* ${WORKSPACE}/logs/ || true
            '''
        }
        failure {
            sh '''
                echo "=== Debug Information ==="
                echo "Docker containers:"
                docker ps -a
                echo "Port usage:"
                netstat -tulpn || true
                echo "Certificate files:"
                ls -la ${WORKSPACE}/ssl/certbot/conf/live/${DOMAIN} || true
                echo "Nginx error log:"
                tail -n 50 ${WORKSPACE}/logs/nginx.log || true
            '''
        }
    }
}
