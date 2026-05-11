# SmplkitGeneratedClient::Config::EnvironmentOverride

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **values** | [**Hash&lt;String, ConfigItemOverride&gt;**](ConfigItemOverride.md) | Map of item keys to override values that apply when this environment is resolved. Each key must already be declared (with a type) on this config or one of its ancestors. | [optional] |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::EnvironmentOverride.new(
  values: null
)
```

