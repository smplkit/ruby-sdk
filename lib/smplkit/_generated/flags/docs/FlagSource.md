# SmplkitGeneratedClient::Flags::FlagSource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **service** | **String** | Service that declared the flag. | [optional][readonly] |
| **environment** | **String** | Environment in which the service declared the flag. | [optional][readonly] |
| **declared_type** | **String** | Value type the SDK reported when registering the flag from this service/environment. May differ from the flag&#39;s authoritative &#x60;type&#x60; if the service is running stale code. | [optional][readonly] |
| **declared_default** | **Object** |  | [optional] |
| **first_observed** | **Time** | When this source was first observed. | [optional][readonly] |
| **last_seen** | **Time** | Most recent time the SDK re-registered this source. | [optional][readonly] |
| **created_at** | **Time** | When the source record was created. | [optional][readonly] |
| **updated_at** | **Time** | When the source record was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagSource.new(
  service: null,
  environment: null,
  declared_type: null,
  declared_default: null,
  first_observed: null,
  last_seen: null,
  created_at: null,
  updated_at: null
)
```

