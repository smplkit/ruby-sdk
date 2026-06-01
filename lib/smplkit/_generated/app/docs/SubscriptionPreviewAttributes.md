# SmplkitGeneratedClient::App::SubscriptionPreviewAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **projected_subtotal_cents** | **Integer** | Projected sum of item monthly list prices after the change. |  |
| **projected_discount_pct** | **Integer** | Projected discount percentage that will apply after the change. |  |
| **projected_discount_source** | **String** | &#x60;VOLUME&#x60; when the projected discount comes from the multi-product schedule; &#x60;OVERRIDE&#x60; when an administrator&#39;s discount applies. |  |
| **projected_discount_amount_cents** | **Integer** | Projected discount amount in cents after the change. |  |
| **projected_total_cents** | **Integer** | Projected final monthly total in cents after the change. |  |
| **projected_next_tier** | [**NextTierResponse**](NextTierResponse.md) |  | [optional] |
| **changes** | [**Array&lt;SubscriptionChangeProjection&gt;**](SubscriptionChangeProjection.md) | Per-product breakdown of changes the desired state would produce. Products that would remain unchanged are omitted. |  |
| **total_charge_today_cents** | **Integer** | Total amount in cents that would be charged at confirmation time — the sum of &#x60;prorated_charge_today_cents&#x60; across all changes. &#x60;0&#x60; when there is no immediate charge (for example when changes apply to an already-active subscription and the prorated amounts are carried onto the next invoice instead). |  |
| **next_invoice_total_cents** | **Integer** | Projected total of the next monthly invoice in cents, after all scheduled changes have taken effect. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionPreviewAttributes.new(
  projected_subtotal_cents: null,
  projected_discount_pct: null,
  projected_discount_source: null,
  projected_discount_amount_cents: null,
  projected_total_cents: null,
  projected_next_tier: null,
  changes: null,
  total_charge_today_cents: null,
  next_invoice_total_cents: null
)
```

