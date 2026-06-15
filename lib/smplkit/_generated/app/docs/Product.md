# SmplkitGeneratedClient::App::Product

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **display_name** | **String** | Human-readable product name. |  |
| **description** | **String** | Long-form product description. |  |
| **tagline** | **String** | Short marketing tagline shown on plan-selection surfaces. | [optional] |
| **features** | **Array&lt;String&gt;** | Bullet-list feature highlights for the product. | [optional] |
| **limits** | [**Hash&lt;String, LimitDefinition&gt;**](LimitDefinition.md) | Map of limit key to limit definition for this product. |  |
| **metered_limits** | **Array&lt;String&gt;** | Limit keys on this product that are metered: each includes a monthly allotment in the plan price and bills per unit beyond it at the plan&#39;s &#x60;overage_rates&#x60; rate, rather than capping hard. Empty for products with no metered limits. | [optional] |
| **plans** | [**Hash&lt;String, PlanDefinition&gt;**](PlanDefinition.md) | Map of plan key to plan definition for this product. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Product.new(
  display_name: null,
  description: null,
  tagline: null,
  features: null,
  limits: null,
  metered_limits: null,
  plans: null
)
```

