# SmplkitGeneratedClient::App::NextTierResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **products_needed** | **Integer** | Number of additional paid products required to reach the next discount tier. |  |
| **discount_pct** | **Integer** | Discount percentage that would apply at the next tier. |  |
| **additional_savings_cents** | **Integer** | Estimated additional monthly savings (in cents) at the next tier, compared to paying full list price for the added product. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::NextTierResponse.new(
  products_needed: null,
  discount_pct: null,
  additional_savings_cents: null
)
```

