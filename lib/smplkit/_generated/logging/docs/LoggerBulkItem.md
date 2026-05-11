# SmplkitGeneratedClient::Logging::LoggerBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Dot-separated logger key as the SDK saw it. |  |
| **level** | **String** | Level explicitly set on the logger by application code. &#x60;null&#x60; when the level is inherited. | [optional] |
| **resolved_level** | **String** | Effective level after framework inheritance. SDKs should always report this; the server falls back to &#x60;level&#x60; when &#x60;resolved_level&#x60; is missing. | [optional] |
| **service** | **String** | Service name that observed the logger. | [optional] |
| **environment** | **String** | Environment where the logger was observed. | [optional] |

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

