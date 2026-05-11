# SmplkitGeneratedClient::App::SubscriptionAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **product** | **String** | Product key the subscription is for, e.g. &#x60;flags&#x60;. |  |
| **plan** | **String** | Plan key the subscription is on, e.g. &#x60;pro&#x60;. |  |
| **status** | **String** | Lifecycle state of the subscription, e.g. &#x60;active&#x60;, &#x60;trialing&#x60;, &#x60;past_due&#x60;, &#x60;canceled&#x60;. | [optional] |
| **comped** | **Boolean** | When &#x60;true&#x60;, the subscription is complimentary and is not billed through the billing provider. |  |
| **stripe_managed** | **Boolean** | When &#x60;true&#x60;, the subscription is billed through Stripe; otherwise it is a free or complimentary subscription that does not produce invoices. |  |
| **current_period_end** | **String** | End of the current billing period (ISO 8601 timestamp). | [optional] |
| **client_secret** | **String** | Stripe payment intent client secret returned when a subscription create requires additional authentication (3DS). Returned only on create. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::SubscriptionAttributes.new(
  product: null,
  plan: null,
  status: null,
  comped: null,
  stripe_managed: null,
  current_period_end: null,
  client_secret: null
)
```

