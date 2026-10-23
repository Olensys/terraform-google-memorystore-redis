terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.15, < 8.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.15, < 8.0"
    }
  }
}

variable "project_id" {
  description = "Project that hosts the cluster."
  type        = string
}

variable "network_name" {
  description = "Name of an existing VPC network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the Private Service Connect subnet (purpose PRIVATE_SERVICE_CONNECT) in the region."
  type        = string
}

module "this" {
  source = "../../"

  name       = "example"
  project_id = var.project_id
  region     = "us-central1"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  network = {
    name        = var.network_name
    subnet_name = var.subnet_name
  }
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = module.this.name
}
