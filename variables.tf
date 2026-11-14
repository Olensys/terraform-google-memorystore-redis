variable "name" {
  description = "Cluster name. Starts with a lowercase letter; lowercase letters, digits and hyphens; ends with a letter or digit; at most 63 characters."
  type        = string
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "name must match ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ (1 to 63 characters)."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "Project that hosts the cluster and its service connection policy."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region of the cluster and of the Private Service Connect subnet."
  type        = string
}

variable "network" {
  description = "Consumer network. name is the VPC network name and subnet_name the name of its Private Service Connect subnet (purpose PRIVATE_SERVICE_CONNECT) in var.region."
  type = object({
    name        = string
    subnet_name = string
  })
}

variable "shard_count" {
  description = "Number of shards in the cluster."
  type        = number
  default     = 1
  validation {
    condition     = var.shard_count >= 1 && floor(var.shard_count) == var.shard_count
    error_message = "shard_count must be a whole number >= 1."
  }
}

variable "replica_count" {
  description = "Replicas per shard (0, 1 or 2). Null resolves to 1 in prod and 0 elsewhere."
  type        = number
  default     = null
  validation {
    condition     = var.replica_count == null || contains([0, 1, 2], var.replica_count)
    error_message = "replica_count must be null, 0, 1 or 2."
  }
}

variable "node_type" {
  description = "Node type of every shard."
  type        = string
  default     = "REDIS_STANDARD_SMALL"
  validation {
    condition     = contains(["REDIS_SHARED_CORE_NANO", "REDIS_STANDARD_SMALL", "REDIS_HIGHMEM_MEDIUM", "REDIS_HIGHMEM_XLARGE"], var.node_type)
    error_message = "node_type must be one of REDIS_SHARED_CORE_NANO, REDIS_STANDARD_SMALL, REDIS_HIGHMEM_MEDIUM, REDIS_HIGHMEM_XLARGE."
  }
}

variable "auth_enabled" {
  description = "Enable IAM authentication (AUTH_MODE_IAM_AUTH). Redis Cluster uses IAM, not a password."
  type        = bool
  default     = true
}

variable "transit_encryption" {
  description = "Enable in-transit encryption (TLS with server authentication)."
  type        = bool
  default     = true
}

variable "service_connection_policy_name" {
  description = "Name of the Private Service Connect service connection policy. Null (the default) uses <name>-psc; set it to adopt an existing policy with a different name."
  type        = string
  default     = null
  validation {
    condition     = var.service_connection_policy_name == null ? true : can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.service_connection_policy_name))
    error_message = "service_connection_policy_name must match ^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$ (1 to 63 characters)."
  }
}

variable "maintenance_window" {
  description = "Weekly maintenance window: day of week (MONDAY to SUNDAY) and start hour (0 to 23, UTC) with an optional minute (0 to 59). The window itself is fixed at one hour by the service. Null (the default) means Sunday 02:00 UTC."
  type = object({
    day    = string
    hour   = number
    minute = optional(number, 0)
  })
  default = null
  validation {
    condition = var.maintenance_window == null ? true : (
      contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], var.maintenance_window.day)
      && var.maintenance_window.hour >= 0 && var.maintenance_window.hour <= 23
      && var.maintenance_window.minute >= 0 && var.maintenance_window.minute <= 59
    )
    error_message = "maintenance_window.day must be MONDAY to SUNDAY, hour 0 to 23 and minute 0 to 59."
  }
}

variable "persistence_mode" {
  description = "Persistence mode: PERSISTENCE_MODE_UNSPECIFIED, DISABLED, RDB or AOF. Null (the default) does not set persistence_config, leaving the service default. Snapshot period and fsync settings are left to the service (and kept as they are on an adopted cluster)."
  type        = string
  default     = null
  validation {
    condition     = var.persistence_mode == null ? true : contains(["PERSISTENCE_MODE_UNSPECIFIED", "DISABLED", "RDB", "AOF"], var.persistence_mode)
    error_message = "persistence_mode must be null or one of PERSISTENCE_MODE_UNSPECIFIED, DISABLED, RDB, AOF."
  }
}

variable "deletion_protection" {
  description = "Whether the cluster is protected from deletion. Null (the default) turns it on when context.environment is prod and off otherwise; true or false overrides that rule."
  type        = bool
  default     = null
  nullable    = true
}

variable "labels" {
  description = "Labels merged onto the cluster, applied last. Must already be normalised by the caller."
  type        = map(string)
  default     = {}
}
