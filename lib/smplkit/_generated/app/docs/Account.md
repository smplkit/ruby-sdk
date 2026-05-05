# SmplkitGeneratedClient::App::Account

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **key** | **String** |  |  |
| **has_stripe_customer** | **Boolean** |  | [optional][readonly][default to false] |
| **expires_at** | **Time** |  | [optional][readonly] |
| **created_at** | **Time** |  | [optional][readonly] |
| **deleted_at** | **Time** |  | [optional][readonly] |
| **product_subscriptions** | **Hash&lt;String, Object&gt;** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Account.new(
  name: null,
  key: null,
  has_stripe_customer: null,
  expires_at: null,
  created_at: null,
  deleted_at: null,
  product_subscriptions: null
)
```

