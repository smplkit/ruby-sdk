# SmplkitGeneratedClient::Audit::TestForwarderResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **succeeded** | **Boolean** |  |  |
| **response_status** | **Integer** |  |  |
| **response_headers** | **Hash&lt;String, String&gt;** |  | [optional] |
| **response_body** | **String** |  | [optional] |
| **latency_ms** | **Integer** |  |  |
| **error** | **String** |  | [optional] |

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

