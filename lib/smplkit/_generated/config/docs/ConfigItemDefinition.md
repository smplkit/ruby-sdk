# SmplkitGeneratedClient::Config::ConfigItemDefinition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **value** | **Object** |  | [optional] |
| **type** | **String** | Declared value type. Constrains the JSON shape of &#x60;value&#x60; and of every override of this key in the &#x60;environments&#x60; map. | [optional] |
| **description** | **String** | Optional human-readable explanation of what this item controls. | [optional] |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::ConfigItemDefinition.new(
  value: null,
  type: null,
  description: null
)
```

