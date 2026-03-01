# AWS Essentials - Application Stack Documentation

This project provisions a standard scalable, secure, and highly available web application architecture on AWS using Terraform. It is divided into four main modules: **Network**, **Data**, **Application**, and **Front**.

## Architecture Overview

1. **Network Layer**: A Virtual Private Cloud (VPC) with public and private subnets, a NAT Gateway, and an Application Load Balancer (ALB).
2. **Data Layer**: An Amazon RDS PostgreSQL database instance configured in a private subnet.
3. **Application Layer**: An Amazon Elastic Container Service (ECS) cluster running an AWS Fargate service (containerized Nginx application).
4. **Frontend Layer**: An Amazon S3 bucket for static website hosting distributed globally via Amazon CloudFront.

---

## Component Details

### 1. Network (`/network`)
- **VPC Configuration**:
  - Two public subnets and two private subnets spanning two Availability Zones.
  - A single NAT Gateway to allow outbound internet access for resources in the private subnets.
- **Application Load Balancer (ALB)**:
  - Deployed in the public subnets, acting as the entry point for API traffic.
  - Includes a security group allowing HTTP (port 80) access from anywhere.
  - Routes traffic to a default target group configured for the ECS tasks backend.

### 2. Data (`/data`)
- **RDS PostgreSQL Database**:
  - Engine: PostgreSQL 17.4
  - Instance Class: `db.t4g.micro` with 20GB to 100GB of auto-scaling storage.
  - Placed securely inside the private subnets.
- **Security & Secrets**:
  - The database security group restricts access (port 5432) to only traffic originating from within the VPC.
  - A randomly generated master password is created and securely stored in AWS Systems Manager (SSM) Parameter Store.
  - Backups are currently disabled, and cluster deletion protection is off (suitable for POC/development environments).

### 3. Application (`/application`)
- **ECS Cluster (Fargate)**:
  - Runs in serverless mode using AWS Fargate capacity providers.
- **ECS Service**:
  - Deployed in the private subnets for enhanced security.
  - Contains a single `nginx` container exposed on port 80.
  - Connects to the ALB target group for health checks and traffic processing.
  - Container configuration contains a custom startup command providing a static JSON response for `/api/health`.
  - Injects the `DB_HOST` environment variable automatically mapped to the deployed RDS instance.
- **Auto-scaling & Monitoring**:
  - Uses Target Tracking Scaling to dynamically adjust container replicas (from 1 up to 4) striving for an average CPU utilization of 80%.
  - Configured with CloudWatch Alarms to monitor and alert on ALB `4xx` and `5xx` errors.
  - Application logs are routed to a CloudWatch Log Group.

### 4. Frontend (`/front`)
- **Amazon S3**:
  - Hosts the static application files (e.g., `index.html`).
  - Configured with `BucketOwnerEnforced` object ownership for a secure baseline.
- **Amazon CloudFront**:
  - Acts as the global Content Delivery Network (CDN) with routing behaviors.
  - **Static Assets**: Routes the default path to the S3 bucket. Access to the S3 bucket is strictly locked down using Origin Access Control (OAC), ensuring data is ONLY retrieved through CloudFront.
  - **API Routing**: Configured with an ordered cache behavior that proxies all `/api/*` requests securely to the Application Load Balancer.
  - The distribution sets `index.html` as its `default_root_object` and enables the default CloudFront viewer certificate (HTTPS enabled for the `.cloudfront.net` domain).

## State Management
Each module relies on a centralized remote Terraform state file hosted in an AWS S3 backend (`iu-poc-tf-state`). Component outputs (such as VPC ID, ALB ARN, Db Endpoint) are shared dynamically via `terraform_remote_state` data sources, ensuring the stack provisions and links properly cross-module without manual hardcoding.
