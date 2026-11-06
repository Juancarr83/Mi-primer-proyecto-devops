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
   * Reduce el tamaño final de la imagen (~100 MB frente a ~1 GB de las imágenes estándar de Node).
   * Minimiza vulnerabilidades de seguridad (CVEs) al eliminar binarios innecesarios del sistema operativo.

3. **Principio de Mínimo Privilegio (`USER node`)**:
   * Elimina los privilegios de `root` dentro del contenedor, evitando que un posible ataque con escape de contenedor escale accesos al servidor anfitrión.

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
* **Gestión de Entorno**: Lee dinámicamente `process.env.PORT` con fallback al puerto `3000` (siguiendo la metodología *12-Factor App*).

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

## 🛠️ Solución de Problemas y Defensa Técnica (Guía para Entrevistas)

Esta sección documenta errores reales encontrados durante el desarrollo y su resolución, demostrando capacidad diagnóstica profesional ante evaluadores técnicos.

### Problema 1: Fallo de Conexión a la API del Motor de Docker

* **Síntoma**: `ERROR: failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine...`
* **Causa Raíz**: El cliente CLI intentó comunicarse con el daemon de Docker antes de que el motor de Docker Desktop terminara de inicializarse en el sistema.
* **Resolución**:
  1. Se verificó el estado del motor en la barra de tareas del sistema operativo.
  2. Se inició Docker Desktop y se esperó a la confirmación de estado activo (icono verde).
  3. Se volvió a ejecutar `docker build` una vez abierto el socket de comunicación.

### Problema 2: Error de Sintaxis por Falta de Argumento en `docker build`

* **Síntoma**: `ERROR: 'docker buildx build' requires 1 argument`
* **Causa Raíz**: Se omitió el punto (`.`) indicativo del contexto de construcción al final del comando.
* **Conclusión Técnica**: Docker requiere especificar explícitamente la ruta del contexto (`.`) que contiene los archivos que serán enviados al daemon para la compilación.

---

## 💡 Preguntas y Respuestas Clave para Entrevistas Técnicas

| Pregunta | Respuesta de Ingeniería |
| :--- | :--- |
| **¿Por qué vincular el servidor a `0.0.0.0` y no a `127.0.0.1` dentro de `app.js`?** | Vincular a `127.0.0.1` restringe el tráfico a la interfaz interna de *loopback* del propio contenedor. `0.0.0.0` permite escuchar en todas las interfaces de red del contenedor, posibilitando que los puentes de red de Docker y los reenvíos de puertos del host alcancen el proceso. |
| **¿Por qué se separa la copia de `package.json` de la del resto del código fuente en el `Dockerfile`?** | Docker guarda en caché las capas secuencialmente. Copiar `package.json` y ejecutar `npm install` antes del código fuente evita invalidar la capa de dependencias si solo cambia `app.js`, reduciendo el tiempo de compilación de minutos a segundos. |
| **¿Qué riesgo de seguridad implica ejecutar el contenedor como `root`?** | Si la aplicación sufre una vulnerabilidad de ejecución remota de código, ser `root` facilita ataques de escape de contenedor o acceso a recursos del kernel del anfitrión. Usar `USER node` restringe estrictamente los privilegios del proceso. |