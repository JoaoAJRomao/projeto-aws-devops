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
- **Princípio do Menor Privilégio (PoLP)**: O usuário IAM que executa o Terraform utiliza uma política personalizada contendo apenas as permissões estritamente necessárias para a EC2 e recursos associados.
- **Free Tier Friendly**: Utiliza o tipo de instância `t2.micro`.

---

## 🔑 Permissões IAM (Princípio do Menor Privilégio)

Para executar o Terraform com segurança sem conceder permissões excessivas (como `AdministratorAccess`), utilize a política de IAM minimalista abaixo.

### 📄 Política IAM em JSON (`TerraformEC2MinimalPolicy`)

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "TerraformEC2MinimalPermissions",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeImages",
				"ec2:DescribeKeyPairs",
				"ec2:CreateKeyPair",
				"ec2:ImportKeyPair",
				"ec2:DeleteKeyPair",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeSecurityGroupRules",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupIngress",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceAttribute",
				"ec2:DescribeInstanceTypes",
				"ec2:DescribeInstanceCreditSpecifications",
				"ec2:ModifyInstanceCreditSpecification",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeNetworkInterfaceAttribute",
				"ec2:DescribeVolumes",
				"ec2:DescribeTags",
				"ec2:RunInstances",
				"ec2:TerminateInstances",
				"ec2:CreateTags"
			],
			"Resource": "*"
		}
	]
}
```

### 🛠️ Como Criar e Anexar a Política ao Usuário Terraform

#### Método 1: Pelo Console Web da AWS

1. **Acesse o IAM:** Faça login no Console AWS e navegue até **IAM** (*Identity and Access Management*).
2. **Criar Política:**
   - No menu esquerdo, clique em **Policies** (Políticas) > **Create policy** (Criar política).
   - Selecione a aba **JSON**, apague o conteúdo padrão e cole o JSON da política acima.
   - Clique em **Next** (Próximo).
   - Defina o nome da política como `TerraformEC2MinimalPolicy` e clique em **Create policy**.
3. **Anexar ao Usuário:**
   - No menu esquerdo, clique em **Users** (Usuários) e selecione o usuário que executa o Terraform.
   - Na aba **Permissions** (Permissões), clique em **Add permissions** (Adicionar permissões) > **Attach policies directly** (Anexar políticas diretamente).
   - Busque por `TerraformEC2MinimalPolicy`, selecione-a e clique em **Add permissions**.

#### Método 2: Via AWS CLI

Caso prefira a linha de comando:

```bash
# 1. Criar a política na AWS
aws iam create-policy \
  --policy-name TerraformEC2MinimalPolicy \
  --policy-document '{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "TerraformEC2MinimalPermissions",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeImages",
				"ec2:DescribeKeyPairs",
				"ec2:CreateKeyPair",
				"ec2:ImportKeyPair",
				"ec2:DeleteKeyPair",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeSecurityGroupRules",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupIngress",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceAttribute",
				"ec2:DescribeInstanceTypes",
				"ec2:DescribeInstanceCreditSpecifications",
				"ec2:ModifyInstanceCreditSpecification",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeNetworkInterfaceAttribute",
				"ec2:DescribeVolumes",
				"ec2:DescribeTags",
				"ec2:RunInstances",
				"ec2:TerminateInstances",
				"ec2:CreateTags"
			],
			"Resource": "*"
		}
	]
}'

# 2. Anexar a política ao seu usuário do Terraform (substitua SEU_USUARIO e SEU_ACCOUNT_ID)
aws iam attach-user-policy \
  --user-name SEU_USUARIO \
  --policy-arn arn:aws:iam::SEU_ACCOUNT_ID:policy/TerraformEC2MinimalPolicy
```

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
