# YP_AWS_COMMON_INFRA
This repository contains reusable Terraform modules and example configurations to provision and manage common AWS infrastructure (VPC, networking, IAM, logging, and monitoring), along with recommended local tooling and workflows for linting, security scanning, and deployment.

## Setting up the AWS/Terraform:
### Install Terraform:
    - brew tap hashicorp/tap
        - NOTE: 
            - Terraform is now under the BUSL license → so it cannot be in homebrew-core.
            - Therefore, to install Terraform officially on macOS, you must install from the vendor `tap`
    - brew install hashicorp/tap/terraform
    - To verify:
        - terraform -version
    - brew install tflint
        - cmd: tflint
        - NOTE:
            - This is for terraform linting
    - brew install tfsec
        - cmd: tfsec .
        - NOTE:
            - Terraform Security Scanner scans your code for security misconfigurations.
### Install AWS-CLI:
    - brew install awscli
    - aws --version
    - aws configure:
        - AWS Access Key ID (None)
        - AWS Secret Access Key (None)
        - Default region name (us-east-1)
        - Default output format (json)
        - NOTE:
            - This creates:
                - ~/.aws/credentials
                - ~/.aws/config
### Steps to run the terrafom:
    - Move to the directory where the infrastructure code is written:
    - Then run below cmd:
        - terraform init
        - terraform fmt
        - terraform validate
        - terraform plan
            - terraform plan -out=tfplan.out (OPTIONAL CMD)
            - terraform show tfplan.out
        - terraform apply tfplan.out (Optional if you are planning to actual deployment)
        - terraform destroy

### Steps to setup Jenkins(macOS)
    - Run Jenkins local:
        - Install Jenkins via Homebrew:
            - brew install jenkins-lts
        - Start Jenkins:
            - brew services start jenkins-lts
        - Access Jenkins:
            - Open browser: http://localhost:8080
            - Get initial admin password:
                - cat /Users/yash/.jenkins/secrets/initialAdminPassword
        - Stop Jenkins
            - brew services stop jenkins-lts
    - Run Jenkins in Docker(RECOMMENDED):
        - Install Docker: brew install docker
        - Start Docker Desktop: brew install --cask docker
        - Create a Jenkins container:
            - docker run -d \
                -p 8080:8080 \
                -p 50000:50000 \
                -v jenkins_home:/var/jenkins_home \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --name jenkins \
                jenkins/jenkins:lts
        - Get initial admin password
            - docker logs jenkins | grep -i "password"
        - Access Jenkins:
            - Open browser: http://localhost:8080
        - Stop Jenkins:
            - docker stop jenkins
        - Useful commands after running docker: 
            - # See if container is running
                - docker ps

            - # View Jenkins logs (including initial admin password)
                - docker logs jenkins

            - # Stop the container
                - docker stop jenkins

            - # Start it again (data persists in the volume)
                - docker start jenkins

            - # Remove the container (but keep the volume/data)
                - docker rm jenkins

            - # Connect to the container's shell
                - docker exec -it jenkins bash

            - # View the volume location on macOS
                - docker volume inspect jenkins_home




