/*
1. VPC
2. Route53 Zone (Manages DNS domains and records in AWS Route 53)
3. S3
4. Lambda Role
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

# 2. Route53 Zone
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

# 3. S3 bucket, access rule & versioning
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

# 4. Lambda Roles and Policies
## This role allows Lambda to do things inside AWS.
resource "aws_iam_role" "lambda_role" {
  name = "${var.namespace}-lambda-exec-role"
  assume_role_policy = jsondecode({
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
  policy = jsondecode({
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
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.ddb_table_name}"
      },
    ]
  })
}

# Attach the S3 and Dynamodb policy to lambda
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.policy.arn
}
