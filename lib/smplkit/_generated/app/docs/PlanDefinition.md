# SmplkitGeneratedClient::App::PlanDefinition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **price_monthly_cents** | **Integer** | Monthly list price in cents. &#x60;0&#x60; for free plans. |  |
| **limits** | **Hash&lt;String, Integer&gt;** | Map of limit key to the cap that applies on this plan. &#x60;-1&#x60; indicates an unlimited cap. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::PlanDefinition.new(
  price_monthly_cents: null,
  limits: null
)
```

