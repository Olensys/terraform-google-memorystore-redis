locals {
  extra_labels = { for k, v in var.context.extra_tags :
  substr(replace(lower(k), "/[^a-z0-9_-]/", "-"), 0, 63) => substr(replace(lower(v), "/[^a-z0-9_-]/", "-"), 0, 63) }
  labels = merge(local.extra_labels, var.labels)

  is_prod = var.context.environment == "prod"

  replica_count = coalesce(var.replica_count, local.is_prod ? 1 : 0)

  # Null follows the environment rule (on in prod); true or false overrides it.
  deletion_protection = coalesce(var.deletion_protection, local.is_prod)

  authorization_mode      = var.auth_enabled ? "AUTH_MODE_IAM_AUTH" : "AUTH_MODE_DISABLED"
  transit_encryption_mode = var.transit_encryption ? "TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION" : "TRANSIT_ENCRYPTION_MODE_DISABLED"

  service_connection_policy_name = coalesce(var.service_connection_policy_name, "${var.name}-psc")

  service_connection_policies = {
    (local.service_connection_policy_name) = {
      network_name    = var.network.name
      network_project = var.project_id
      subnet_names    = [var.network.subnet_name]
    }
  }

  # Null keeps the documented default window: Sunday 02:00 UTC.
  maintenance_window = var.maintenance_window == null ? { day = "SUNDAY", hour = 2, minute = 0 } : var.maintenance_window

  weekly_maintenance_window = {
    day_of_the_week = local.maintenance_window.day
    hours           = tostring(local.maintenance_window.hour)
    minutes         = tostring(local.maintenance_window.minute)
    seconds         = "0"
    nanos           = 0
  }

  # Null leaves persistence unset so the API default applies (today's behaviour). The provider treats the
  # RDB/AOF sub-settings as computed, so an empty sub-object keeps whatever an adopted cluster already has.
  persistence_config = var.persistence_mode == null ? null : {
    mode       = var.persistence_mode
    rdb_config = var.persistence_mode == "RDB" ? {} : null
    aof_config = var.persistence_mode == "AOF" ? {} : null
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
  node_type     = var.node_type

  authorization_mode      = local.authorization_mode
  transit_encryption_mode = local.transit_encryption_mode

  zone_distribution_config_mode = "MULTI_ZONE"
  deletion_protection_enabled   = local.deletion_protection

  weekly_maintenance_window = local.weekly_maintenance_window
  persistence_config        = local.persistence_config

  service_connection_policies = local.service_connection_policies

  # The caller owns project API enablement.
  enable_apis = false

  labels = local.labels
}
