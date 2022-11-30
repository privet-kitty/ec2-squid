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

variable "aws_region" {
  default = "ap-northeast-1"
}

provider "aws" {
  region = var.aws_region
}

data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

locals {
  current_ip   = chomp(data.http.ifconfig.response_body)
  allowed_cidr = "${local.current_ip}/32"
}

resource "aws_vpc" "proxy_vpc" {
  cidr_block                       = "172.31.0.0/16"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = "false"
}

resource "aws_subnet" "proxy_vpc_public_subnet" {
  vpc_id                          = aws_vpc.proxy_vpc.id
  cidr_block                      = "172.31.0.0/20"
  assign_ipv6_address_on_creation = "false"
  map_public_ip_on_launch         = "true"
  # availability_zone can't be fixed because the region isn't fixed either.

  tags = {
    Name = "proxy_vpc_public_subnet"
  }
}

resource "aws_route_table" "proxy_vpc_public_rt" {
  vpc_id = aws_vpc.proxy_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proxy_igw.id
  }
}

resource "aws_main_route_table_association" "public_rt_vpc" {
  vpc_id         = aws_vpc.proxy_vpc.id
  route_table_id = aws_route_table.proxy_vpc_public_rt.id
}

resource "aws_route_table_association" "public_rt_public_subnet" {
  subnet_id      = aws_subnet.proxy_vpc_public_subnet.id
  route_table_id = aws_route_table.proxy_vpc_public_rt.id
}

resource "aws_internet_gateway" "proxy_igw" {
  vpc_id = aws_vpc.proxy_vpc.id
  tags = {
    Name = "proxy_igw"
  }
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

  tags = {
    Name = "squid_server"
  }
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
