# SmplkitGeneratedClient::App::DiscountTier

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **products_count** | **Integer** | Minimum number of paid product subscriptions a customer must hold for this tier&#39;s discount to apply. Counts above the highest defined tier are clamped to that tier. |  |
| **percent_off** | **Integer** | Discount percentage applied to every paid subscription item when the customer holds at least &#x60;&#x60;products_count&#x60;&#x60; paid products. 0 means no discount at this tier. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::DiscountTier.new(
  products_count: null,
  percent_off: null
)
```

