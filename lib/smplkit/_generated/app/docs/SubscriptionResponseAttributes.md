# SmplkitGeneratedClient::App::SubscriptionResponseAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **status** | **String** | Lifecycle state of the subscription. &#x60;ACTIVE&#x60; while billing is current; &#x60;PAST_DUE&#x60; after a failed charge; &#x60;CANCELED&#x60; once the subscription has ended; &#x60;null&#x60; when the subscription has no billing object (fully comped at 100% discount). | [optional] |
| **current_period_start** | **String** | ISO-8601 timestamp of the current billing period&#39;s start. | [optional] |
| **current_period_end** | **String** | ISO-8601 timestamp of the current billing period&#39;s end. Scheduled plan changes take effect at this moment. | [optional] |
| **discount_pct** | **Integer** | Effective discount percentage applied to the subscription&#39;s monthly invoice. This is the value locked at the time of the customer&#39;s last subscription change; subsequent changes to the public discount schedule do not affect this customer until they themselves change their subscription. |  |
| **discount_source** | **String** | &#x60;VOLUME&#x60; when the discount comes from the multi-product discount schedule; &#x60;OVERRIDE&#x60; when an administrator has applied a custom discount. |  |
| **subtotal_cents** | **Integer** | Sum of all item list prices in cents, before discount. |  |
| **discount_amount_cents** | **Integer** | Amount discounted from the subtotal in cents. |  |
| **total_cents** | **Integer** | Final monthly total in cents after the discount is applied. |  |
| **next_tier** | [**NextTierResponse**](NextTierResponse.md) |  | [optional] |
| **payment_method** | **String** | Identifier of the default payment method used to bill this subscription. &#x60;null&#x60; when the subscription has no associated payment method (e.g. fully comped). | [optional] |
| **items** | [**Array&lt;SubscriptionItemResponse&gt;**](SubscriptionItemResponse.md) | One entry per product currently enrolled on the subscription. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionResponseAttributes.new(
  status: null,
  current_period_start: null,
  current_period_end: null,
  discount_pct: null,
  discount_source: null,
  subtotal_cents: null,
  discount_amount_cents: null,
  total_cents: null,
  next_tier: null,
  payment_method: null,
  items: null
)
```

