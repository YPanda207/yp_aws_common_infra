pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_DIR = '.'
        DOCKER_IMAGE = 'yp-terraform:latest'
        DOCKER_CONTAINER = 'yp-terraform-build'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/YPanda207/yp_aws_common_infra.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image with Terraform..."
                    docker build -t ${DOCKER_IMAGE} .
                    echo "Docker image built successfully!"
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                    echo "Running Terraform Init in Docker container..."
                    docker run --rm \
                      -v ${WORKSPACE}:${WORKSPACE} \
                      -w ${WORKSPACE}/${TF_DIR} \
                      ${DOCKER_IMAGE} \
                      terraform init
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                    echo "Running Terraform Plan in Docker container..."
                    docker run --rm \
                      -v ${WORKSPACE}:${WORKSPACE} \
                      -w ${WORKSPACE}/${TF_DIR} \
                      ${DOCKER_IMAGE} \
                      terraform plan -out=tfplan.out
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                input 'Approve Terraform Apply?'
                sh '''
                    echo "Running Terraform Apply in Docker container..."
                    docker run --rm \
                      -v ${WORKSPACE}:${WORKSPACE} \
                      -w ${WORKSPACE}/${TF_DIR} \
                      ${DOCKER_IMAGE} \
                      terraform apply tfplan.out
                '''
            }
        }
    }

    post {
        always {
            sh 'echo "Cleaning up Docker image..."'
            cleanWs()
        }
    }
}