# Configuração do provedor AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC e Subnets
resource "aws_vpc" "farmacia_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "farmacia-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.farmacia_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "farmacia-private-subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.farmacia_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "farmacia-private-subnet-2"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.farmacia_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "farmacia-public-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "farmacia_igw" {
  vpc_id = aws_vpc.farmacia_vpc.id

  tags = {
    Name = "farmacia-igw"
    Environment = var.environment
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.farmacia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.farmacia_igw.id
  }

  tags = {
    Name = "farmacia-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "rds_sg" {
  name        = "farmacia-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.farmacia_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "farmacia-rds-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "farmacia-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.farmacia_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "farmacia-lambda-sg"
    Environment = var.environment
  }
}

# Subnet Group para RDS
resource "aws_db_subnet_group" "farmacia_db_subnet_group" {
  name       = "farmacia-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "farmacia-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Instance
resource "aws_db_instance" "farmacia_db" {
  identifier = "farmacia-db"
  
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "farmacia_db"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.farmacia_db_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name = "farmacia-db"
    Environment = var.environment
  }
}

# S3 Bucket para armazenamento
resource "aws_s3_bucket" "farmacia_bucket" {
  bucket = "abstergo-farmacia-${var.environment}-${random_string.bucket_suffix.result}"

  tags = {
    Name = "farmacia-storage-bucket"
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "farmacia_bucket_versioning" {
  bucket = aws_s3_bucket.farmacia_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "farmacia_bucket_lifecycle" {
  bucket = aws_s3_bucket.farmacia_bucket.id

  rule {
    id     = "archive_old_files"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# IAM Role para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "farmacia-lambda-role"

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

# IAM Policy para Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "farmacia-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.farmacia_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "estoque_handler" {
  filename         = "../lambda/functions/estoque_handler.zip"
  function_name    = "farmacia-estoque-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "estoque_handler.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      DB_HOST     = aws_db_instance.farmacia_db.endpoint
      DB_NAME     = aws_db_instance.farmacia_db.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      S3_BUCKET   = aws_s3_bucket.farmacia_bucket.bucket
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name = "farmacia-estoque-handler"
    Environment = var.environment
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "farmacia_api" {
  name = "farmacia-api"

  tags = {
    Name = "farmacia-api"
    Environment = var.environment
  }
}

resource "aws_api_gateway_resource" "estoque_resource" {
  rest_api_id = aws_api_gateway_rest_api.farmacia_api.id
  parent_id   = aws_api_gateway_rest_api.farmacia_api.root_resource_id
  path_part   = "estoque"
}

resource "aws_api_gateway_method" "estoque_get" {
  rest_api_id   = aws_api_gateway_rest_api.farmacia_api.id
  resource_id   = aws_api_gateway_resource.estoque_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "estoque_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.farmacia_api.id
  resource_id = aws_api_gateway_resource.estoque_resource.id
  http_method = aws_api_gateway_method.estoque_get.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.estoque_handler.invoke_arn
}

# Lambda Permission para API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.estoque_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.farmacia_api.execution_arn}/*/*"
}

# Outputs
output "rds_endpoint" {
  value = aws_db_instance.farmacia_db.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.farmacia_bucket.bucket
}

output "api_gateway_url" {
  value = "${aws_api_gateway_rest_api.farmacia_api.execution_arn}/prod/estoque"
}
