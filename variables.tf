variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "tailscale_auth_key" {
  description = "Auth Key de Tailscale para unir los nodos a la VPN"
  type        = string
  sensitive   = true
}

variable "control_node_instance_type" {
  description = "Tipo de instancia para el nodo de control"
  type        = string
  default     = "t4g.small"
}

variable "worker_node_instance_type" {
  description = "Tipo de instancia para los workers spot (burst compute)"
  type        = string
  default     = "c6g.2xlarge"
}
