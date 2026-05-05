# SmplkitGeneratedClient::Config::Config

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **description** | **String** |  | [optional] |
| **parent** | **String** |  | [optional] |
| **items** | [**Hash&lt;String, ConfigItemDefinition&gt;**](ConfigItemDefinition.md) |  | [optional] |
| **environments** | [**Hash&lt;String, EnvironmentOverride&gt;**](EnvironmentOverride.md) |  | [optional] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |

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

