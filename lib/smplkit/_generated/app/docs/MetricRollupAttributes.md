# SmplkitGeneratedClient::App::MetricRollupAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Metric series name the rollup is computed from. |  |
| **value** | **String** | Sum of the underlying metric values over the bucket. |  |
| **unit** | **String** | Unit the value is expressed in. | [optional] |
| **bucket** | **Time** | Start of the time bucket this rollup covers. |  |
| **rollup** | **String** | Rollup interval. One of &#x60;1m&#x60;, &#x60;5m&#x60;, &#x60;15m&#x60;, &#x60;1h&#x60;, &#x60;6h&#x60;, &#x60;1d&#x60;. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::MetricRollupAttributes.new(
  name: null,
  value: null,
  unit: null,
  bucket: null,
  rollup: null
)
```

