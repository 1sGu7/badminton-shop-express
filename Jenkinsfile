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
                script {
                    // 1. Pull docker images for needed tools (nginx, certbot, alpine/scp, alpine/ssh)
                    sh """
docker pull alpine:latest
docker pull alpine/ssh:latest
docker pull alpine/scp:latest
docker pull nginx:latest
docker pull certbot/certbot:latest
"""
                    // 2. Copy files to EC2 using dockerized scp
                    sh """
docker run --rm -v $PWD:/work -v ${EC2_KEY}:${EC2_KEY} alpine/scp -i ${EC2_KEY} .env ${EC2_HOST}:/home/ubuntu/.env
docker run --rm -v $PWD:/work -v ${EC2_KEY}:${EC2_KEY} alpine/scp -i ${EC2_KEY} Dockerfile ${EC2_HOST}:/home/ubuntu/Dockerfile
docker run --rm -v $PWD:/work -v ${EC2_KEY}:${EC2_KEY} alpine/scp -i ${EC2_KEY} -r src ${EC2_HOST}:/home/ubuntu/src
docker run --rm -v $PWD:/work -v ${EC2_KEY}:${EC2_KEY} alpine/scp -i ${EC2_KEY} package*.json ${EC2_HOST}:/home/ubuntu/
"""
                    // 3. SSH to EC2 and run commands using dockerized ssh
                    sh """
docker run --rm -v ${EC2_KEY}:${EC2_KEY} alpine/ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} 'sudo apt-get update && sudo apt-get install -y nginx certbot python3-certbot-nginx'
docker run --rm -v ${EC2_KEY}:${EC2_KEY} alpine/ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} 'docker stop ${DOCKER_IMAGE} || true && docker rm ${DOCKER_IMAGE} || true && docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true && rm -f /home/ubuntu/.env'
docker run --rm -v ${EC2_KEY}:${EC2_KEY} alpine/ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} 'cd /home/ubuntu && docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} . && docker run -d --name ${DOCKER_IMAGE} -p 127.0.0.1:${PORT}:3000 --env-file .env ${DOCKER_IMAGE}:${DOCKER_TAG}'
docker run --rm -v ${EC2_KEY}:${EC2_KEY} alpine/ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} "sudo bash -c 'cat > /etc/nginx/sites-available/badminton-shop <<EOF\nserver {\n    listen 80;\n    server_name ${DOMAIN};\n    location / {\n        proxy_pass http://localhost:${PORT};\n        proxy_set_header Host \\$host;\n        proxy_set_header X-Real-IP \\$remote_addr;\n        proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto \\$scheme;\n    }\n}\nEOF' && sudo ln -sf /etc/nginx/sites-available/badminton-shop /etc/nginx/sites-enabled/badminton-shop && sudo nginx -t && sudo systemctl reload nginx"
docker run --rm -v ${EC2_KEY}:${EC2_KEY} alpine/ssh -o StrictHostKeyChecking=no -i ${EC2_KEY} ${EC2_HOST} 'sudo certbot --nginx --non-interactive --agree-tos --redirect -d ${DOMAIN} -m ${EMAIL} && sudo systemctl reload nginx'
"""
                }
            }
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