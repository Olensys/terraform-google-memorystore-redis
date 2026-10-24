# Changelog

## [1.2.0](https://github.com/Olensys/terraform-google-memorystore-redis/compare/v1.1.0...v1.2.0) (2026-10-24)


### Features

* expose node_type ([fc71b8e](https://github.com/Olensys/terraform-google-memorystore-redis/commit/fc71b8ef91c18dcd40db0f38fa215b4a4f7adf7f))


### Bug Fixes

* **examples:** use REDIS_SHARED_CORE_NANO ([2d62a5c](https://github.com/Olensys/terraform-google-memorystore-redis/commit/2d62a5caf38668a869bef1efcd6109302c368e32))
* run integration on change and weekly instead of nightly ([00da929](https://github.com/Olensys/terraform-google-memorystore-redis/commit/00da9292e26050929bd2b579c2c5dcffcd567777))

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
