# SmplkitGeneratedClient::App::LimitDefinition

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **display_name** | **String** | Human-readable name for the limit. |  |
| **description** | **String** | Long-form description of what the limit controls. |  |
| **unit** | **String** | Unit the limit is measured in, e.g. &#x60;flags&#x60;, &#x60;events&#x60;. |  |
| **display_format** | **String** | Optional formatter hint for rendering the limit value in customer-facing UI. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::LimitDefinition.new(
  display_name: null,
  description: null,
  unit: null,
  display_format: null
)
```

