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
        WORKSPACE_SSL = "${WORKSPACE}/ssl-data"
    }

    stages {
        stage('Prepare Workspace') {
            steps {
                script {
                    // Cleanup workspace
                    cleanWs()
                    checkout scm
                    
                    // Setup SSL directory with correct permissions
                    sh '''
                        # Create fresh SSL directory
                        sudo rm -rf ${WORKSPACE_SSL} || true
                        sudo mkdir -p ${WORKSPACE_SSL}
                        sudo chown jenkins:jenkins ${WORKSPACE_SSL}
                        
                        # Create required subdirectories
                        mkdir -p ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge
                        mkdir -p ${WORKSPACE_SSL}/certbot/conf
                        
                        # Set correct permissions
                        sudo chown -R jenkins:jenkins ${WORKSPACE_SSL}
                        sudo chmod -R 755 ${WORKSPACE_SSL}
                        
                        # Verify permissions
                        ls -la ${WORKSPACE_SSL}
                    '''
                }
            }
        }

        stage('Stop Existing Services') {
            steps {
                sh '''
                    docker ps -q | xargs -r docker stop
                    docker ps -aq | xargs -r docker rm
                    docker system prune -af || true
                '''
            }
        }

        stage('Setup ACME Challenge') {
            steps {
                sh '''
                    # Create test file
                    echo "acme challenge test" > ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge/test.txt
                    
                    # Create minimal nginx config
                    cat > ${WORKSPACE}/nginx-acme.conf <<-EOF
events {
    worker_connections 512;
}
http {
    server {
        listen 80;
        listen [::]:80;
        server_name ${DOMAIN};
        
        location ^~ /.well-known/acme-challenge/ {
            root /usr/share/nginx/html;
            default_type text/plain;
            allow all;
        }
        
        location / {
            return 200 "ACME Challenge Server Running\\n";
        }
    }
}
EOF
                    
                    # Start nginx for ACME challenge
                    docker run -d \
                        --name nginx-acme \
                        --restart unless-stopped \
                        -p 80:80 \
                        -v ${WORKSPACE_SSL}/certbot/www:/usr/share/nginx/html \
                        -v ${WORKSPACE}/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine

                    # Verify nginx is running
                    sleep 5
                    docker ps | grep nginx-acme
                    curl -v http://${DOMAIN}/.well-known/acme-challenge/test.txt
                '''
            }
        }

        stage('Get SSL Certificate') {
            steps {
                sh '''
                    # Run certbot
                    docker run --rm \
                        -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt \
                        -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot \
                        certbot/certbot certonly \
                        --webroot \
                        --webroot-path=/var/www/certbot \
                        --non-interactive \
                        --agree-tos \
                        --email ${EMAIL} \
                        --domains ${DOMAIN} \
                        --staging \
                        --debug \
                        --verbose
                        
                    # Fix permissions
                    sudo chown -R jenkins:jenkins ${WORKSPACE_SSL}
                    
                    # Verify certificate
                    ls -la ${WORKSPACE_SSL}/certbot/conf/live/${DOMAIN} || echo "Certificate not generated"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    # Stop ACME nginx
                    docker stop nginx-acme
                    docker rm nginx-acme

                    # Create network
                    docker network create badminton-net || true

                    # Create .env file
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

                    # Deploy application
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker run -d \
                        --name ${DOCKER_IMAGE} \
                        --network badminton-net \
                        --memory=200m \
                        --memory-swap=200m \
                        --cpus=0.3 \
                        --restart unless-stopped \
                        --env-file .env \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}

                    # Deploy nginx with SSL
                    docker run -d \
                        --name nginx \
                        --network badminton-net \
                        --memory=128m \
                        --memory-swap=128m \
                        --cpus=0.2 \
                        --restart unless-stopped \
                        -p 80:80 \
                        -p 443:443 \
                        -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt:ro \
                        -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot:ro \
                        -v ${WORKSPACE}/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine

                    # Verify services
                    sleep 10
                    echo "Checking containers..."
                    docker ps
                    echo "Checking application logs..."
                    docker logs ${DOCKER_IMAGE}
                    echo "Checking nginx logs..."
                    docker logs nginx
                '''
            }
        }
    }

    post {
        always {
            sh '''
                # Save debug information
                mkdir -p ${WORKSPACE}/debug
                
                echo "=== Container Status ===" > ${WORKSPACE}/debug/status.log
                docker ps -a >> ${WORKSPACE}/debug/status.log
                
                echo "=== Container Logs ===" >> ${WORKSPACE}/debug/status.log
                docker logs ${DOCKER_IMAGE} >> ${WORKSPACE}/debug/status.log 2>&1 || true
                docker logs nginx >> ${WORKSPACE}/debug/status.log 2>&1 || true
                
                echo "=== Certificate Files ===" >> ${WORKSPACE}/debug/status.log
                ls -la ${WORKSPACE_SSL}/certbot/conf/live/${DOMAIN} >> ${WORKSPACE}/debug/status.log 2>&1 || true
                
                echo "=== System Info ===" >> ${WORKSPACE}/debug/status.log
                id >> ${WORKSPACE}/debug/status.log
                df -h >> ${WORKSPACE}/debug/status.log
                
                # Set permissions for debug files
                sudo chown -R jenkins:jenkins ${WORKSPACE}/debug
                chmod -R 755 ${WORKSPACE}/debug
            '''
        }
        failure {
            sh '''
                echo "=== Failure Debug Information ==="
                cat ${WORKSPACE}/debug/status.log || true
                
                echo "=== Directory Permissions ==="
                ls -la ${WORKSPACE}
                ls -la ${WORKSPACE_SSL}
                
                echo "=== Docker Info ==="
                docker info
            '''
        }
    }
}
