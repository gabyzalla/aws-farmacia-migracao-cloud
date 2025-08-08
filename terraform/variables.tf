variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Usuário do banco de dados RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Senha do banco de dados RDS"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block para a primeira subnet privada"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block para a segunda subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR block para a subnet pública"
  type        = string
  default     = "10.0.3.0/24"
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado para o RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Armazenamento máximo alocado para o RDS (GB)"
  type        = number
  default     = 100
}

variable "lambda_timeout" {
  description = "Timeout da função Lambda (segundos)"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memória alocada para a função Lambda (MB)"
  type        = number
  default     = 256
}

variable "backup_retention_period" {
  description = "Período de retenção de backup do RDS (dias)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags padrão para todos os recursos"
  type        = map(string)
  default = {
    Project     = "Abstergo-Farmacia"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}
