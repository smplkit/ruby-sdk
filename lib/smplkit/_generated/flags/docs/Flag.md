# SmplkitGeneratedClient::Flags::Flag

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable display name |  |
| **description** | **String** |  | [optional] |
| **type** | **String** | Value type: STRING, BOOLEAN, NUMERIC, or JSON |  |
| **default** | **Object** |  |  |
| **values** | [**Array&lt;FlagValue&gt;**](FlagValue.md) | Ordered set of allowed values (constrained), or null (unconstrained) | [optional] |
| **environments** | [**Hash&lt;String, FlagEnvironment&gt;**](FlagEnvironment.md) |  | [optional] |
| **managed** | **Boolean** | True if admin-managed, false if auto-discovered | [optional] |
| **sources** | **Array&lt;Hash&lt;String, Object&gt;&gt;** |  | [optional][readonly] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::Flag.new(
  name: null,
  description: null,
  type: null,
  default: null,
  values: null,
  environments: null,
  managed: null,
  sources: null,
  created_at: null,
  updated_at: null
)
```

