# SmplkitGeneratedClient::App::AddPaymentMethodAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **stripe_payment_method_id** | **String** | Identifier of the Stripe payment method to register on the account, e.g. &#x60;pm_1234567890abcdef&#x60;. |  |
| **default** | **Boolean** | When &#x60;true&#x60;, make the newly registered payment method the account&#39;s default. The first payment method on an account is always set as default regardless of this field. | [optional][default to false] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::AddPaymentMethodAttributes.new(
  stripe_payment_method_id: null,
  default: null
)
```

