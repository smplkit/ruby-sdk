# SmplkitGeneratedClient::Flags::UsageAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **limit_key** | **String** | Identifier of the metered limit, e.g. &#x60;flags.managed_flags&#x60;. |  |
| **period** | **String** | Period the counter covers. &#x60;current&#x60; is the only supported value. |  |
| **value** | **Integer** | Count for the period. |  |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::UsageAttributes.new(
  limit_key: null,
  period: null,
  value: null
)
```

