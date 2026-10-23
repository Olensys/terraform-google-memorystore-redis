# terraform-google-memorystore-redis

Memorystore for Redis Cluster with AUTH and in-transit encryption, a Private Service Connect connection policy, and HA in prod

## Opinions

- IAM authentication (`AUTH_MODE_IAM_AUTH`) is on by default; Redis Cluster has no password. `auth_enabled = false` selects `AUTH_MODE_DISABLED`.
- In-transit encryption (`TRANSIT_ENCRYPTION_MODE_SERVER_AUTHENTICATION`) is on by default.
- One Private Service Connect service connection policy, `<name>-psc`, is created on `network.name` using `network.subnet_name`. That subnet must have purpose `PRIVATE_SERVICE_CONNECT`; `terraform-google-network` exposes its subnet names.
- HA in prod: `replica_count` defaults to 1 per shard when `context.environment` is `prod`, otherwise 0. Zones are always `MULTI_ZONE`.
- Deletion protection is on in prod only.
- Node type `REDIS_STANDARD_SMALL`; weekly maintenance window on Sunday 02:00 UTC.
- Project APIs (`redis`, `networkconnectivity`, `compute`, `serviceconsumermanagement`) are not enabled by this module; enable them in the project beforehand.
- Labels (`context.extra_tags` merged with `labels`, `labels` winning) are applied to the cluster resource; the upstream supports `labels` on the cluster in 16.4.1. They are not applied to the connection policy.

## Requirements note

The pinned upstream requires `google >= 7.15`, so this module declares `>= 7.15, < 8.0` instead of the library-wide floor.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-google-memorystore-redis.git?ref=v1.0.0"

  name       = "example"
  project_id = "my-project"
  region     = "us-central1"
  network = {
    name        = "my-network"
    subnet_name = "my-psc-subnet"
  }
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.15, < 8.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | terraform-google-modules/memorystore/google//modules/redis-cluster | 16.4.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Cluster name. Starts with a lowercase letter; lowercase letters, digits and hyphens; ends with a letter or digit; at most 63 characters. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Consumer network. name is the VPC network name and subnet\_name the name of its Private Service Connect subnet (purpose PRIVATE\_SERVICE\_CONNECT) in var.region. | <pre>object({<br/>    name        = string<br/>    subnet_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project that hosts the cluster and its service connection policy. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of the cluster and of the Private Service Connect subnet. | `string` | n/a | yes |
| <a name="input_auth_enabled"></a> [auth\_enabled](#input\_auth\_enabled) | Enable IAM authentication (AUTH\_MODE\_IAM\_AUTH). Redis Cluster uses IAM, not a password. | `bool` | `true` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto the cluster, applied last. Must already be normalised by the caller. | `map(string)` | `{}` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Replicas per shard (0, 1 or 2). Null resolves to 1 in prod and 0 elsewhere. | `number` | `null` | no |
| <a name="input_shard_count"></a> [shard\_count](#input\_shard\_count) | Number of shards in the cluster. | `number` | `1` | no |
| <a name="input_transit_encryption"></a> [transit\_encryption](#input\_transit\_encryption) | Enable in-transit encryption (TLS with server authentication). | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_discovery_endpoint"></a> [discovery\_endpoint](#output\_discovery\_endpoint) | Host address of the cluster discovery endpoint. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | Cluster ID (projects/<project>/locations/<region>/clusters/<name>). Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to the cluster, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Cluster name. Null when create is false. |
| <a name="output_port"></a> [port](#output\_port) | Port of the cluster discovery endpoint. Null when create is false. |
| <a name="output_replica_count_effective"></a> [replica\_count\_effective](#output\_replica\_count\_effective) | Replicas per shard after the environment default is applied. Null when create is false. |
| <a name="output_security_config"></a> [security\_config](#output\_security\_config) | Effective authorization\_mode and transit\_encryption\_mode. Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Relative resource path of the cluster. Null when create is false. |
| <a name="output_service_connection_policies"></a> [service\_connection\_policies](#output\_service\_connection\_policies) | Private Service Connect connection policies created for the cluster, keyed by policy name. Null when create is false. |
<!-- END_TF_DOCS -->
