# SmplkitGeneratedClient::Flags::FlagEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** |  | [optional][default to true] |
| **default** | [**AnyOf**](AnyOf.md) |  | [optional] |
| **rules** | [**Array&lt;FlagRule&gt;**](FlagRule.md) |  | [optional] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagEnvironment.new(
  enabled: null,
  default: null,
  rules: null
)
```

