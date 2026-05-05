# SmplkitGeneratedClient::App::Product

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **display_name** | **String** |  |  |
| **description** | **String** |  |  |
| **coming_soon** | **Boolean** |  | [optional][default to false] |
| **limits** | [**Hash&lt;String, LimitDefinition&gt;**](LimitDefinition.md) |  |  |
| **plans** | [**Hash&lt;String, PlanDefinition&gt;**](PlanDefinition.md) |  |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Product.new(
  display_name: null,
  description: null,
  coming_soon: null,
  limits: null,
  plans: null
)
```

