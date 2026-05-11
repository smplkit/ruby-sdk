# SmplkitGeneratedClient::Flags::FlagEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether the flag is active in this environment. When &#x60;false&#x60;, evaluation skips rules and returns the flag&#39;s global &#x60;default&#x60;. | [optional][default to true] |
| **default** | [**AnyOf**](AnyOf.md) | Environment-level default returned when no rule fires. If &#x60;null&#x60;, evaluation falls back to the flag&#39;s global &#x60;default&#x60;. | [optional] |
| **rules** | [**Array&lt;FlagRule&gt;**](FlagRule.md) | Targeting rules evaluated top-down. The first rule whose logic returns truthy provides the result. | [optional] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagEnvironment.new(
  enabled: null,
  default: null,
  rules: null
)
```

