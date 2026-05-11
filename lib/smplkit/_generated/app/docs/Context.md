# SmplkitGeneratedClient::App::Context

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable display name for the context instance. | [optional] |
| **context_type** | **String** | Key of the context type this instance belongs to (e.g. &#x60;user&#x60;, &#x60;account&#x60;). |  |
| **attributes** | **Hash&lt;String, Object&gt;** | Observed attribute values for this context instance. The key set is conventionally aligned with the parent context type&#39;s known attribute keys, but additional keys are accepted. | [optional] |
| **created_at** | **Time** | When the context instance was first registered. | [optional][readonly] |
| **updated_at** | **Time** | When the context instance was last modified. | [optional][readonly] |

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

