# SmplkitGeneratedClient::App::SubscriptionItemRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **product** | **String** | Product key (e.g. &#x60;audit&#x60;, &#x60;config&#x60;, &#x60;flags&#x60;, &#x60;logging&#x60;). |  |
| **plan** | **String** | Target plan for this product. Must be a paid plan such as &#x60;STANDARD&#x60; or &#x60;PRO&#x60;; the free plan is implicit when a product is not listed. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionItemRequest.new(
  product: null,
  plan: null
)
```

