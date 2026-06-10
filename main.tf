# Configuracion principal del proyecto Casino Online
# Empresa: Promarketing Chile
# Region: ca-central-1 Canada

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Proveedor AWS apuntando a Canada
provider "aws" {
  region = var.region
}