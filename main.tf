locals {
  labels = merge(var.context.extra_tags, var.labels)

  is_prod = var.context.environment == "prod"

  replica_count = coalesce(var.replica_count, local.is_prod ? 1 : 0)

  authorization_mode      = var.auth_enabled ? "AUTH_MODE_IAM_AUTH" : "AUTH_MODE_DISABLED"
  transit_encryption_mode = var.transit_encryption ? "TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION" : "TRANSIT_ENCRYPTION_MODE_DISABLED"

  service_connection_policies = {
    "${var.name}-psc" = {
      network_name    = var.network.name
      network_project = var.project_id
      subnet_names    = [var.network.subnet_name]
    }
  }
}

module "this" {
  source  = "terraform-google-modules/memorystore/google//modules/redis-cluster"
  version = "16.4.1"

  count = var.create ? 1 : 0

  project_id = var.project_id
  name       = var.name
  region     = var.region
  network    = ["projects/${var.project_id}/global/networks/${var.network.name}"]

  shard_count   = var.shard_count
  replica_count = local.replica_count
  node_type     = "REDIS_STANDARD_SMALL"

  authorization_mode      = local.authorization_mode
  transit_encryption_mode = local.transit_encryption_mode

  zone_distribution_config_mode = "MULTI_ZONE"
  deletion_protection_enabled   = local.is_prod

  weekly_maintenance_window = {
    day_of_the_week = "SUNDAY"
    hours           = "2"
    minutes         = "0"
    seconds         = "0"
    nanos           = 0
  }

  service_connection_policies = local.service_connection_policies

  # The caller owns project API enablement.
  enable_apis = false

  labels = local.labels
}
