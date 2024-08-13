terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.48.0"
    }
  }
  backend "s3" {
    bucket = "rithin-remotestate"
    key = "expense-infra-app-alb1"
    region = "us-east-1"
    dynamodb_table = "rithin-locking"
  }
}
#provide authentication here
provider "aws" {
  region = "us-east-1"
}