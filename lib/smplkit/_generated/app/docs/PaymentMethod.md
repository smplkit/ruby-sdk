# SmplkitGeneratedClient::App::PaymentMethod

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **brand** | **String** |  | [optional][readonly] |
| **last4** | **String** |  | [optional][readonly] |
| **exp_month** | **Integer** |  | [optional] |
| **exp_year** | **Integer** |  | [optional] |
| **default** | **Boolean** |  | [optional] |
| **billing_details** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |

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

