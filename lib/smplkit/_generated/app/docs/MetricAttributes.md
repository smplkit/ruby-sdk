# SmplkitGeneratedClient::App::MetricAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **value** | [**Value**](Value.md) |  |  |
| **unit** | **String** |  | [optional] |
| **period_seconds** | **Integer** |  |  |
| **dimensions** | **Hash&lt;String, String&gt;** |  | [optional] |
| **recorded_at** | **Time** |  |  |
| **created_at** | **Time** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::MetricAttributes.new(
  name: null,
  value: null,
  unit: null,
  period_seconds: null,
  dimensions: null,
  recorded_at: null,
  created_at: null
)
```

