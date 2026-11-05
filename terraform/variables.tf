variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "Región de AWS donde se desplegará la infraestructura de red."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Entorno del proyecto (ej: dev, prod)."
}

variable "project_name" {
  type        = string
  default     = "devops-project"
  description = "Nombre base para etiquetar y organizar los recursos."
}