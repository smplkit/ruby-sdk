# SmplkitGeneratedClient::App::SubscriptionRequestAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **items** | [**Array&lt;SubscriptionItemRequest&gt;**](SubscriptionItemRequest.md) | Desired enrollments. Products listed are scheduled to be on the specified plan immediately (for upgrades and new enrollments) or at the end of the current billing period (for downgrades). Products not listed are scheduled to be dropped at the end of the current billing period. |  |
| **payment_method** | **String** | Optional identifier of the payment method to bill against. If omitted, the account&#39;s default payment method is used. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionRequestAttributes.new(
  items: null,
  payment_method: null
)
```

