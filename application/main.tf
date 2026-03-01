data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "iu-poc-tf-state"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "iu-poc-tf-state"
    key    = "data/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 7.3"

  cluster_name = "${var.company_name}-${var.environment}-cluster"

  cluster_capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.company_name
  }
}

module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${var.company_name}-${var.environment}-ecs-app-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = data.terraform_remote_state.network.outputs.alb_security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.3"

  name        = "${var.company_name}-${var.environment}-app-service"
  cluster_arn = module.ecs_cluster.cluster_arn

  cpu    = 256
  memory = 512

  container_definitions = {
    nginx = {
      cpu                    = 256
      memory                 = 512
      essential              = true
      image                  = "nginx:${var.image_tag}"
      readonlyRootFilesystem = false

      command = [
        "/bin/sh",
        "-c",
        <<-EOT
          cat > /etc/nginx/conf.d/default.conf <<'EOF'
          server {
              listen 80;
              location /api/health {
                  access_log off;
                  add_header Content-Type application/json;
                  return 200 '{"status": "ok"}';
              }
              location / {
                  root /usr/share/nginx/html;
                  index index.html index.htm;
              }
          }
          EOF
          exec nginx -g 'daemon off;'
        EOT
      ]

      portMappings = [
        {
          name          = "nginx-80"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = data.terraform_remote_state.data.outputs.db_instance_address
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = data.terraform_remote_state.network.outputs.alb_target_group_arn
      container_name   = "nginx"
      container_port   = 80
    }
  }

  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
  security_group_ingress_rules = {
    alb_ingress = {
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      referenced_security_group_id = data.terraform_remote_state.network.outputs.alb_security_group_id
    }
  }

  security_group_egress_rules = {
    egress_all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 4
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 80
      }
    }
  }

  assign_public_ip = false
}
