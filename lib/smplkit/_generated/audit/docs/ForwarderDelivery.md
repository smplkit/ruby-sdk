# SmplkitGeneratedClient::Audit::ForwarderDelivery

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** | Forwarder the delivery belongs to. |  |
| **event_id** | **String** | Event that was being delivered. |  |
| **attempt_number** | **Integer** | 1 for the initial delivery, incremented for each retry. |  |
| **status** | **String** | Delivery outcome. &#x60;SUCCEEDED&#x60; and &#x60;FAILED&#x60; are the live-delivery outcomes; &#x60;FILTERED_OUT&#x60; is recorded when the forwarder&#39;s filter rejected the event. |  |
| **request** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against each event. The event is delivered only if the expression returns truthy. Omit to deliver every event. | [optional] |
| **response_status** | **Integer** | HTTP status code returned by the destination. | [optional] |
| **response_body** | **String** | Response body returned by the destination. | [optional] |
| **latency_ms** | **Integer** | Elapsed time of the delivery attempt in milliseconds. | [optional] |
| **error** | **String** | Error message if the delivery did not complete. | [optional] |
| **created_at** | **Time** | When the delivery attempt was recorded. | [optional] |

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

