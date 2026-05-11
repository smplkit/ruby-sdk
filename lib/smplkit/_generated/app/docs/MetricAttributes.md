# SmplkitGeneratedClient::App::MetricAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Metric series name, e.g. &#x60;flags.evaluations&#x60;. Dot-separated. |  |
| **value** | [**Value**](Value.md) |  |  |
| **unit** | **String** | Unit the value is expressed in, e.g. &#x60;evaluations&#x60;, &#x60;ms&#x60;, &#x60;bytes&#x60;. | [optional] |
| **period_seconds** | **Integer** | Length of the aggregation window in seconds (e.g. &#x60;60&#x60; for a one-minute roll-up). |  |
| **dimensions** | **Hash&lt;String, String&gt;** | Optional dimension keys that scope the data point, e.g. &#x60;environment&#x60;, &#x60;service&#x60;. Used as filter targets on the list endpoint via &#x60;filter[dimensions.&lt;key&gt;]&#x3D;...&#x60;. | [optional] |
| **recorded_at** | **Time** | Start of the aggregation window this data point covers. |  |
| **created_at** | **Time** | When the data point was ingested. | [optional][readonly] |

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

