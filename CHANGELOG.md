# Changelog

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, invalid characters to `-`, 63 characters); `labels` still win

### Tests

- `test_tags_contract` covers a mixed-case tag key and a value with a space

### Docs

- README usage shows the naming module

### Behaviour changes

- `context.extra_tags` entries now appear as normalised labels (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on unnormalised keys must read the normalised ones; values that previously failed GCP label validation now succeed.

## 1.0.1

### Fixes

- declare and mock google-beta required by the upstream module

## 1.0.0

- Memorystore for Redis Cluster wrapper over `terraform-google-modules/memorystore/google//modules/redis-cluster` 16.4.1: IAM auth and in-transit encryption on by default, a Private Service Connect connection policy, replicas and deletion protection in prod.
