# 🏗️ Módulo de Infraestructura de Red AWS (Terraform)

Este directorio contiene la configuración de Infraestructura como Código (IaC) en **Terraform** para aprovisionar una arquitectura de red segura, escalable y de alta disponibilidad en Amazon Web Services (AWS).

### Componentes Principales

* **Virtual Private Cloud (VPC)**: Bloque CIDR personalizado `192.168.0.0/16` que proporciona hasta 65.536 direcciones IP privadas, con resolución DNS habilitada (`enable_dns_hostnames` y `enable_dns_support`).

* **Internet Gateway (IGW)**: Conectado a la VPC para permitir comunicación bidireccional a internet para la subred pública.

* **Subred Pública (`192.168.1.0/24`)**: Configurada con `map_public_ip_on_launch = true` para asignar automáticamente direcciones IP públicas a los recursos que se lancen en ella.

* **Subred Privada (`192.168.2.0/24`)**: Subred totalmente aislada diseñada para microservicios privados, bases de datos o nodos de trabajo de Kubernetes.

* **NAT Gateway y Elastic IP (EIP)**: Desplegado dentro de la Subred Pública. Permite que los recursos de la Subred Privada inicien conexiones salientes bloqueando cualquier intento de conexión entrante no solicitada desde el exterior.

* **Tablas de Ruteo (*Route Tables*)**:

  * **Tabla de Ruteo Pública**: Redirige el tráfico genérico a internet (`0.0.0.0/0`) hacia el Internet Gateway.

  * **Tabla de Ruteo Privada**: Redirige el tráfico genérico a internet (`0.0.0.0/0`) hacia el NAT Gateway.

## 📁 Estructura de Archivos y Desglose Técnico

```
terraform/
├── main.tf         # Declaración principal de infraestructura (VPC, Subredes, Gateways, Rutas)
├── variables.tf    # Definición de variables de entrada y valores por defecto
├── outputs.tf      # Atributos exportados (VPC ID, NAT Gateway ID, etc.)
└── README.md       # Documentación técnica (este archivo)
```

### Patrones Técnicos Clave Utilizados

1. **Etiquetas Globales por Defecto (`default_tags`)**:

   * Configurado a nivel de proveedor (`Environment`, `ManagedBy = "Terraform"`, `Project`). Todo recurso creado hereda automáticamente estas etiquetas, garantizando gobernanza y facilitando el control de costes.

2. **Gestión Explícita de Dependencias (`depends_on`)**:

   * Utilizado en la Elastic IP y el NAT Gateway para evitar condiciones de carrera durante la creación, asegurando que el Internet Gateway esté totalmente creado antes de acoplar el NAT.

3. **Parametrización**:

   * Cero valores quemados en el código fuente. La región, nombres de entorno y rangos de red están desacoplados en `variables.tf`.

## 🚀 Guía de Despliegue y Operaciones

### Requisitos Previos

* [Terraform CLI](https://www.terraform.io/downloads) (>= 1.5.0) instalado localmente.

* Credenciales añadidas en las variables de entorno del sistema en windows
    - **Añadimos el usuario ID que nos aporta AWS creando una llave de acceso**: añadimos en la variable `AWS_ACCESS_KEY_ID` el valor
    - **Añadimos posteriormente la Region por defecto**: con `AWS_DEFAULT_REGION` y el valor `eu-west-1` especificamos cual es la región por defecto que sera modificada si se añadiera una linea en main.tf (jerarquia) 
    - **Añadimos la clave secreta de acceso**: finalmente con `AWS_SECRET_ACCESS_KEY` y el valor que nos de AWS tendremos configurada las credenciales para una cuenta de AWS sin tener que añadir las credenciales constantemente.

### Ciclo de Vida de Ejecución

#### 1. Inicializar el Directorio de Trabajo

Descarga los plugins del proveedor (AWS Provider `~> 5.0`) e inicializa el entorno local.

```bash
terraform init
```

#### 2. Validar la Sintaxis

Comprueba la validez sintáctica y que el código HCL esté bien estructurado.

```bash
terraform validate
```

#### 3. Simular el Plan de Ejecución

Genera una simulación en seco mostrando exactamente qué recursos se crearán o modificarán en AWS sin realizar cambios reales.

```bash
terraform plan
```

#### 4. Aplicar la Infraestructura

Aprovisiona físicamente los recursos en AWS tras confirmar escribiendo `yes`.

```bash
terraform apply
```

#### 5. Destrucción de Infraestructura (Optimización de Costes)

Elimina todos los recursos gestionados por esta configuración para evitar cargos innecesarios cuando el entorno no esté en uso.

```bash
terraform destroy
```