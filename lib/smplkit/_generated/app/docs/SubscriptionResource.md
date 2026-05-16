# SmplkitGeneratedClient::App::SubscriptionResource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Subscription identifier. Always &#x60;current&#x60; on response; absent on create-style requests. | [optional] |
| **type** | **String** | JSON:API resource type. |  |
| **attributes** | [**SubscriptionResponseAttributes**](SubscriptionResponseAttributes.md) |  |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionResource.new(
  id: null,
  type: null,
  attributes: null
)
```

