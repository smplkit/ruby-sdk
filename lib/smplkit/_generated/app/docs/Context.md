# SmplkitGeneratedClient::App::Context

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable display name | [optional] |
| **context_type** | **String** | Context type key (e.g., &#39;user&#39;, &#39;account&#39;) |  |
| **attributes** | **Hash&lt;String, Object&gt;** | Observed attributes | [optional] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Context.new(
  name: null,
  context_type: null,
  attributes: null,
  created_at: null,
  updated_at: null
)
```

