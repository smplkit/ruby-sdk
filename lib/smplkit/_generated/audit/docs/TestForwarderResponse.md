# SmplkitGeneratedClient::Audit::TestForwarderResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **succeeded** | **Boolean** | True if the destination responded with a status matching &#x60;success_status&#x60;. |  |
| **response_status** | **Integer** | HTTP status code returned by the destination. |  |
| **response_headers** | **Hash&lt;String, String&gt;** | Headers returned by the destination. | [optional] |
| **response_body** | **String** | Response body returned by the destination. | [optional] |
| **latency_ms** | **Integer** | Elapsed time of the request in milliseconds. |  |
| **error** | **String** | Error message if the request did not complete. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::TestForwarderResponse.new(
  succeeded: null,
  response_status: null,
  response_headers: null,
  response_body: null,
  latency_ms: null,
  error: null
)
```

