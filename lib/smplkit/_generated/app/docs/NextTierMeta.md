# SmplkitGeneratedClient::App::NextTierMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **products_needed** | **Integer** | Number of additional subscribed products needed to reach the next tier. |  |
| **discount_pct** | **Integer** | Discount percentage that would apply at the next tier. |  |
| **additional_savings_cents** | **Integer** | Additional monthly savings in cents at the next tier. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::NextTierMeta.new(
  products_needed: null,
  discount_pct: null,
  additional_savings_cents: null
)
```

