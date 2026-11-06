# Módulo de Kubernetes: Despliegue, Exposición y Alta Disponibilidad

Está diseñado utilizando las mejores prácticas de arquitectura *Cloud Native*, incluyendo alta disponibilidad, balanceo de carga, límites de recursos y supervisión activa del estado de salud de la aplicación.

---

## 🛠️ Arquitectura y Objetos Definidos

El módulo de Kubernetes se compone de dos manifiestos principales escritos en YAML:

### 1. `deployment.yaml` (Carga de Trabajo / Workload)
Gestiona la ejecución y actualización declarativa de la aplicación de forma sin estado (*stateless*).
* **Alta Disponibilidad:** Configurado con **2 réplicas** idénticas distribuidas dentro del clúster. Si un contenedor o nodo falla, Kubernetes levanta automáticamente un nuevo pod para mantener la capacidad declarada.
* **Política de Imagen:** `imagePullPolicy: IfNotPresent`, ideal para desarrollo y validación local con entornos como `kind` o `minikube`.
* **Gestión de Recursos (`requests` / `limits`):**
  * `requests`: Recursos mínimos garantizados por pod.
  * `limits`: Techo máximo de uso para evitar sobreconsumos de memoria (*OOMKilled*) que puedan comprometer el nodo.
* **Sondas de Salud:**
  * `readinessProbe`: Determina cuándo el contenedor ha arrancado y está listo para recibir tráfico.
  * `livenessProbe`: Comprueba periódicamente si la aplicación está sana. Si detecta fallos continuos, reinicia el contenedor de manera automática.

### 2. `service.yaml`
Proporciona una capa de abstracción con una dirección IP y un nombre de DNS estables dentro del clúster.
* **Tipo de Servicio:** `NodePort` (Puerto estático expuesto en el nodo: `30080`).
* **Mapeo de Puertos:**
  * `port: 80` -> Puerto interno expuesto en el servicio dentro del clúster.
  * `targetPort: 3000` -> Puerto nativo donde escucha la aplicación dentro del contenedor.
  * `nodePort: 30080` -> Puerto público asignado a nivel de nodo.
* **Balanceo de Carga:** Utiliza un *Selector* basado en la etiqueta `app: devops-test-app` para distribuir el tráfico equitativamente entre las 2 réplicas del Deployment.

---

## 🚀 Guía de Despliegue y Ejecución

### Requisitos Previos
* Tener un clúster local activo (por ejemplo, **`kind`** o **Docker Desktop** con soporte de Kubernetes).
* Tener la CLI `kubectl` instalada y conectada al contexto correcto.
* Haber construido la imagen localmente en docker(`devops-test-app:latest`).

### 1. Aplicar los manifiestos al clúster

Ejecuta los siguientes comandos desde la raíz del repositorio:

```bash
# Aplicar el Deployment (Pods y Réplicas)
kubectl apply -f kubernetes/deployment.yaml

# Aplicar el Servicio (Red y Exposición)
kubectl apply -f kubernetes/service.yaml
```

### 2. Verificación del estado de los recursos

```bash
# Verificar los Pods en ejecución
kubectl get pods

# Verificar el Deployment y sus réplicas activas
kubectl get deployments

# Verificar el Servicio y sus puertos
kubectl get services
```

---

## 🔌 Diagnóstico y Acceso Local (`port-forward`)

En entornos locales aislados (como Docker Desktop con Windows o `kind`), el tráfico directo hacia el `NodePort` puede requerir la creación de un túnel de red directo desde el host.

Para exponer el servicio hacia la máquina local sin depender del nombre individual de los Pods (incluso si estos se reinician o reemplazan), se utiliza la redirección hacia el **Servicio**:

```bash
kubectl port-forward service/devops-test-app-service 3000:80
```

> **Nota de uso:** Este comando mantiene la conexión abierta en primer plano. Accede desde tu navegador a:
> **`http://localhost:3000`** Hay que abrir una nueva terminal para seguir trabajando con el tunel creado en segundo plano.

---

## 🧹 Comandos de Limpieza

Para eliminar todos los recursos creados en Kubernetes y dejar el clúster limpio:

```bash
kubectl delete -f kubernetes/service.yaml
kubectl delete -f kubernetes/deployment.yaml
```