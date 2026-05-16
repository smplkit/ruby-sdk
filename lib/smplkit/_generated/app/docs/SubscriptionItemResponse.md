# SmplkitGeneratedClient::App::SubscriptionItemResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Unique identifier for this enrollment. |  |
| **product** | **String** | Product key (e.g. &#x60;audit&#x60;, &#x60;config&#x60;, &#x60;flags&#x60;, &#x60;logging&#x60;). |  |
| **plan** | **String** | Current plan for this product (e.g. &#x60;STANDARD&#x60;, &#x60;PRO&#x60;). |  |
| **price_monthly_cents** | **Integer** | Monthly list price for this enrollment, in cents. This value is locked at the time the enrollment was created or last had its plan changed; subsequent changes to the public price list do not affect this enrollment until the customer themselves changes their plan. |  |
| **pending_plan_change** | **String** | When a plan change is scheduled for the end of the current billing period, this is the plan that will take effect. Otherwise &#x60;null&#x60;. The value &#x60;FREE&#x60; indicates the enrollment will be dropped. | [optional] |
| **scheduled_change_effective_at** | **String** | ISO-8601 timestamp at which the pending plan change takes effect. Matches the subscription&#39;s &#x60;current_period_end&#x60;. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionItemResponse.new(
  id: null,
  product: null,
  plan: null,
  price_monthly_cents: null,
  pending_plan_change: null,
  scheduled_change_effective_at: null
)
```

