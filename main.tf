terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Consulta automatica do seu IP publico local
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  # Limpa quebras de linha e formata como CIDR /32 (IP unico)
  my_ip = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# 2. Envia a sua chave publica SSH para a AWS
resource "aws_key_pair" "dev_key" {
  key_name   = "ansible-key"
  public_key = file("~/.ssh/aws_ec2_key.pub")
}

# 3. Security Group Com Regras Restritivas de Seguranca
resource "aws_security_group" "allow_ssh_http" {
  name        = "sg_ec2_ansible_secure"
  description = "Security Group com acesso SSH restrito ao meu IP"

  # SSH (Porta 22) - Apenas o SEU IP
  ingress {
    description = "SSH restrito ao IP do desenvolvedor"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # HTTP (Porta 80) - Mantido para o mundo para poder ver a pagina web
  ingress {
    description = "Acesso web publico Nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - Trafego de saida para atualizacoes do sistema (APT)
  egress {
    description = "Permitir saida para a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-ec2-secure"
  }
}

# 4. Busca da imagem mais recente do Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 5. Instancia EC2 com Hardening de Seguranca
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name               = aws_key_pair.dev_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # Força o uso do IMDSv2 (Protecao contra SSRF)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Criptografia do disco EBS da EC2
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "Servidor-Ansible-Terraform-Seguro"
  }
}

# Exibe o IP da EC2 e o IP autorizado no SSH
output "ec2_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "IP Publico da EC2 gerada"
}

output "your_authorized_ip" {
  value       = local.my_ip
  description = "Seu IP detectado que recebeu acesso SSH"
}
