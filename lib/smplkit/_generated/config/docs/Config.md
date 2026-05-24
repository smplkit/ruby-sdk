# SmplkitGeneratedClient::Config::Config

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the config. |  |
| **description** | **String** | Optional human-readable description of what this config holds. | [optional] |
| **parent** | **String** | Key of another config to inherit items from. Inherited items appear as if declared on this config; locally declared items with the same key shadow them. Omit or set to &#x60;null&#x60; for a standalone config with no parent. | [optional] |
| **items** | [**Hash&lt;String, ConfigItemDefinition&gt;**](ConfigItemDefinition.md) | Map of item keys to item definitions declared on this config. Keys must be unique within the config; declared types are immutable once set and must match any type declared for the same key on an ancestor. | [optional] |
| **environments** | **Hash&lt;String, Hash&lt;String, Object&gt;&gt;** | Map of environment keys to per-environment overrides. Each environment maps to a flat object of item key to override value (e.g. &#x60;{\&quot;production\&quot;: {\&quot;database.host\&quot;: \&quot;db-prod.internal\&quot;}}&#x60;). Only the keys being overridden need to be present. Override values must conform to the item&#39;s declared &#x60;type&#x60;; &#x60;type&#x60; and &#x60;description&#x60; are always resolved from the defining configuration and are never redeclared on an override. | [optional] |
| **managed** | **Boolean** | Whether this config is admin-managed (&#x60;true&#x60;) or auto-discovered by an SDK and not yet claimed (&#x60;false&#x60;). Configs created through the console or &#x60;POST /api/v1/configs&#x60; are always managed. Configs registered via &#x60;POST /api/v1/configs/bulk&#x60; land unmanaged. Setting this field to &#x60;true&#x60; on a PUT promotes a discovered config to managed, which consumes a slot of the &#x60;config.managed_configurations&#x60; entitlement. | [optional] |
| **created_at** | **Time** | When the config was created. | [optional][readonly] |
| **updated_at** | **Time** | When the config was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::Config.new(
  name: null,
  description: null,
  parent: null,
  items: null,
  environments: null,
  managed: null,
  created_at: null,
  updated_at: null
)
```

