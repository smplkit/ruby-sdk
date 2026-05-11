# SmplkitGeneratedClient::App::Environment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the environment. |  |
| **color** | **String** | Display color used by the console to badge the environment. Accepts any CSS color string. | [optional] |
| **classification** | **String** | &#x60;STANDARD&#x60; for environments the customer explicitly manages; &#x60;AD_HOC&#x60; for environments auto-created from SDK traffic. Case-insensitive on input. | [optional][default to &#39;AD_HOC&#39;] |
| **created_at** | **Time** | When the environment was created. | [optional][readonly] |
| **updated_at** | **Time** | When the environment was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Environment.new(
  name: null,
  color: null,
  classification: null,
  created_at: null,
  updated_at: null
)
```

