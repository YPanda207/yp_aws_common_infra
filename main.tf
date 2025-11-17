/*
- VPC
- Route53 Zone (Manages DNS domains and records in AWS Route 53)
- S3
*/
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
