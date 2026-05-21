# SmplkitGeneratedClient::Config::UsageAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **limit_key** | **String** | Identifier of the metered limit, e.g. &#x60;config.managed_configurations&#x60; or &#x60;config.inheritance_depth&#x60;. |  |
| **period** | **String** | Period the counter covers. &#x60;current&#x60; is the only supported value. |  |
| **value** | **Integer** | Count for the period. |  |

## Example

```ruby
require 'smplkit_config_client'

instance = SmplkitGeneratedClient::Config::UsageAttributes.new(
  limit_key: null,
  period: null,
  value: null
)
```

