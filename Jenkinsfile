pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        TF_DIR = '.'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/YPanda207/yp_aws_common_infra.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'cd ${TF_DIR} && terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'cd ${TF_DIR} && terraform plan -out=tfplan.out'
            }
        }

        stage('Terraform Apply') {
            steps {
                input 'Approve Terraform Apply?'
                sh 'cd ${TF_DIR} && terraform apply tfplan.out'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}