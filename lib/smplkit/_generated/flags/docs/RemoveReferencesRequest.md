# SmplkitGeneratedClient::Flags::RemoveReferencesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **context** | **String** | Identifier of the context instance to remove references to, formatted as &#x60;{type}:{key}&#x60; (e.g. &#x60;customer:c-123&#x60;). | [optional] |
| **context_type** | **String** | Context type to remove all references to (any attribute of this type). | [optional] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::RemoveReferencesRequest.new(
  context: null,
  context_type: null
)
```

