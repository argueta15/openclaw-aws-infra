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

variable "ssh_public_key" {
  description = "Llave pública SSH para acceso al nodo de control"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD1fkT7N+/02UWNU+QnfXiiYbTcOqYOU7XIwCtEgGh9mSyQPmiNrkh3lEf9AKnIL7J92GSgXH6dhct5YA6ekCg9NyOC3HNf1FJQvEK6AxzZpPoWu2mT1w+Wd4tgPu7aOo8BDWKrZpvY1FSU4qNnQiy0DNCnAtn3QnZB74k8ev8qbi2WDkBLfhLQNJajgLZ48AqV9+GmnAKniZ5kUd9Q7afvVhKgo4zXXBjsBaXDmqPl2B/MsQsH8q3uO+7+a5EnPivKxCgJnMQq/ffk5HQwKle6pw+v6EZmkHIsNFomDu7mvlJC3fadIKlSwAPr0gKqVSjIJ8i5yEapACI/5oO22mfoV26LxHIedZYp84th0RffQdE5YeHQ8dNojnZoiFbcCh75HdoU/RlT1sUuOyMPuXMcFbUtltYqHGbvp+JGu4wEdrCFRTcQy/6+shjvuMS7+xXVsAQlsG7wkzNqSEnZY0F+7g7Q+vbOMXD6lvykTXk3uBl8agpzegmgX0cD/aWKGis= ger@MacBook-Pro-de-Ger.local"
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
