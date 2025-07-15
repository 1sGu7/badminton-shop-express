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
                    cleanWs()
                    checkout scm
                    sh '''
                        rm -rf ${WORKSPACE_SSL} || true
                        mkdir -p ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge
                        mkdir -p ${WORKSPACE_SSL}/certbot/conf
                        chmod -R 755 ${WORKSPACE_SSL}
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
                    mkdir -p ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge
                    echo "acme challenge test" > ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge/test.txt
                    chmod -R 755 ${WORKSPACE_SSL}/certbot/www

                    cat > ${WORKSPACE}/nginx-acme.conf <<EOF
events {
    worker_connections 512;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        listen [::]:80;
        server_name ${DOMAIN};

        root /usr/share/nginx/html;

        location /.well-known/acme-challenge/ {
            allow all;
            default_type "text/plain";
            try_files \$uri =404;
        }

        location / {
            return 200 "ACME Challenge Server Running\\n";
            add_header Content-Type text/plain;
        }

        access_log /dev/stdout;
        error_log /dev/stdout info;
    }
}
EOF

                    echo "Validating nginx configuration..."
                    docker run --rm \
                        -v ${WORKSPACE}/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine nginx -t

                    docker run -d --name nginx-acme --restart unless-stopped -p 80:80 \
                        -v ${WORKSPACE_SSL}/certbot/www:/usr/share/nginx/html \
                        -v ${WORKSPACE}/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine

                    echo "Waiting for nginx to start..."
                    sleep 10

                    echo "Testing nginx configuration..."
                    docker exec nginx-acme nginx -t

                    echo "Testing local access..."
                    curl -v http://localhost/.well-known/acme-challenge/test.txt

                    echo "Testing domain access..."
                    curl -v http://${DOMAIN}/.well-known/acme-challenge/test.txt

                    echo "Nginx logs:"
                    docker logs nginx-acme
                '''
            }
        }

        stage('Verify DNS') {
            steps {
                sh '''
                    EC2_IP=$(curl -s https://api.ipify.org)
                    echo "EC2 Public IP: $EC2_IP"

                    echo "Checking DNS A record for ${DOMAIN}..."
                    DOMAIN_IP=$(dig +short ${DOMAIN} A)
                    echo "Domain A record resolves to: $DOMAIN_IP"

                    if [ "$EC2_IP" != "$DOMAIN_IP" ]; then
                        echo "Warning: Domain ${DOMAIN} A record ($DOMAIN_IP) does not match EC2 IP ($EC2_IP)"
                        SECONDARY_IP=$(curl -s http://checkip.amazonaws.com)
                        echo "Secondary IP check: $SECONDARY_IP"
                        if [ "$SECONDARY_IP" != "$DOMAIN_IP" ]; then
                            echo "Please update DNS A record for ${DOMAIN} to point to $EC2_IP"
                            exit 1
                        fi
                    else
                        echo "DNS A record matches EC2 IP ✓"
                    fi

                    echo "Testing DNS propagation..."
                    NAMESERVERS="8.8.8.8 1.1.1.1 208.67.222.222"
                    for ns in $NAMESERVERS; do
                        echo "Checking with nameserver $ns..."
                        RESOLVED_IP=$(dig @$ns +short ${DOMAIN} A)
                        if [ "$RESOLVED_IP" != "$DOMAIN_IP" ]; then
                            echo "Warning: DNS not yet propagated to $ns"
                            echo "Got $RESOLVED_IP, expected $DOMAIN_IP"
                            echo "Waiting for propagation..."
                            sleep 30
                            RESOLVED_IP=$(dig @$ns +short ${DOMAIN} A)
                            if [ "$RESOLVED_IP" != "$DOMAIN_IP" ]; then
                                echo "DNS failed to propagate to $ns after waiting"
                                exit 1
                            fi
                        fi
                        echo "DNS propagated to $ns ✓"
                    done

                    echo "All DNS checks passed! ✓"

                    echo "Running final connectivity test..."
                    if curl -f -s -m 10 http://${DOMAIN}/.well-known/acme-challenge/test.txt > /dev/null; then
                        echo "Web server connectivity test passed ✓"
                    else
                        echo "Warning: Could not access test file via domain name"
                        exit 1
                    fi
                '''
            }
        }

        stage('Get SSL Certificate') {
            steps {
                sh '''
                    rm -rf ${WORKSPACE_SSL}/certbot/conf/*

                    echo "Starting certbot with staging..."
                    docker run --rm \
                        -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt \
                        -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot \
                        certbot/certbot certonly --webroot -w /var/www/certbot \
                        --non-interactive --agree-tos --email ${EMAIL} --domains ${DOMAIN} --staging --debug --verbose

                    if [ $? -eq 0 ]; then
                        echo "Staging cert obtained successfully, obtaining production cert..."

                        rm -rf ${WORKSPACE_SSL}/certbot/conf/*

                        docker run --rm \
                            -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt \
                            -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot \
                            certbot/certbot certonly --webroot -w /var/www/certbot \
                            --non-interactive --agree-tos --email ${EMAIL} --domains ${DOMAIN} --force-renewal --debug --verbose
                    else
                        echo "Certbot staging failed"
                        exit 1
                    fi

                    echo "Listing certificates..."
                    ls -la ${WORKSPACE_SSL}/certbot/conf/live/${DOMAIN} || echo "Certificate not generated"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    docker stop nginx-acme || true
                    docker rm nginx-acme || true

                    docker network create badminton-net || true

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

                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

                    docker run -d --name ${DOCKER_IMAGE} --network badminton-net --memory=200m --memory-swap=200m --cpus=0.3 --restart unless-stopped --env-file .env ${DOCKER_IMAGE}:${DOCKER_TAG}

                    docker run -d --name nginx --network badminton-net --memory=128m --memory-swap=128m --cpus=0.2 --restart unless-stopped -p 80:80 -p 443:443 \
                        -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt:ro \
                        -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot:ro \
                        -v ${WORKSPACE}/nginx.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine

                    sleep 10

                    echo "Containers running:"
                    docker ps
                    echo "Application logs:"
                    docker logs ${DOCKER_IMAGE}
                    echo "Nginx logs:"
                    docker logs nginx
                '''
            }
        }
    }

    post {
        always {
            sh '''
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

                chmod -R 755 ${WORKSPACE}/debug
            '''
        }
        failure {
            sh '''
                echo "=== Failure Debug Information ==="
                cat ${WORKSPACE}/debug/status.log || true
                echo "=== Directory Permissions ==="
                ls -la ${WORKSPACE}
                ls -la ${WORKSPACE_SSL} || true
                echo "=== Docker Info ==="
                docker info
            '''
        }
    }
}
