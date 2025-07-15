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
                        # Remove old SSL directory if exists
                        rm -rf ${WORKSPACE_SSL} || true
                        
                        # Create required directories
                        mkdir -p ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge
                        mkdir -p ${WORKSPACE_SSL}/certbot/conf
                        
                        # Set permissions
                        chmod -R 755 ${WORKSPACE_SSL}
                        
                        # Verify setup
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
                    mkdir -p ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge
                    echo "acme challenge test" > ${WORKSPACE_SSL}/certbot/www/.well-known/acme-challenge/test.txt
                    chmod -R 755 ${WORKSPACE_SSL}/certbot/www
                    
                    # Create minimal nginx config
                    cat > ${WORKSPACE}/nginx-acme.conf <<-EOF
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
            default_type text/plain;
            try_files \$uri \$uri/ =404;
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
                    
                    # Create empty directory to override conf.d
                    mkdir -p ${WORKSPACE}/empty-dir
                    
                    # Validate nginx config before starting
                    echo "Validating nginx configuration..."
                    docker run --rm \
                        -v ${WORKSPACE}/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine nginx -t
                    
                    # Start nginx for ACME challenge
                    docker run -d \
                        --name nginx-acme \
                        --restart unless-stopped \
                        -p 80:80 \
                        -v ${WORKSPACE_SSL}/certbot/www:/usr/share/nginx/html \
                        -v ${WORKSPACE}/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
                        -v ${WORKSPACE}/empty-dir:/etc/nginx/conf.d:ro \
                        nginx:alpine

                    # Wait for nginx to start
                    echo "Waiting for nginx to start..."
                    sleep 10

                    # Verify nginx is running and test file is accessible
                    echo "Testing nginx configuration..."
                    docker exec nginx-acme nginx -t
                    
                    echo "Testing local access..."
                    curl -v http://localhost/.well-known/acme-challenge/test.txt
                    
                    echo "Testing domain access..."
                    curl -v http://${DOMAIN}/.well-known/acme-challenge/test.txt
                    
                    # Show nginx logs
                    echo "Nginx logs:"
                    docker logs nginx-acme
                '''
            }
        }

        stage('Verify DNS') {
            steps {
                sh '''
                    # Get instance public IP using eth0 interface
                    EC2_IP=$(curl -s https://api.ipify.org)
                    echo "EC2 Public IP: $EC2_IP"
                    
                    # Verify DNS A record
                    echo "Checking DNS A record for ${DOMAIN}..."
                    DOMAIN_IP=$(dig +short ${DOMAIN} A)
                    echo "Domain A record resolves to: $DOMAIN_IP"
                    
                    # Verify exact match with EC2 IP
                    if [ "$EC2_IP" = "$DOMAIN_IP" ]; then
                        echo "DNS A record matches EC2 IP ✓"
                    else
                        echo "Warning: Domain ${DOMAIN} A record ($DOMAIN_IP) does not match EC2 IP ($EC2_IP)"
                        
                        # Try secondary IP check
                        SECONDARY_IP=$(curl -s http://checkip.amazonaws.com)
                        echo "Secondary IP check: $SECONDARY_IP"
                        
                        if [ "$SECONDARY_IP" = "$DOMAIN_IP" ]; then
                            echo "DNS A record matches secondary IP check ✓"
                        else
                            echo "Please update DNS A record for ${DOMAIN} to point to $EC2_IP"
                            exit 1
                        fi
                    fi
                    
                    # Test DNS propagation with multiple nameservers
                    echo "Testing DNS propagation..."
                    NAMESERVERS="8.8.8.8 1.1.1.1 208.67.222.222"
                    for ns in $NAMESERVERS; do
                        echo "Checking with nameserver $ns..."
                        RESOLVED_IP=$(dig @$ns +short ${DOMAIN} A)
                        if [ "$RESOLVED_IP" = "$DOMAIN_IP" ]; then
                            echo "DNS propagated to $ns ✓"
                        else
                            echo "Warning: DNS not yet propagated to $ns"
                            echo "Got $RESOLVED_IP, expected $DOMAIN_IP"
                            echo "Waiting for propagation..."
                            sleep 30
                            # Check one more time
                            RESOLVED_IP=$(dig @$ns +short ${DOMAIN} A)
                            if [ "$RESOLVED_IP" = "$DOMAIN_IP" ]; then
                                echo "DNS now propagated to $ns ✓"
                            else
                                echo "DNS failed to propagate to $ns after waiting"
                                exit 1
                            fi
                        fi
                    done
                    
                    echo "All DNS checks passed! ✓"
                    
                    # Additional verification
                    echo "Running final connectivity test..."
                    if curl -f -s -m 10 http://${DOMAIN}/.well-known/acme-challenge/test.txt > /dev/null; then
                        echo "Web server connectivity test passed ✓"
                    else
                        echo "Warning: Could not access test file via domain name"
                        echo "Please check your web server configuration and firewall rules"
                        exit 1
                    fi
                '''
            }
        }

        stage('Get SSL Certificate') {
            steps {
                sh '''
                    # Prepare certbot command - FIX: Removed extra "certbot"
                    CERTBOT_CMD="certonly --webroot -w /var/www/certbot"
                    CERTBOT_CMD="$CERTBOT_CMD --non-interactive --agree-tos"
                    CERTBOT_CMD="$CERTBOT_CMD --email ${EMAIL} --domains ${DOMAIN}"
                    CERTBOT_CMD="$CERTBOT_CMD --staging --debug --verbose"
                    
                    # Clean any previous certbot data
                    rm -rf ${WORKSPACE_SSL}/certbot/conf/*
                    
                    echo "Starting certbot with staging..."
                    docker run --rm \
                        -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt \
                        -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot \
                        certbot/certbot $CERTBOT_CMD
                        
                    # If staging succeeds, try production
                    if [ $? -eq 0 ]; then
                        echo "Staging certificate obtained successfully. Trying production..."
                        # Clean staging certificates
                        rm -rf ${WORKSPACE_SSL}/certbot/conf/*
                        
                        # Run certbot without staging
                        docker run --rm \
                            -v ${WORKSPACE_SSL}/certbot/conf:/etc/letsencrypt \
                            -v ${WORKSPACE_SSL}/certbot/www:/var/www/certbot \
                            certbot/certbot \
                            certonly --webroot \
                            --webroot-path=/var/www/certbot \
                            --non-interactive \
                            --agree-tos \
                            --email ${EMAIL} \
                            --domains ${DOMAIN} \
                            --force-renewal \
                            --debug \
                            --verbose
                    fi
                    
                    # Verify certificate files
                    echo "Checking certificate files..."
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

                    # Create network if not exists
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
                        -v ${WORKSPACE}/nginx.conf:/etc/nginx/nginx.conf:ro \
                        nginx:alpine

                    # Verify deployment
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
                # Create debug directory
                mkdir -p ${WORKSPACE}/debug
                
                # Save debug information
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
