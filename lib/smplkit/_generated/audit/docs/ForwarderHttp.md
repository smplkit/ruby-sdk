# SmplkitGeneratedClient::Audit::ForwarderHttp

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** | HTTP method used when delivering an event. | [optional][default to &#39;POST&#39;] |
| **url** | **String** | Destination URL. |  |
| **headers** | [**Array&lt;HttpHeader&gt;**](HttpHeader.md) | HTTP headers attached to each delivery request. | [optional] |
| **body** | **String** | Request body sent to the destination. If omitted, the event JSON is sent as the body. | [optional] |
| **success_status** | **String** | HTTP response status that indicates a successful delivery. Either a specific status code (e.g. &#x60;200&#x60;, &#x60;204&#x60;) or a status class (&#x60;1xx&#x60;, &#x60;2xx&#x60;, &#x60;3xx&#x60;, &#x60;4xx&#x60;, &#x60;5xx&#x60;). | [optional][default to &#39;2xx&#39;] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderHttp.new(
  method: null,
  url: null,
  headers: null,
  body: null,
  success_status: null
)
```

