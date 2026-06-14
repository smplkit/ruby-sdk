# SmplkitGeneratedClient::App::PlanDefinition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **price_monthly_cents** | **Integer** | Monthly list price in cents. &#x60;0&#x60; for free plans. |  |
| **limits** | **Hash&lt;String, Integer&gt;** | Map of limit key to the cap that applies on this plan. &#x60;-1&#x60; indicates an unlimited cap. |  |
| **overage_rates** | **Hash&lt;String, Integer&gt;** | For metered products only: map of metered limit key to the per-unit overage price in micro-USD ($0.000001) charged for each unit beyond the plan&#39;s included allotment. A rate of &#x60;0&#x60; means the plan stops at its allotment with no overage. Omitted for products that are not metered. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::PlanDefinition.new(
  price_monthly_cents: null,
  limits: null,
  overage_rates: null
)
```

