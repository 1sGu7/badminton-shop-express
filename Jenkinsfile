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
                sh 'docker build --platform linux/amd64 -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
                sh 'docker save ${DOCKER_IMAGE}:${DOCKER_TAG} | gzip > image.tar.gz'
            }
        }

        stage('Deploy & Setup HTTPS on EC2') {
            steps {
                // Copy image và .env lên EC2 (dùng scp gốc, không docker run alpine/scp)
                sh 'scp -i ${EC2_KEY} -o StrictHostKeyChecking=no image.tar.gz ${EC2_HOST}:/home/ubuntu/'
                sh 'scp -i ${EC2_KEY} -o StrictHostKeyChecking=no .env ${EC2_HOST}:/home/ubuntu/.env'

                // SSH vào EC2 để load image, stop/run container, setup nginx/certbot
                sh """
ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_HOST} '
docker load < image.tar.gz
docker stop ${DOCKER_IMAGE} || true
docker rm ${DOCKER_IMAGE} || true
docker run -d --name ${DOCKER_IMAGE} --restart=always --memory=512m --cpus=0.5 -p 127.0.0.1:${PORT}:3000 --env-file .env ${DOCKER_IMAGE}:${DOCKER_TAG}
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
sudo certbot --nginx --non-interactive --agree-tos --redirect -d ${DOMAIN} -m ${EMAIL} || true
sudo systemctl reload nginx
'
"""
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