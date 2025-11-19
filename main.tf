/*
1. VPC
2. Subnets
  2a. Private Subnets
  2b. Public Subnets
3. Security Group
  3a. Lambda Security Group
4. Route53 Zone (Manages DNS domains and records in AWS Route 53)
5. S3
6. Lambda Role
*/
# 1. Setup VPC
resource "aws_vpc" "vpc" {
  /*
    - It must be between /16 and /28 (e.g., 10.0.0.0/16 to 10.0.0.0/28).
    - It must not overlap with other VPCs in the same region/account.
    - It must be a private IP range (recommended: 10.0.0.0/16, 172.16.0.0/16, or 192.168.0.0/16).
    - Within the same AWS account and region, you cannot have two VPCs with overlapping CIDR blocks.
    - Across different accounts or regions, using the same CIDR block is fine, 
      but if you later connect those VPCs (e.g., with VPC peering or Transit Gateway),
      overlapping CIDR blocks will cause routing conflicts and are not allowed.
  */
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default" # or "dedicated" (This means Instances run on shared or dedicated hardware to you)
  enable_dns_support   = true      # Allows instances in the VPC to resolve AWS-provided DNS names (e.g., internal IPs, AWS service endpoints).
  enable_dns_hostnames = true      # Assigns DNS hostnames to EC2 instances launched in the VPC. This is required if you want your instances to have public DNS names (e.g., ec2-xx-xx-xx-xx.compute-1.amazonaws.com)
}

# 2. Subnets
# 2a. Private Subnets
resource "aws_sunbet" "private_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-a"
    Tier = "private"
  }
}
resource "aws_sunbet" "private_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-b"
    Tier = "private"
  }
}

# 2b. Public Subnets
resource "aws_sunbet" "public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
    Tier = "public"
  }
}

# 3. Security Group
# 3a. Lambda Security Group
resource "aws_security_group" "lambda_sec_grp" {
  name   = "${var.namespace}-lambda-sec-grp-${var.yp_environment}"
  vpc_id = aws_vpc.vpc.id

  # Allow all outbound means allow lambda to talk to: NAT, AWS APIs, VPC endpoints, RDS, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Route53 Zone
resource "aws_route53_zone" "public_zone" {
  name          = "yp-external.world.com"
  force_destroy = false
}

resource "aws_route53_zone" "private_zone" {
  name          = "yp-internal.world.com"
  force_destroy = false
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

# 5. S3 bucket, access rule & versioning
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.namespace}-world-${var.yp_environment}-${var.aws_region}"
}

resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 6. Lambda Roles and Policies
## This role allows Lambda to do things inside AWS.
resource "aws_iam_role" "lambda_role" {
  name = "${var.namespace}-lambda-exec-role"
  # aws_iam_role.assume_role_policy expects a JSON string. Use jsonencode to
  # convert the HCL object into a JSON string (jsondecode expects a string
  # input and would error with an object).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS provided global CWLogs policy so that lambda can write logs to CWlogs
resource "aws_iam_role_policy_attachment" "cwlogs_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Creates the policy to Read & Write in S3 and Dynamodb
resource "aws_iam_policy" "policy" {
  name = "${var.namespace}-lambda-policy"
  # aws_iam_policy.policy expects a JSON string for the policy document.
  # Use jsonencode to encode the HCL object as JSON.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ---------- S3 READ & WRITE ----------
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.namespace}-world-${var.yp_environment}-${var.aws_region}",
          "arn:aws:s3:::${var.namespace}-world-${var.yp_environment}-${var.aws_region}/*"
        ]
      },
      # ---------- DynamoDB READ & WRITE ----------
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.namespace}-*"
      },
    ]
  })
}

# Attach the S3 and Dynamodb policy to lambda
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy.arn
}
