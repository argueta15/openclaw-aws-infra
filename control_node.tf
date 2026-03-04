# control_node.tf

# Obtenemos la última AMI de Ubuntu 22.04 ARM64
data "aws_ami" "ubuntu_arm" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }
}

# IAM Role para el Control Node (necesita permisos de SQS)
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

# (Opcional) SSM para entrar por terminal web si Tailscale falla
resource "aws_iam_role_policy_attachment" "control_node_ssm" {
  role       = aws_iam_role.control_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "control_node_profile" {
  name = "openclaw-control-node-profile"
  role = aws_iam_role.control_node_role.name
}

# El nodo de control siempre prendido
resource "aws_instance" "control_node" {
  ami           = data.aws_ami.ubuntu_arm.id
  instance_type = var.control_node_instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.openclaw_sg.id]

  iam_instance_profile = aws_iam_instance_profile.control_node_profile.name

  # Provisionamiento inicial
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y curl wget git unzip jq redis-server

              # Tailscale
              curl -fsSL https://tailscale.com/install.sh | sh
              tailscale up --authkey=${var.tailscale_auth_key} --hostname=claw-control

              # Configuración de Redis
              systemctl enable redis-server
              systemctl start redis-server

              # Aquí va el clone/install de OpenClaw...
              EOF

  tags = {
    Name = "OpenClaw-ControlNode"
    Role = "Control"
  }
}
