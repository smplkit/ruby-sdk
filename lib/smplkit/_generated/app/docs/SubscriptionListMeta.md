# SmplkitGeneratedClient::App::SubscriptionListMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **subtotal_cents** | **Integer** | Sum of list prices across all subscriptions in cents. |  |
| **discount_pct** | **Integer** | Effective discount percentage applied. |  |
| **discount_amount_cents** | **Integer** | Discount amount in cents. |  |
| **discount_source** | **String** | Source of the discount. &#x60;VOLUME&#x60; indicates the standard volume-discount schedule; &#x60;OVERRIDE&#x60; indicates a custom discount set on the account. |  |
| **total_cents** | **Integer** | Final monthly total in cents after the discount. |  |
| **next_tier** | [**NextTierMeta**](NextTierMeta.md) |  | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionListMeta.new(
  subtotal_cents: null,
  discount_pct: null,
  discount_amount_cents: null,
  discount_source: null,
  total_cents: null,
  next_tier: null
)
```

