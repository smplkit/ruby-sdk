# SmplkitGeneratedClient::App::SubscriptionRequestResource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Subscription identifier; the server ignores this and uses the auth context. | [optional] |
| **type** | **String** | JSON:API resource type. |  |
| **attributes** | [**SubscriptionRequestAttributes**](SubscriptionRequestAttributes.md) |  |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionRequestResource.new(
  id: null,
  type: null,
  attributes: null
)
```

