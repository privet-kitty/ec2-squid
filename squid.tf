terraform {
  required_version = "~> 1.3.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.41.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.2.1"
    }
  }
}


provider "aws" {
  region = "ap-northeast-1"
}

data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

locals {
  current_ip   = chomp(data.http.ifconfig.response_body)
  allowed_cidr = "${local.current_ip}/32"
}

resource "aws_security_group" "allow_proxy" {
  name        = "allow_proxy"
  description = "Allow traffic for squid"
  ingress { # squid default port
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }
  ingress { # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_key_pair" "squid_key" {
  key_name   = "squid_key"
  public_key = file("./squid_key.pub")
}

resource "aws_instance" "squid_server" {
  ami                    = data.aws_ssm_parameter.amzn2_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_proxy.id]
  key_name               = aws_key_pair.squid_key.id
  user_data              = file("initialize.sh")
}

output "public_ip" {
  value = aws_instance.squid_server.public_ip
}

output "public_dns" {
  value = aws_instance.squid_server.public_dns
}

output "allowed_cidr" {
  value = local.allowed_cidr
}
