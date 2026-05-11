# SmplkitGeneratedClient::App::PaymentMethod

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **brand** | **String** | Card network brand, e.g. &#x60;visa&#x60;, &#x60;mastercard&#x60;, &#x60;amex&#x60;. | [optional][readonly] |
| **last4** | **String** | Last four digits of the card number. | [optional][readonly] |
| **exp_month** | **Integer** | Expiry month (1-12). | [optional] |
| **exp_year** | **Integer** | Expiry year (four-digit). | [optional] |
| **default** | **Boolean** | Whether this payment method is the account&#39;s default for subscription charges. Use the &#x60;set_default&#x60; action to change which payment method is default — this field is not writable via PUT. | [optional] |
| **billing_details** | **Hash&lt;String, Object&gt;** | Billing details (name, email, phone, address) associated with the card. | [optional] |
| **created_at** | **Time** | When the payment method was registered. | [optional][readonly] |
| **updated_at** | **Time** | When the payment method was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::PaymentMethod.new(
  brand: null,
  last4: null,
  exp_month: null,
  exp_year: null,
  default: null,
  billing_details: null,
  created_at: null,
  updated_at: null
)
```

