# SmplkitGeneratedClient::Audit::TestForwarderRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** | HTTP method used for the test request. | [optional][default to &#39;POST&#39;] |
| **url** | **String** | Destination URL. |  |
| **headers** | [**Array&lt;HttpHeader&gt;**](HttpHeader.md) | HTTP headers attached to the test request. | [optional] |
| **body** | **String** | Request body. If omitted, an empty body is sent. | [optional] |
| **success_status** | **String** | HTTP response status that indicates success. Either a specific status code (e.g. &#x60;200&#x60;, &#x60;204&#x60;) or a status class (&#x60;1xx&#x60;, &#x60;2xx&#x60;, &#x60;3xx&#x60;, &#x60;4xx&#x60;, &#x60;5xx&#x60;). | [optional][default to &#39;2xx&#39;] |
| **timeout_ms** | **Integer** | Per-request timeout in milliseconds. Capped at 30 seconds. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::TestForwarderRequest.new(
  method: null,
  url: null,
  headers: null,
  body: null,
  success_status: null,
  timeout_ms: null
)
```

