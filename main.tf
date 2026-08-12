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

# 1. Habilita o IAM Access Analyzer (Resolve o achado de severidade LOW)
resource "aws_accessanalyzer_analyzer" "account_analyzer" {
  analyzer_name = "account-access-analyzer"
  type          = "ACCOUNT"

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Project     = "Ansible-EC2-Lab"
  }
}

# 2. Consulta automatica do seu IP publico local
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# 3. Envia a chave publica SSH com tags adicionais
resource "aws_key_pair" "dev_key" {
  key_name   = "ansible-key"
  public_key = file("~/.ssh/aws_ec2_key.pub")

  tags = {
    Name        = "ansible-key"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Project     = "Ansible-EC2-Lab"
  }
}

# 4. Security Group com tags de governanca
resource "aws_security_group" "allow_ssh_http" {
  name        = "sg_ec2_ansible_secure"
  description = "Security Group com acesso SSH restrito ao meu IP"

  # SSH (Porta 22) - Apenas o seu IP
  ingress {
    description = "SSH restrito ao IP do desenvolvedor"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # HTTP (Porta 80) - Acesso web publico (Risco aceito para ambiente de teste)
  ingress {
    description = "Acesso web publico Nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permitir saida para a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-ec2-secure"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Project     = "Ansible-EC2-Lab"
  }
}

# 5. Busca da imagem mais recente do Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 6. Instancia EC2 com Hardening, Monitoramento e EBS Otimizado
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name               = aws_key_pair.dev_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # Habilita monitoramento detalhado do CloudWatch (Resolve achado MEDIUM)
  monitoring = true

  # Habilita otimizacao de EBS (Resolve achado INFO)
  ebs_optimized = true

  # Protecao IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Criptografia do disco EBS
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "Servidor-Ansible-Terraform-Seguro"
    Environment = "Dev"
    ManagedBy   = "Terraform"
    Project     = "Ansible-EC2-Lab"
  }
}

output "ec2_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "IP Publico da EC2 gerada"
}

output "your_authorized_ip" {
  value       = local.my_ip
  description = "Seu IP detectado que recebeu acesso SSH"
}
