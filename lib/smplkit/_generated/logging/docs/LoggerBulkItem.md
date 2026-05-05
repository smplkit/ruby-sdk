# SmplkitGeneratedClient::Logging::LoggerBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Normalized logger name |  |
| **level** | **String** | The explicitly-set level on this logger. Null if inherited. | [optional] |
| **resolved_level** | **String** | The effective level after framework inheritance. Never null in compliant SDKs. | [optional] |
| **service** | **String** | Service name that discovered this logger | [optional] |
| **environment** | **String** | Environment where this logger was observed | [optional] |

## Example

```ruby
require 'smplkit_logging_client'

instance = SmplkitGeneratedClient::Logging::LoggerBulkItem.new(
  id: null,
  level: null,
  resolved_level: null,
  service: null,
  environment: null
)
```

