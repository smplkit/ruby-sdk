# SmplkitGeneratedClient::App::AdminSubscriptionRequestAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **items** | [**Array&lt;SubscriptionItemRequest&gt;**](SubscriptionItemRequest.md) | Desired enrollments. Products listed are scheduled to be on the specified plan immediately (for upgrades and new enrollments) or at the end of the current billing period (for downgrades). Products not listed are scheduled to be dropped at the end of the current billing period. |  |
| **payment_method** | **String** | Optional identifier of the payment method to bill against. If omitted, the account&#39;s default payment method is used. | [optional] |
| **discount_override_pct** | **Integer** | Administrator-set discount percentage (0–100). When set, the multi-product discount schedule is bypassed and this value is used directly. Setting &#x60;100&#x60; skips the billing provider entirely — the customer pays nothing. Pass &#x60;null&#x60; to clear any existing override and revert to the multi-product discount schedule. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::AdminSubscriptionRequestAttributes.new(
  items: null,
  payment_method: null,
  discount_override_pct: null
)
```

