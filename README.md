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





