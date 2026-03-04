# OpenClaw AWS Infra (Burst Compute)

Arquitectura de infraestructura como código (Terraform) para desplegar OpenClaw en AWS optimizando costos (<$20/mes) y maximizando rendimiento mediante "Burst Compute".

## Propósito

Este repositorio contiene la infraestructura para desplegar un asistente **OpenClaw** personal para Gera. 
El objetivo de este asistente es apoyarlo en:
- Sus emprendimientos y negocios (ClawOps, etc.)
- Desarrollo personal y guía (en su etapa actual de 18 años).
- Aprendizaje tecnológico (viendo cómo funciona la IA y la infraestructura por detrás).
- Demostraciones de ventas (Gera podrá usar este asistente para mostrar a sus clientes de qué es capaz y vender servicios similares).

## Arquitectura (AWS)

La arquitectura sigue un modelo de "Control Node + Burst Compute":
1. **Control Node (siempre activo):** Una instancia EC2 `t4g.small` (ARM64) muy económica que ejecuta OpenClaw y un servidor Redis. Se mantiene conectado de manera segura a través de **Tailscale** (sin puertos expuestos a internet).
2. **Cola SQS:** Amazon SQS maneja de forma asíncrona y confiable los trabajos (jobs) que emiten los agentes de OpenClaw.
3. **Lambda Trigger:** Una función AWS Lambda escucha la cola SQS. Cuando llegan trabajos pesados, desencadena la creación de instancias "Worker".
4. **Workers Temporales (Spot):** Instancias de alto rendimiento (ej. 32 vCPUs) que se levantan solo para procesar el trabajo encolado y luego se apagan automáticamente. Como se utiliza el mercado Spot y solo viven minutos, el costo es de un par de centavos por ejecución pesada.

## Despliegue

```bash
# Inicializar Terraform
terraform init

# Revisar los cambios
terraform plan

# Aplicar infraestructura
terraform apply
```

> **Nota de seguridad:** Se requiere configurar la variable `tailscale_auth_key` para que los nodos puedan unirse a la red privada VPN.
