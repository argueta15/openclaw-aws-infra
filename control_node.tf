# control_node.tf

# Última AMI de Ubuntu 22.04 ARM64
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "ger_mac" {
  key_name   = "ger-mac"
  public_key = var.ssh_public_key
}

# IAM Role para el Control Node
resource "aws_iam_role" "control_node_role" {
  name = "openclaw-control-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "control_node_sqs" {
  role       = aws_iam_role.control_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "control_node_ssm" {
  role       = aws_iam_role.control_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "control_node_profile" {
  name = "openclaw-control-node-profile"
  role = aws_iam_role.control_node_role.name
}

# Nodo de control (siempre prendido)
resource "aws_instance" "control_node" {
  ami           = data.aws_ami.ubuntu_arm.id
  instance_type = var.control_node_instance_type
  key_name      = aws_key_pair.ger_mac.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.openclaw_sg.id]

  iam_instance_profile = aws_iam_instance_profile.control_node_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail
              exec > /var/log/user-data.log 2>&1

              echo "=== Actualizando sistema ==="
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y curl wget git unzip jq redis-server build-essential

              echo "=== Instalando Tailscale ==="
              curl -fsSL https://tailscale.com/install.sh | sh
              tailscale up --authkey=${var.tailscale_auth_key} --hostname=claw-control --ssh

              echo "=== Configurando Redis ==="
              systemctl enable redis-server
              systemctl start redis-server

              echo "=== Instalando Node.js 22 (ARM64) ==="
              curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
              apt-get install -y nodejs
              npm install -g pnpm

              echo "=== Instalando SSM Agent ==="
              snap install amazon-ssm-agent --classic
              systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
              systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

              echo "=== Instalando OpenClaw ==="
              npm install -g openclaw

              echo "=== Setup completo ==="
              echo "$(date): User data finished" >> /var/log/user-data-complete.log
              EOF

  tags = {
    Name = "OpenClaw-ControlNode"
    Role = "Control"
  }
}

output "control_node_id" {
  value = aws_instance.control_node.id
}

output "control_node_public_ip" {
  value = aws_instance.control_node.public_ip
}
