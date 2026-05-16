# SmplkitGeneratedClient::App::Context

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** | Entity identifier within the context type (e.g. &#x60;alice-123&#x60;). Together with &#x60;context_type&#x60; it forms the composite &#x60;id&#x60; &#x60;context_type:key&#x60;. Set by the bulk-register API; not editable. | [readonly] |
| **name** | **String** | Human-readable display name for the context instance. | [optional] |
| **context_type** | **String** | Key of the context type this instance belongs to (e.g. &#x60;user&#x60;, &#x60;account&#x60;). |  |
| **attributes** | **Hash&lt;String, Object&gt;** | Observed attribute values for this context instance. The key set is conventionally aligned with the parent context type&#39;s known attribute keys, but additional keys are accepted. | [optional] |
| **created_at** | **Time** | When the context instance was first registered. | [optional][readonly] |
| **updated_at** | **Time** | When the context instance was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Context.new(
  key: null,
  name: null,
  context_type: null,
  attributes: null,
  created_at: null,
  updated_at: null
)
```

