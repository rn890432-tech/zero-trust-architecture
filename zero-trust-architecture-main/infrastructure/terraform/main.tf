# Terraform AWS Infrastructure
provider "aws" {
  region = "us-east-1"
}
resource "aws_eks_cluster" "main" {
  name     = "soc-platform-cluster"
  role_arn = "arn:aws:iam::123456789012:role/EKSRole"
  vpc_config {
    subnet_ids = ["subnet-abc", "subnet-def"]
  }
}
resource "aws_rds_cluster" "postgres" {
  cluster_identifier = "soc-postgres"
  engine = "aurora-postgresql"
  master_username = "admin"
  master_password = "securepassword"
  skip_final_snapshot = true
}
