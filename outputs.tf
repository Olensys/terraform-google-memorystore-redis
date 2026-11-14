output "id" {
  description = "Cluster ID (projects/<project>/locations/<region>/clusters/<name>). Null when create is false."
  value       = var.create ? module.this[0].id : null
}

output "name" {
  description = "Cluster name. Null when create is false."
  value       = var.create ? var.name : null
}

output "self_link" {
  description = "Relative resource path of the cluster. Null when create is false."
  value       = var.create ? module.this[0].id : null
}

output "discovery_endpoint" {
  description = "Host address of the cluster discovery endpoint. Null when create is false."
  value       = var.create ? try(module.this[0].discovery_endpoints[0].address, null) : null
}

output "port" {
  description = "Port of the cluster discovery endpoint. Null when create is false."
  value       = var.create ? try(module.this[0].discovery_endpoints[0].port, null) : null
}

output "labels" {
  description = "Labels applied to the cluster, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}

output "security_config" {
  description = "Effective authorization_mode and transit_encryption_mode. Null when create is false."
  value = var.create ? {
    authorization_mode      = local.authorization_mode
    transit_encryption_mode = local.transit_encryption_mode
  } : null
}

output "service_connection_policies" {
  description = "Private Service Connect connection policies created for the cluster, keyed by policy name. Null when create is false."
  value       = var.create ? local.service_connection_policies : null
}

output "replica_count_effective" {
  description = "Replicas per shard after the environment default is applied. Null when create is false."
  value       = var.create ? local.replica_count : null
}

output "node_type" {
  description = "Node type applied to the cluster. Null when create is false."
  value       = var.create ? var.node_type : null
}

output "deletion_protection" {
  description = "Whether the cluster is protected from deletion (on in prod unless deletion_protection overrides it). Null when create is false."
  value       = var.create ? local.deletion_protection : null
}

output "maintenance_window" {
  description = "Weekly maintenance window passed to the upstream module. Null when create is false."
  value       = var.create ? local.weekly_maintenance_window : null
}

output "persistence_config" {
  description = "persistence_config passed to the upstream module; null when persistence_mode is null or create is false."
  value       = var.create ? local.persistence_config : null
}
