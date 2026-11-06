# 🚀 End-to-End DevOps Infrastructure & Cloud-Native Deployment

![AWS](https://img.shields.io/badge/AWS-VPC%20%7C%20EC2%20%7C%20Networking-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Orchestration-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18--Alpine-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)

Un proyecto DevOps integral que demuestra la automatización de infraestructura como código (IaC), la optimización de contenedores y la orquestación de servicios mediante las mejores prácticas de la industria *Cloud Native*.

---

## 📌 Visión General del Proyecto

Este repositorio contiene la arquitectura completa de una aplicación web moderna (Node.js), desplegada desde cero mediante un pipeline de automatización que abarca:

1. **Infraestructura como Código (IaC)**: Provisionamiento de red modular y altamente accesible en **AWS** con **Terraform**.
2. **Contenerización Eficiente**: Construcción de una imagen ultraligera con **Docker Multi-stage builds**.
3. **Orquestación y Alta Disponibilidad**: Despliegue supervisado en **Kubernetes** con controles de salud de producción.

---

### Componentes Clave

* **Red en AWS (Terraform)**:
  * VPC dedicada con división entre subredes públicas y privadas.
  * *Internet Gateway* (IGW) para tráfico entrante y *NAT Gateway* con *Elastic IP* (EIP) para conectividad segura de salida.
  * Tablas de enrutamiento explícitas estableciendo un orden de pasos con `depends_on`.
  * Posibilidad de incremento con servicios como EC2, RDS, S3 a petición.

* **Empaquetado de Aplicación (Docker)**:
  * Arquitectura **Multi-Stage** basada en `node:18-alpine` para reducir la superficie de ataque y optimizar el tamaño de la imagen final.
  * Ejecución bajo un usuario no-root por seguridad.

* **Orquestación en Kubernetes**:
  * **Deployment declarativo** con 2 réplicas para garantizar la tolerancia a fallos.
  * Limite estricto de recursos de CPU y RAM (`requests` / `limits`) para evitar saturación.
  * **Sondas de Salud**: `livenessProbe` para autorecuperación y `readinessProbe` para balanceo de carga sin caídas de servicio.
  * **Service (NodePort)** para la exposición y balanceo interno de red.

---

## 🛠️ Tecnologías y Herramientas

| Capa | Tecnología | Descripción |
| :--- | :--- | :--- |
| **Cloud Provider** | AWS | Infraestructura base de red y cómputo |
| **IaC** | Terraform | Automatización declarativa de recursos cloud |
| **Contenedores** | Docker | Construcción multi-stage de imágenes pequeñas y seguras |
| **Orquestación** | Kubernetes (`kind` / `kubectl`) | Gestión del ciclo de vida, réplicas y salud del servicio |
| **Backend** | Node.js / Express | API ligera utilizada como aplicación de prueba |

---

## 📁 Estructura del Repositorio

```bash
.
├── terraform/          # Módulo IaC: VPC, Subnets, Gateways, Route Tables
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── docker/             # Definición de contenedor optimizado
│   ├── Dockerfile
│   ├── .dockerignore
│   └── README.md
├── kubernetes/         # Manifiestos de orquestación y red
│   ├── deployment.yaml
│   ├── service.yaml
│   └── README.md
├── app/                # Código fuente de la aplicación Node.js
│   ├── package.json
│   └── app.js
└── README.md           # Documentación principal del proyecto
```

---

## 🚀 Inicio Rápido / Guía de Despliegue

Cada uno de los módulos principales cuenta con su propia documentación exhaustiva y pasos detallados:

1. 🌐 **Infraestructura AWS**: Consulta [`terraform/README.md`](./terraform/README.md) para el despliegue con IaC.
2. 🐳 **Construcción de Contenedores**: Consulta [`docker/README.md`](./docker/README.md) para empaquetar la aplicación.
3. ☸️ **Orquestación en Kubernetes**: Consulta [`kubernetes/README.md`](./kubernetes/README.md) para desplegar los manifiestos en un clúster local.

---

## 👨‍💻 Autor

Proyecto básico desarrollado como parte de un laboratorio de ingenieria DevOps con el objetivo de aprender las buenas practicas y la estructura y arquitectura cloud correcta.