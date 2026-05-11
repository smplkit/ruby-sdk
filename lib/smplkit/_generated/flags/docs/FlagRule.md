# SmplkitGeneratedClient::Flags::FlagRule

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **description** | **String** | Human-readable description of the rule. | [optional] |
| **logic** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against the evaluation context. The rule fires when the expression is truthy. |  |
| **value** | **Object** |  |  |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagRule.new(
  description: null,
  logic: null,
  value: null
)
```

