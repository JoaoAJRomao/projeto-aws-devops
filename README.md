# Projeto AWS DevOps: Provisionamento com Terraform & Automação com Ansible.

Este projeto demonstra a infraestrutura como código (IaC) e automação de gerenciamento de configuração na AWS. Ele provisiona uma instância **EC2 Ubuntu 22.04 LTS** com práticas de **Hardening de Segurança** usando **Terraform** e configura um servidor web **Nginx** usando **Ansible**.

---

## 🛠️ Tecnologias Utilizadas

- **AWS (Amazon Web Services)**: Provedor de nuvem.
- **Terraform (>= 1.0)**: Provisionamento de infraestrutura (EC2, Security Groups, Key Pairs, EBS Criptografado).
- **Ansible**: Gerenciamento de configuração (automação do Nginx).
- **Ubuntu 22.04 LTS**: Sistema Operacional do servidor web.

---

## 🔒 Destaques de Segurança (Hardening)

- **Acesso SSH Restrito**: O Security Group consulta dinamicamente o IP público do desenvolvedor via `checkip.amazonaws.com` e libera a porta 22 (SSH) **apenas** para o seu IP (`/32`).
- **Criptografia EBS**: O volume de disco da instância EC2 (8 GB gp3) é criptografado por padrão.
- **IMDSv2 Obrigatório**: A instância exige tokens para acesso aos metadados (`http_tokens = "required"`), prevenindo vulnerabilidades SSRF.
- **Free Tier Friendly**: Utiliza o tipo de instância `t2.micro`.

---

## 📂 Estrutura do Repositório

```text
.
├── main.tf              # Configurações de infraestrutura com Terraform (AWS)
├── hosts.ini            # Inventário do Ansible (IP do servidor e chave SSH)
├── playbook.yml         # Playbook do Ansible para instalação do Nginx
├── .gitignore           # Regras de exclusão do Git (estados, chaves e temporários)
└── README.md            # Documentação do projeto
```

---

## 📋 Pré-requisitos

1. **AWS CLI** instalado e autenticado (`aws configure`).
2. **Terraform** (>= 1.0) instalado.
3. **Ansible** instalado.
4. Par de chaves SSH criado em `~/.ssh/aws_ec2_key` (chave privada) e `~/.ssh/aws_ec2_key.pub` (chave pública).

### Gerando a chave SSH (caso ainda não possua):

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws_ec2_key -N ""
```

---

## 🚀 Passo a Passo para Execução

### 1. Provisionar a Infraestrutura (Terraform)

Inicialize o Terraform e aplique o plano para criar a infraestrutura na AWS:

```bash
# Inicializa os provedores
terraform init

# Visualiza o plano de execução
terraform plan

# Aplica e cria os recursos na AWS
terraform apply
```

Após a confirmação (`yes`), anote o **IP Público da EC2** exibido na saída (`Outputs`):

```text
Outputs:

ec2_public_ip = "X.X.X.X"
your_authorized_ip = "Y.Y.Y.Y/32"
```

---

### 2. Configurar o Inventário do Ansible

Abra o arquivo `hosts.ini` e substitua `{SEU-EC2-IP-PUBLICO}` pelo IP real retornado pelo Terraform:

```ini
[webservers]
X.X.X.X ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/aws_ec2_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

### 3. Executar a Automação (Ansible)

Execute o playbook para instalar e ativar o servidor Nginx na instância EC2:

```bash
ansible-playbook -i hosts.ini playbook.yml
```

---

### 4. Validar o Servidor Web

Acesse o IP público da instância via navegador ou via linha de comando (`curl`):

```bash
curl http://X.X.X.X
```

**Resposta esperada:**
```html
<h1>Servidor provisionado com Terraform e configurado via Ansible!</h1>
```

---

## 🧹 Destruição da Infraestrutura

Para remover todos os recursos criados na AWS e evitar custos indesejados:

```bash
terraform destroy
```
