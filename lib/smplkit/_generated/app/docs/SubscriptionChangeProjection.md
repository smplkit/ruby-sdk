# SmplkitGeneratedClient::App::SubscriptionChangeProjection

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **product** | **String** | Product key affected by this change. |  |
| **from_plan** | **String** | Current plan for this product, or &#x60;free&#x60; if it is being added. |  |
| **to_plan** | **String** | Plan the product will be on after the change. &#x60;free&#x60; indicates the enrollment will be dropped. |  |
| **monthly_cents** | **Integer** | Monthly cost in cents of this enrollment after the change. &#x60;0&#x60; when the enrollment will be dropped. |  |
| **effect** | **String** | &#x60;IMMEDIATE&#x60; when the change takes effect at confirmation time (and a prorated charge may apply today). &#x60;NEXT_PERIOD&#x60; when the change takes effect at the end of the current billing period. |  |
| **prorated_charge_today_cents** | **Integer** | When &#x60;effect&#x60; is &#x60;IMMEDIATE&#x60;, the estimated prorated charge for the remainder of the current billing period in cents. Always &#x60;0&#x60; when &#x60;effect&#x60; is &#x60;NEXT_PERIOD&#x60;. | [optional][default to 0] |
| **starts_at** | **String** | When &#x60;effect&#x60; is &#x60;NEXT_PERIOD&#x60;, the ISO-8601 timestamp at which the change takes effect. &#x60;null&#x60; when &#x60;effect&#x60; is &#x60;IMMEDIATE&#x60; (the change applies on confirmation). | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionChangeProjection.new(
  product: null,
  from_plan: null,
  to_plan: null,
  monthly_cents: null,
  effect: null,
  prorated_charge_today_cents: null,
  starts_at: null
)
```

