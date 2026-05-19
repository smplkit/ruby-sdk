# SmplkitGeneratedClient::Logging::LogGroup

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable label for the group. |  |
| **level** | [**LogLevel**](LogLevel.md) | Default level applied to every logger in the group. &#x60;null&#x60; leaves member loggers to inherit from elsewhere. | [optional] |
| **parent_id** | **String** | Reserved for nested groups. Must be &#x60;null&#x60; in this version; nested groups are not yet supported. | [optional] |
| **environments** | **Hash&lt;String, Object&gt;** | Per-environment level overrides keyed by environment name. Each value is an object with an optional &#x60;level&#x60; field, e.g. &#x60;{\&quot;production\&quot;: {\&quot;level\&quot;: \&quot;ERROR\&quot;}}&#x60;. Member loggers inherit the per-environment level unless they set their own override. | [optional] |
| **created_at** | **Time** | When the group was created. | [optional][readonly] |
| **updated_at** | **Time** | When the group was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_logging_client'

instance = SmplkitGeneratedClient::Logging::LogGroup.new(
  name: null,
  level: null,
  parent_id: null,
  environments: null,
  created_at: null,
  updated_at: null
)
```

