# SmplkitGeneratedClient::App::ContextType

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Display label for the context type, e.g. &#x60;User&#x60;, &#x60;Account&#x60;, or &#x60;Device&#x60;. |  |
| **attributes** | **Hash&lt;String, Object&gt;** | Map of known attribute key to per-attribute metadata. The metadata object is free-form and may be empty. Keys grow as new attributes are observed on context instances of this type. | [optional] |
| **created_at** | **Time** | When the context type was created. | [optional][readonly] |
| **updated_at** | **Time** | When the context type was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::ContextType.new(
  name: null,
  attributes: null,
  created_at: null,
  updated_at: null
)
```

