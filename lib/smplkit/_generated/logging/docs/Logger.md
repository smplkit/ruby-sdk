# SmplkitGeneratedClient::Logging::Logger

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** |  |  |
| **level** | **String** |  | [optional] |
| **group** | **String** |  | [optional] |
| **managed** | **Boolean** |  | [optional] |
| **sources** | **Array&lt;Hash&lt;String, Object&gt;&gt;** |  | [optional][readonly] |
| **environments** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **effective_levels** | **Hash&lt;String, Object&gt;** |  | [optional][readonly] |
| **created_at** | **Time** |  | [optional][readonly] |
| **updated_at** | **Time** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_logging_client'

instance = SmplkitGeneratedClient::Logging::Logger.new(
  name: null,
  level: null,
  group: null,
  managed: null,
  sources: null,
  environments: null,
  effective_levels: null,
  created_at: null,
  updated_at: null
)
```

