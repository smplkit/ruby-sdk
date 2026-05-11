# SmplkitGeneratedClient::App::CreateSubscriptionAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **product** | **String** | Product key to subscribe to, e.g. &#x60;flags&#x60;. |  |
| **plan** | **String** | Plan key to subscribe on, e.g. &#x60;pro&#x60;. |  |
| **payment_method** | **String** | UUID of a payment method on file to bill against. If omitted, the account&#39;s default payment method is used. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::CreateSubscriptionAttributes.new(
  product: null,
  plan: null,
  payment_method: null
)
```

