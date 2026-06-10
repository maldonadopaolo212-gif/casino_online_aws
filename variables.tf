# Variables del proyecto Casino Online

# Region donde se despliega toda la infraestructura
variable "region" {
  description = "Region AWS"
  type        = string
  default     = "ca-central-1"
}

# Nombre del proyecto para usar en nomenclatura de recursos
variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
  default     = "casino"
}

# Nombre de la operacion para nomenclatura
variable "operacion" {
  description = "Nombre de la operacion"
  type        = string
  default     = "promarketing"
}

# Ambiente de despliegue
variable "ambiente" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "prod"
}

# Tipo de instancia EC2 para los servidores de aplicacion
variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.medium"
}

# CIDR de la VPC principal donde viven las aplicaciones
variable "vpc_principal_cidr" {
  description = "CIDR block VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

# CIDR de la VPC secundaria donde vive la bodega de datos
variable "vpc_secundaria_cidr" {
  description = "CIDR block VPC secundaria"
  type        = string
  default     = "10.1.0.0/16"
}