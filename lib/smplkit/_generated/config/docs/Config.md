# SmplkitGeneratedClient::Config::Config

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the config. |  |
| **description** | **String** | Optional human-readable description of what this config holds. | [optional] |
| **parent** | **String** | Key of another config to inherit items from. Inherited items appear as if declared on this config; locally declared items with the same key shadow them. Omit or set to &#x60;null&#x60; for a standalone config with no parent. | [optional] |
| **items** | [**Hash&lt;String, ConfigItemDefinition&gt;**](ConfigItemDefinition.md) | Map of item keys to item definitions declared on this config. Keys must be unique within the config; declared types are immutable once set and must match any type declared for the same key on an ancestor. | [optional] |
| **environments** | [**Hash&lt;String, EnvironmentOverride&gt;**](EnvironmentOverride.md) | Map of environment keys to per-environment override sets. An environment override applies when this config is resolved against that environment. | [optional] |
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
  created_at: null,
  updated_at: null
)
```

