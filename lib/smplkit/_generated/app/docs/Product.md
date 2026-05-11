# SmplkitGeneratedClient::App::Product

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **display_name** | **String** | Human-readable product name. |  |
| **description** | **String** | Long-form product description. |  |
| **tagline** | **String** | Short marketing tagline shown on plan-selection surfaces. | [optional] |
| **features** | **Array&lt;String&gt;** | Bullet-list feature highlights for the product. | [optional] |
| **coming_soon** | **Boolean** | When &#x60;true&#x60;, the product is listed but not yet available for subscription. | [optional][default to false] |
| **limits** | [**Hash&lt;String, LimitDefinition&gt;**](LimitDefinition.md) | Map of limit key to limit definition for this product. |  |
| **plans** | [**Hash&lt;String, PlanDefinition&gt;**](PlanDefinition.md) | Map of plan key to plan definition for this product. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Product.new(
  display_name: null,
  description: null,
  tagline: null,
  features: null,
  coming_soon: null,
  limits: null,
  plans: null
)
```

