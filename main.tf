terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "demo" {
  ami           = "ami-02c3627b04781eada" # AmazonLinux2のAMI
  instance_type = "t2.micro"
  key_name      = "rkw_home"

  tags = {
    Name = "tf-demo"
  }
}
