# SmplkitGeneratedClient::Flags::FlagBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Flag key as declared in code |  |
| **type** | **String** | Flag type: BOOLEAN, STRING, NUMERIC, or JSON |  |
| **default** | **Object** |  |  |
| **service** | **String** | Service that declared this flag | [optional] |
| **environment** | **String** | Environment where observed | [optional] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagBulkItem.new(
  id: null,
  type: null,
  default: null,
  service: null,
  environment: null
)
```

