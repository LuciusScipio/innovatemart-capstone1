terraform {
  backend "s3" {
    bucket         = "project-bedrock-tfstate-cype" 
    key            = "state/terraform.tfstate"     
    region         = "us-east-1"
    encrypt        = true                          
  }
}

# ==========================================
# PART 1: NETWORKING (VPC & SUBNETS)
# ==========================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "project-bedrock-vpc"
  cidr = "10.0.0.0/16"

  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Budget-friendly optimization for capstone projects

  # Critical tags for AWS Load Balancer Controller discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }


  tags = {
    Project = "karatu-2025-capstone"
  }
}

# ==========================================
# PART 2: COMPUTATION (AMAZON EKS CLUSTER)
# ==========================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "project-bedrock-cluster"
  cluster_version = "1.34" # Meets >= 1.34.0 standard

# ADD THESE TWO LINES TO ENABLE PUBLIC ENDPOINT ACCESS:
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Dynamically pull the network settings from the VPC module above
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
# ADD THIS BLOCK HERE TO CONFIGURE THE VPC CNI ADDON PERMANENTLY:
  cluster_addons = {
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Control Plane Logging 
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Worker Nodes Group Configuration
  eks_managed_node_groups = {
    bedrock_nodes = {
      min_size       = 4
      max_size       = 5
      desired_size   = 5
      instance_types = ["t3.micro", "t3a.micro"] # Reliable and cost-efficient for microservices
      iam_role_additional_policies = {
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonDynamoDBFullAccess    = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
      }
    }
  }

  # Gives your deployment account cluster admin access automatically
  enable_cluster_creator_admin_permissions = true

  # Mandatory Capstone Project Tagging
  tags = {
    Project = "karatu-2025-capstone"
  }
}

# ===========================================
# PART 3: SECURITY GROUPS (THE FIREWALL)
# ===========================================

resource "aws_security_group" "db_sg" {
  name        = "project-bedrock-db-sg"
  description = "Allow inbound traffic from EKS worker nodes to RDS"
  vpc_id      = module.vpc.vpc_id

  # Inbound MySQL (3306) from EKS Nodes
  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

# Supplementary entry for cluster shared communication
  ingress {
    description     = "MySQL from EKS Cluster security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  # Inbound PostgreSQL (5432) from EKS Nodes
  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  # Outbound rule (Corrected to global wildcard)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = "karatu-2025-capstone" }
}

# ===========================================
# PART 4: DATA LAYER (RDS & DYNAMODB)
# ===========================================

# Subnet Group
resource "aws_db_subnet_group" "bedrock_db_subnet_group" {
  name       = "project-bedrock-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = { Project = "karatu-2025-capstone" }
}

# Amazon RDS MySQL (For Catalog Service)
resource "aws_db_instance" "mysql" {
  identifier             = "project-bedrock-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "catalog"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.bedrock_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Project = "karatu-2025-capstone" }
}

# Amazon RDS PostgreSQL (For Orders Service)
resource "aws_db_instance" "postgres" {
  identifier             = "project-bedrock-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "orders"
  username               = "dbadmin"
  password               = "BedrockSecurePass123!"
  db_subnet_group_name   = aws_db_subnet_group.bedrock_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Project = "karatu-2025-capstone" }
}


# Amazon DynamoDB Table (For Carts Service)
resource "aws_dynamodb_table" "carts" {
  name         = "project-bedrock-carts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id" # The primary partition key expected by the retail application

  attribute {
    name = "id"
    type = "S"
  }

  # 1. Define the customerId attribute so it can be used in the index
  attribute {
    name = "customerId"
    type = "S"
  }

  # 2. Configure the Global Secondary Index the Spring Boot app requires
  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  tags = { Project = "karatu-2025-capstone" }
}
# ===========================================
# PART 5: OBSERVABILITY
# ===========================================
