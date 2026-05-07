# SmplkitGeneratedClient::App::SubscriptionListMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **subtotal_cents** | **Integer** |  |  |
| **discount_pct** | **Integer** |  |  |
| **discount_amount_cents** | **Integer** |  |  |
| **discount_source** | **String** |  |  |
| **total_cents** | **Integer** |  |  |
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

