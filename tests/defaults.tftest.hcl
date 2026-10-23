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
    condition     = output.id == null && output.name == null && output.self_link == null && output.discovery_endpoint == null && output.port == null && output.labels == null && output.security_config == null && output.service_connection_policies == null && output.replica_count_effective == null
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
      extra_tags   = { owner = "y", team = "z" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "z"
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
