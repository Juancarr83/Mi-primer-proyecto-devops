🏗️ Documentación del Módulo de Infraestructura (AWS & Terraform)
1. Arquitectura de Red Implementada
El diseño de la red sigue las mejores prácticas de seguridad de AWS (Well-Architected Framework), aislando los recursos según su exposición al tráfico de internet mediante una VPC (Virtual Private Cloud) segmentada.

VPC Principal (10.0.0.0/16): Rango de red global que proporciona hasta 65.536 direcciones IP privadas, con soporte de nombres de dominio y hostnames de DNS habilitados.

Internet Gateway (IGW): Componente acoplado a la VPC que actúa como la pasarela lógica hacia el mundo exterior, permitiendo el flujo de tráfico bidireccional entre la red y internet.

Subred Pública (10.0.1.0/24):

Configurada con map_public_ip_on_launch = true para asignar automáticamente direcciones IP públicas a los recursos que se inicien en ella.

Alberga los componentes de entrada/salida como el NAT Gateway.

Subred Privada (10.0.2.0/24):

Subred completamente aislada donde residirán las bases de datos o servicios backend que no deben ser accesibles directamente desde internet.

NAT Gateway y Elastic IP (EIP):

Se ubica en la subred pública y utiliza una IP fija (Elastic IP). Su propósito es permitir que los servidores de la subred privada puedan salir a internet (por ejemplo, para descargar parches o dependencias de contenedores) de forma saliente, pero bloqueando cualquier intento de conexión entrante originada desde el exterior.

Tablas de Ruteo (Route Tables):

Tabla Pública: Asocia la subred pública y enruta todo el tráfico genérico (0.0.0.0/0) directamente hacia el Internet Gateway.

Tabla Privada: Asocia la subred privada y redirige el tráfico exterior (0.0.0.0/0) hacia el NAT Gateway.

📁 2. Desglose Estructural del Código Terraform
El proyecto se estructura de forma modular y limpia en tres archivos clave dentro de la carpeta terraform/:

A. variables.tf (Parametrización)
Evita valores quemados (hardcoded), permitiendo reutilizar el código en distintas regiones o entornos mediante la definición estricta de tipos (type = string) y valores por defecto.

B. main.tf (Core de Infraestructura)
Bloque terraform y provider: Fija la versión mínima de Terraform (ej. >= 1.5.0) y la versión del proveedor de AWS (~> 5.0).

default_tags globales: Una buena práctica de nivel senior que inyecta automáticamente etiquetas (como el entorno, el nombre del proyecto y la autoría de Terraform) a todos los recursos creados, facilitando enormemente la auditoría y el control de costes (FinOps).

Recursos declarativos: Creación secuencial de aws_vpc, aws_internet_gateway, subredes, aws_eip, aws_nat_gateway y las respectivas tablas de ruteo junto con sus asociaciones (aws_route_table_association).

C. outputs.tf (Exposición de Datos)
Extrae los identificadores únicos asignados por AWS (como el vpc_id y el nat_gateway_id) para facilitar su integración con futuras capas del proyecto (como clústeres de Kubernetes o despliegues de aplicaciones).

🚀 3. Ciclo de Vida y Pasos para el Despliegue
Para desplegar esta infraestructura de forma controlada y profesional, se sigue estrictamente el flujo operativo de IaC (Infrastructure as Code):

Inicialización del entorno (terraform init):

Descarga y configura los plugins y dependencias del proveedor de AWS requeridos en el directorio de trabajo local.

Validación estática (terraform validate):

Comprueba que la sintaxis del lenguaje HCL sea correcta antes de interactuar con la nube.

Planificación de cambios (terraform plan):

Genera un informe detallado comparando el estado actual de la infraestructura en AWS con el código escrito, mostrando mediante marcas verdes (+) los recursos que van a ser aprovisionados.

Aplicación del estado (terraform apply):

Ejecuta las llamadas a la API de AWS para construir físicamente la red.

Destrucción controlada (terraform destroy):

Dado que este entorno es de aprendizaje o pruebas, se ejecuta este comando para limpiar y eliminar por completo todos los recursos en la nube (especialmente el NAT Gateway, que genera costes fijos por hora), garantizando una gestión eficiente de los recursos.

🛠️ 4. Resolución de Incidencias y Decisiones de Diseño (Enfoque de Entrevista)
Durante la implementación de este tipo de infraestructuras en entornos reales o de pruebas, es común enfrentarse a retos técnicos que demuestran capacidad de resolución:

Gestión de dependencias de red (Race Conditions):

Problema potencial: Si Terraform intenta crear el NAT Gateway antes de que el Internet Gateway esté completamente operativo y vinculado a la VPC, la API de AWS devolverá un error de dependencia.

Solución aplicada: Se incorporó explícitamente el parámetro depends_on = [aws_internet_gateway.gw] tanto en la Elastic IP como en el NAT Gateway, asegurando que Terraform respete el orden lógico de creación de los componentes de red.

Despliegue Incremental:

Se adoptó la estrategia de construir primero la base troncal (VPC, subredes básicas) y verificar su correcto funcionamiento con un apply, para posteriormente añadir la capa avanzada de ruteo y NAT Gateway. Esto permite aislar errores rápidamente en lugar de intentar desplegar toda la topología de golpe.

Optimización de Costes (Cloud FinOps):

Se comprende y justifica el uso de terraform destroy para evitar cargos innecesarios asociados a componentes de infraestructura persistentes como los NAT Gateways, manteniendo la capacidad de reproducir todo el entorno de forma automatizada e idéntica en cuestión de minutos.