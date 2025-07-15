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
        EC2_HOST = credentials('EC2_HOST')
        EC2_KEY = credentials('EC2_KEY')
        DOMAIN = credentials('DOMAIN')
        EMAIL = credentials('EMAIL')
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
                    def envContent = """
PORT=${PORT}
NODE_ENV=${NODE_ENV}
MONGODB_URI=${MONGODB_URI}
JWT_SECRET=${JWT_SECRET}
SESSION_SECRET=${SESSION_SECRET}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY}
CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET}
"""
                    writeFile file: '.env', text: envContent.trim() + "\n"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
            }
        }

        stage('Deploy & Setup HTTPS on EC2') {
            steps {
                sh '''
ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} '
    # Cài Nginx nếu chưa có
    sudo apt-get update
    sudo apt-get install -y nginx

    # Dừng và xóa container cũ nếu có
    docker stop ${DOCKER_IMAGE} || true
    docker rm ${DOCKER_IMAGE} || true

    # Xóa image cũ nếu có
    docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true

    # Copy .env lên EC2
    rm -f /home/ubuntu/.env
'
scp -i ${EC2_KEY} .env ${EC2_HOST}:/home/ubuntu/.env
scp -i ${EC2_KEY} Dockerfile ${EC2_HOST}:/home/ubuntu/Dockerfile
scp -i ${EC2_KEY} -r src ${EC2_HOST}:/home/ubuntu/src
scp -i ${EC2_KEY} package*.json ${EC2_HOST}:/home/ubuntu/

ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} '
    # Build lại image trên EC2
    cd /home/ubuntu
    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
    docker run -d --name ${DOCKER_IMAGE} -p 127.0.0.1:${PORT}:3000 --env-file .env ${DOCKER_IMAGE}:${DOCKER_TAG}

    # Cấu hình Nginx reverse proxy
    sudo bash -c "cat > /etc/nginx/sites-available/badminton-shop <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF"
    sudo ln -sf /etc/nginx/sites-available/badminton-shop /etc/nginx/sites-enabled/badminton-shop
    sudo nginx -t && sudo systemctl reload nginx

    # Cài Certbot nếu chưa có
    sudo apt-get install -y certbot python3-certbot-nginx

    # Cấp SSL tự động
    sudo certbot --nginx --non-interactive --agree-tos --redirect -d ${DOMAIN} -m ${EMAIL}
    sudo systemctl reload nginx
'
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