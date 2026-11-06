# 🐳 Módulo de Contenedorización con Docker

Este directorio contiene el código fuente, la lógica de contenedorización y las especificaciones de despliegue para el microservicio de aplicación de nuestro pipeline DevOps End-to-End.

## 🏗️ Visión General de la Arquitectura

La estrategia de contenedorización sigue estándares de nivel de producción centrados en **superficie de ataque mínima**, **reproducibilidad** y **velocidad de compilación optimizada**.

```text
+-------------------------------------------------------------------+
|                     Host / Motor de Docker                        |
|                                                                   |
|   +-----------------------------------------------------------+   |
|   |                  Contenedor: mi-app-container             |   |
|   |                                                           |   |
|   |   +-------------------+       +-----------------------+   |   |
|   |   |  Node.js Express  |       | Usuario no-root       |   |   |
|   |   |    App (app.js)   |       | ('node') Aislamiento  |   |   |
|   |   +---------+---------+       +-----------------------+   |   |
|   |             |                                             |   |
|   |             v Escuchando en 0.0.0.0:3000                  |   |
|   +-------------+---------------------------------------------+   |
|                 ^                                                 |
|                 | Mapeo de Puertos (-p 3000:3000)                 |
|                 v                                                 |
|          Puerto Host 3000 (http://localhost:3000)                  |
+-------------------------------------------------------------------+
```

### Aspectos Clave de la Arquitectura

1. **Construcción Multietapa (Multi-Stage Build)**:
   * **Etapa 1 (Builder)**: Descarga e instala las dependencias de producción (`npm install`).
   * **Etapa 2 (Runtime)**: Copia únicamente los módulos compilados y archivos necesarios desde la etapa de compilación, eliminando herramientas innecesarias para mantener el artefacto final ligero y seguro.

2. **Imagen Base Minimalista (`node:20-alpine`)**:
   * Reduce el tamaño final de la imagen.
   * Minimiza vulnerabilidades de seguridad.

3. **Principio de Mínimo Privilegio (`USER node`)**:
   * Elimina los privilegios de `root` dentro del contenedor, evitando que un posible ataque escale accesos al servidor anfitrión.

4. **Optimización de Caché de Capas (Layer Caching)**:
   * El manifiesto de dependencias (`package.json`) se copia antes de los archivos de código fuente de la aplicación, garantizando que las dependencias se mantengan en caché a menos que cambien explícitamente.

---

## 📁 Estructura de Archivos y Desglose Técnico

```text
docker/
├── app.js             # Lógica del servidor web con Node.js y Express
├── package.json       # Manifiesto del proyecto y definición de dependencias
├── Dockerfile         # Instrucciones de construcción multietapa del contenedor
└── README.md          # Documentación técnica (este archivo)
```

### 1. `app.js`
* **Framework**: Express.js
* **Vinculación (Binding)**: Se vincula a `0.0.0.0` para escuchar en todas las interfaces de red del contenedor (esencial para que la red de Docker acepte peticiones desde el exterior del contenedor).
* **Gestión de Entorno**: Lee dinámicamente `process.env.PORT` con fallback al puerto `3000`.

### 2. Análisis Interno del `Dockerfile`

```dockerfile
# Etapa 1: Instalación de dependencias
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json ./
RUN npm install

# Etapa 2: Imagen final de producción
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER node
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 🚀 Guía de Ejecución y Despliegue

### Requisitos Previos
* Docker Engine / Docker Desktop instalado y en ejecución.
* Puerto `3000` libre en la máquina local.

### Paso 1: Construir la Imagen
Ejecuta el comando de compilación desde la carpeta `docker/`:

```bash
docker build -t devops-test-app:latest .
```

### Paso 2: Ejecutar el Contenedor
Arranca el contenedor en segundo plano (modo *detached*) especificando el mapeo de puertos:

```bash
docker run -d -p 3000:3000 --name mi-app-container devops-test-app:latest
```

### Paso 3: Verificar el Estado del Contenedor
* **Endpoint HTTP**: Accede a `http://localhost:3000` mediante el navegador web o la terminal:
  ```bash
  curl http://localhost:3000
  ```
* **Estado y Logs**:
  ```bash
  docker ps
  docker logs mi-app-container
  ```

### Paso 4: Limpieza del Ciclo de Vida
Para detener y borrar el contenedor de forma limpia:

```bash
docker stop mi-app-container
docker rm mi-app-container
```

*O bien, forzar la eliminación en un único paso:*

```bash
docker rm -f mi-app-container
```

---

## 🛠️ Solución de Problemas y Defensa Técnica.

Esta sección documenta errores reales encontrados durante el desarrollo y su resolución.

### Problema 1: Fallo de Conexión a la API del Motor de Docker

* **Síntoma**: `ERROR: failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine...`
* **Causa:**: Se intento comunicar con el daemon de Docker antes de que el motor de Docker Desktop terminara de inicializarse en el sistema.
* **Resolución**:
  1. Se inició Docker Desktop y se esperó a la confirmación de estado activo (icono verde).
  2. Se volvió a ejecutar `docker build` una vez abierto el socket de comunicación.

### Problema 2: Error de Sintaxis por Falta de Argumento en `docker build`

* **Síntoma**: `ERROR: 'docker buildx build' requires 1 argument`
* **Causa:**: Se omitió el punto (`.`) indicativo del contexto de construcción al final del comando.
* **Resolución**: Docker requiere especificar explícitamente la ruta del contexto (`.`) que contiene los archivos que serán enviados al daemon para la compilación.