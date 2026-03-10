# AWS Cloud Infrastructure for Resilient Messaging Platform
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_eks_cluster" "main" {
  name     = "resilient-messaging-cluster"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.private.id]
  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 6
  }
}

resource "aws_elb" "api_gateway_lb" {
  name = "api-gateway-lb"
  subnets = [aws_subnet.public.id]
}

resource "aws_rds_cluster" "postgres" {
  cluster_identifier = "messaging-postgres"
  engine = "aurora-postgresql"
  master_username = "admin"
  master_password = "securepassword"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_vpc.main.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "messaging-redis"
  engine = "redis"
  node_type = "cache.t3.micro"
  num_cache_nodes = 2
  subnet_group_name = aws_subnet.private.id
}

resource "aws_s3_bucket" "attachments" {
  bucket = "messaging-attachments"
}

resource "aws_s3_bucket" "logs" {
  bucket = "messaging-logs"
}

# Managed Kafka (MSK)
resource "aws_msk_cluster" "kafka" {
  cluster_name = "messaging-kafka"
  kafka_version = "2.8.1"
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type = "kafka.m5.large"
    client_subnets = [aws_subnet.private.id]
    security_groups = [aws_vpc.main.id]
  }
}

# IAM roles, security, and other resources would be defined here
