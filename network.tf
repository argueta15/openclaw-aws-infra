# network.tf

# Utilizamos la VPC por defecto para mantener costos bajos (sin NAT Gateways)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "openclaw_sg" {
  name        = "openclaw-sg"
  description = "Security Group para OpenClaw (Solo salida, entrada via Tailscale)"
  vpc_id      = data.aws_vpc.default.id

  # Inbound = 0 (Tailscale hace el tunel, no hay puertos expuestos a internet)
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "OpenClaw-SG"
  }
}
