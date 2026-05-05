# SmplkitGeneratedClient::App::SubscriptionAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **product** | **String** |  |  |
| **plan** | **String** |  |  |
| **status** | **String** |  | [optional] |
| **comped** | **Boolean** |  |  |
| **stripe_managed** | **Boolean** |  |  |
| **bundle** | **String** |  | [optional] |
| **current_period_end** | **String** |  | [optional] |
| **client_secret** | **String** |  | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionAttributes.new(
  product: null,
  plan: null,
  status: null,
  comped: null,
  stripe_managed: null,
  bundle: null,
  current_period_end: null,
  client_secret: null
)
```

