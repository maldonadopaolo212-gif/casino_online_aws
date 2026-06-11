variable "region" {
  default = "ca-central-1"
}

variable "proyecto" {
  default = "casino"
}

variable "operacion" {
  default = "promarketing"
}

variable "ambiente" {
  default = "prod"
}

variable "instance_type" {
  default = "t3.medium"
}

# CIDRs de las dos VPCs
variable "vpc_principal_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_secundaria_cidr" {
  default = "10.1.0.0/16"
}