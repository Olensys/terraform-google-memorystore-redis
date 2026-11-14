mock_provider "google-beta" {}

mock_provider "google" {
  mock_resource "google_redis_cluster" {
    defaults = {
      id = "projects/example-project/locations/us-central1/clusters/example"
      discovery_endpoints = [
        { address = "10.0.0.2", port = 6379, psc_config = [{ network = "projects/example-project/global/networks/example-net" }] }
      ]
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name       = "example"
  project_id = "example-project"
  region     = "us-central1"
  network = {
    name        = "example-net"
    subnet_name = "example-psc"
  }
}

run "test_auth_and_tls_on" {
  command = plan

  assert {
    condition     = output.security_config.authorization_mode == "AUTH_MODE_IAM_AUTH"
    error_message = "IAM auth must be on by default."
  }

  assert {
    condition     = output.security_config.transit_encryption_mode == "TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION"
    error_message = "In-transit encryption must be on by default."
  }
}

run "test_auth_and_tls_off" {
  command = plan

  variables {
    auth_enabled       = false
    transit_encryption = false
  }

  assert {
    condition     = output.security_config.authorization_mode == "AUTH_MODE_DISABLED" && output.security_config.transit_encryption_mode == "TRANSIT_ENCRYPTION_MODE_DISABLED"
    error_message = "Disabling auth and transit encryption must map to the DISABLED modes."
  }
}

run "test_connection_policy_created" {
  command = plan

  assert {
    condition     = output.service_connection_policies["example-psc"].network_name == "example-net" && output.service_connection_policies["example-psc"].network_project == "example-project" && output.service_connection_policies["example-psc"].subnet_names[0] == "example-psc"
    error_message = "One PSC connection policy named <name>-psc must target the given network and subnet."
  }
}

run "test_connection_policy_name_override" {
  command = plan

  variables {
    service_connection_policy_name = "legacy-policy"
  }

  assert {
    condition     = output.service_connection_policies["legacy-policy"].network_name == "example-net" && !contains(keys(output.service_connection_policies), "example-psc")
    error_message = "service_connection_policy_name must replace <name>-psc as the policy name."
  }
}

run "test_connection_policy_name_validation" {
  command = plan

  variables {
    service_connection_policy_name = "Bad_Name"
  }

  expect_failures = [var.service_connection_policy_name]
}

run "test_maintenance_window_default" {
  command = plan

  assert {
    condition = (
      output.maintenance_window.day_of_the_week == "SUNDAY"
      && output.maintenance_window.hours == "2"
      && output.maintenance_window.minutes == "0"
      && output.maintenance_window.seconds == "0"
      && output.maintenance_window.nanos == 0
    )
    error_message = "Default maintenance window is Sunday 02:00 UTC."
  }
}

run "test_maintenance_window_override" {
  command = plan

  variables {
    maintenance_window = { day = "TUESDAY", hour = 23, minute = 30 }
  }

  assert {
    condition     = output.maintenance_window.day_of_the_week == "TUESDAY" && output.maintenance_window.hours == "23" && output.maintenance_window.minutes == "30"
    error_message = "maintenance_window must be passed through as day name and string hours/minutes."
  }
}

run "test_maintenance_window_validation" {
  command = plan

  variables {
    maintenance_window = { day = "SUNDAY", hour = 24 }
  }

  expect_failures = [var.maintenance_window]
}

run "test_persistence_unset_by_default" {
  command = plan

  assert {
    condition     = output.persistence_config == null
    error_message = "persistence_config must not be set unless persistence_mode is given."
  }
}

run "test_persistence_rdb" {
  command = plan

  variables {
    persistence_mode = "RDB"
  }

  assert {
    condition     = output.persistence_config.mode == "RDB" && output.persistence_config.rdb_config != null && output.persistence_config.aof_config == null
    error_message = "RDB mode must pass mode RDB with an rdb_config sub-object and no aof_config."
  }
}

run "test_persistence_aof" {
  command = plan

  variables {
    persistence_mode = "AOF"
  }

  assert {
    condition     = output.persistence_config.mode == "AOF" && output.persistence_config.aof_config != null && output.persistence_config.rdb_config == null
    error_message = "AOF mode must pass mode AOF with an aof_config sub-object and no rdb_config."
  }
}

run "test_persistence_disabled" {
  command = plan

  variables {
    persistence_mode = "DISABLED"
  }

  assert {
    condition     = output.persistence_config.mode == "DISABLED" && output.persistence_config.rdb_config == null && output.persistence_config.aof_config == null
    error_message = "DISABLED must pass mode only."
  }
}

run "test_persistence_mode_validation" {
  command = plan

  variables {
    persistence_mode = "SNAPSHOT"
  }

  expect_failures = [var.persistence_mode]
}

run "test_deletion_protection_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.deletion_protection == true
    error_message = "Deletion protection must be on in prod."
  }
}

run "test_deletion_protection_off_outside_prod" {
  command = plan

  assert {
    condition     = output.deletion_protection == false
    error_message = "Deletion protection must be off outside prod."
  }
}

run "test_deletion_protection_override_on_outside_prod" {
  command = plan

  variables {
    deletion_protection = true
  }

  assert {
    condition     = output.deletion_protection == true
    error_message = "deletion_protection = true must override the environment rule."
  }
}

run "test_deletion_protection_override_off_in_prod" {
  command = plan

  variables {
    deletion_protection = false
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.deletion_protection == false
    error_message = "deletion_protection = false must override the environment rule."
  }
}

run "test_replica_default_in_prod" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.replica_count_effective == 1
    error_message = "replica_count must default to 1 in prod."
  }
}

run "test_replica_default_off_in_dev" {
  command = plan

  variables {
    context = {
      organization = "olensys"
      environment  = "dev"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.replica_count_effective == 0
    error_message = "replica_count must default to 0 outside prod."
  }
}

run "test_replica_override_wins" {
  command = plan

  variables {
    replica_count = 2
  }

  assert {
    condition     = output.replica_count_effective == 2
    error_message = "Explicit replica_count must win over the environment default."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null && output.name == null && output.self_link == null && output.discovery_endpoint == null && output.port == null && output.labels == null && output.security_config == null && output.service_connection_policies == null && output.replica_count_effective == null && output.node_type == null && output.deletion_protection == null && output.maintenance_window == null && output.persistence_config == null
    error_message = "Every output must be null when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "Core Team" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "core-team"
    error_message = "context.extra_tags must be merged."
  }
}

run "test_shard_count_validation" {
  command = plan

  variables {
    shard_count = 0
  }

  expect_failures = [var.shard_count]
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "a-name-that-is-far-too-long-for-a-memorystore-cluster-id-limit-of-63"
  }

  expect_failures = [var.name]
}

run "test_name_format_validation" {
  command = plan

  variables {
    name = "1bad-"
  }

  expect_failures = [var.name]
}

run "test_node_type_default" {
  command = plan

  assert {
    condition     = output.node_type == "REDIS_STANDARD_SMALL"
    error_message = "node_type must default to REDIS_STANDARD_SMALL."
  }
}

run "test_node_type_validation" {
  command = plan

  variables {
    node_type = "REDIS_LARGE"
  }

  expect_failures = [var.node_type]
}
