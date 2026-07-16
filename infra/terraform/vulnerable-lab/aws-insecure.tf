# Intentionally vulnerable Terraform for Veracode IaC lab tests.
# Do not apply this configuration in any real environment.

resource "aws_s3_bucket" "public_artifacts" {
  bucket = "veracode-lab-public-artifacts"
}

resource "aws_s3_bucket_public_access_block" "public_artifacts" {
  bucket = aws_s3_bucket.public_artifacts.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public_artifacts" {
  bucket = aws_s3_bucket.public_artifacts.id
  acl    = "public-read"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "weak_encryption" {
  bucket = aws_s3_bucket.public_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "open_admin_ports" {
  name        = "veracode-lab-open-admin-ports"
  description = "Intentionally open security group for IaC scan testing"

  ingress {
    description = "SSH open to the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP open to the internet"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All TCP ports open to the internet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "insecure_microservice_host" {
  ami                         = "ami-1234567890abcdef0"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.open_admin_ports.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  root_block_device {
    encrypted = false
  }

  user_data = <<-USERDATA
    #!/usr/bin/env bash
    export DATABASE_PASSWORD='TerraformLabPassword123!'
    export AWS_ACCESS_KEY_ID='AKIAIOSFODNN7EXAMPLE'
    export AWS_SECRET_ACCESS_KEY='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
    echo "admin:TerraformLabPassword123!" > /tmp/credentials.txt
    chmod 777 /tmp/credentials.txt
  USERDATA

  tags = {
    Name        = "veracode-lab-insecure-host"
    Environment = "lab"
  }
}
