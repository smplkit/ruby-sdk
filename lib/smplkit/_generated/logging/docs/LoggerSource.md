# SmplkitGeneratedClient::Logging::LoggerSource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **service** | **String** | Service that reported the logger. | [optional][readonly] |
| **environment** | **String** | Environment the service was running in when it reported the logger. | [optional][readonly] |
| **level** | **String** | Level explicitly set on the logger in the source runtime. &#x60;null&#x60; when the runtime inherits its level. | [optional][readonly] |
| **resolved_level** | **String** | Effective level the runtime resolved for the logger. | [optional][readonly] |
| **first_observed** | **Time** | When this service / environment combination first reported the logger. | [optional][readonly] |
| **last_seen** | **Time** | Most recent report received for this service / environment combination. | [optional][readonly] |
| **created_at** | **Time** | When the source row was created. | [optional][readonly] |
| **updated_at** | **Time** | When the source row was last refreshed. | [optional][readonly] |

## Example

```ruby
require 'smplkit_logging_client'

instance = SmplkitGeneratedClient::Logging::LoggerSource.new(
  service: null,
  environment: null,
  level: null,
  resolved_level: null,
  first_observed: null,
  last_seen: null,
  created_at: null,
  updated_at: null
)
```

