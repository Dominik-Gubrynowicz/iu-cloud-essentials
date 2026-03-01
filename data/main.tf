data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "iu-poc-tf-state"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.company_name}-${var.environment}-rds-postgres-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = "10.0.0.0/16" # Align with VPC CIDR from network
    }
  ]
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.10"

  identifier = "${var.company_name}-${var.environment}-postgres"

  engine               = "postgres"
  engine_version       = "17.4"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "ecobuy"
  username = "ecs_user"
  password = random_password.db_password.result
  port     = 5432

  manage_master_user_password = false

  multi_az               = false
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.company_name}-${var.environment}-db-subnet-group"
  subnet_ids             = data.terraform_remote_state.network.outputs.private_subnets
  vpc_security_group_ids = [module.db_sg.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0 # Disable backups for sample to save cost
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Environment = var.environment
    Project     = var.company_name
  }
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.company_name}/${var.environment}/database/password"
  description = "Master password for ECS Sample RDS database"
  type        = "SecureString"
  value       = random_password.db_password.result

  tags = {
    Environment = var.environment
    Project     = var.company_name
  }
}
