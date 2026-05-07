# SmplkitGeneratedClient::Audit::ForwarderDelivery

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |
| **event_id** | **String** |  |  |
| **attempt_number** | **Integer** |  |  |
| **status** | **String** |  |  |
| **request** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **response_status** | **Integer** |  | [optional] |
| **response_body** | **String** |  | [optional] |
| **latency_ms** | **Integer** |  | [optional] |
| **error** | **String** |  | [optional] |
| **created_at** | **Time** |  | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderDelivery.new(
  forwarder_id: null,
  event_id: null,
  attempt_number: null,
  status: null,
  request: null,
  response_status: null,
  response_body: null,
  latency_ms: null,
  error: null,
  created_at: null
)
```

