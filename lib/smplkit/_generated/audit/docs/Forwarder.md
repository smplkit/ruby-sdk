# SmplkitGeneratedClient::Audit::Forwarder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the forwarder. |  |
| **forwarder_type** | [**ForwarderType**](ForwarderType.md) | Destination type. |  |
| **enabled** | **Boolean** | Whether the forwarder is currently delivering events. Set to &#x60;false&#x60; to pause deliveries without deleting the forwarder. | [optional][default to true] |
| **filter** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against each event. The event is delivered only if the expression returns truthy. Omit to deliver every event. | [optional] |
| **transform** | **String** | JSONata template applied to each event before delivery. Omit to deliver the event unchanged. | [optional] |
| **http** | [**ForwarderHttp**](ForwarderHttp.md) | HTTP request used to deliver each event to the destination. |  |
| **slug** | **String** | URL-safe identifier derived from &#x60;name&#x60; at create time. Stable for the lifetime of the forwarder. | [optional][readonly] |
| **created_at** | **Time** | When the forwarder was created. | [optional][readonly] |
| **updated_at** | **Time** | When the forwarder was last modified. | [optional][readonly] |
| **deleted_at** | **Time** | When the forwarder was deleted. &#x60;null&#x60; for active forwarders. | [optional][readonly] |
| **version** | **Integer** | Monotonic counter incremented on every update, starting at 1. | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Forwarder.new(
  name: null,
  forwarder_type: null,
  enabled: null,
  filter: null,
  transform: null,
  http: null,
  slug: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

