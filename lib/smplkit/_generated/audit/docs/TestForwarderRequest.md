# SmplkitGeneratedClient::Audit::TestForwarderRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** | HTTP method used for the test request. | [optional][default to &#39;POST&#39;] |
| **url** | **String** | Destination URL. Must be an absolute &#x60;http://&#x60; or &#x60;https://&#x60; URL with a hostname (e.g. &#x60;https://siem.example.com/in&#x60;). |  |
| **headers** | [**Array&lt;HttpHeader&gt;**](HttpHeader.md) | HTTP headers attached to the test request. | [optional] |
| **success_status** | **String** | HTTP response status that indicates success. Either a specific status code (e.g. &#x60;200&#x60;, &#x60;204&#x60;) or a status class (&#x60;1xx&#x60;, &#x60;2xx&#x60;, &#x60;3xx&#x60;, &#x60;4xx&#x60;, &#x60;5xx&#x60;). | [optional][default to &#39;2xx&#39;] |
| **timeout_ms** | **Integer** | Per-request timeout in milliseconds. Capped at 30 seconds. | [optional] |
| **tls_verify** | **Boolean** | Whether to verify the destination server&#39;s TLS certificate. Mirrors the parent forwarder field of the same name — see its description for security guidance. Defaults to &#x60;true&#x60;. | [optional][default to true] |
| **ca_cert** | **String** | Optional PEM-encoded certificate (or bundle) used to verify the destination server&#39;s TLS certificate. Mirrors the parent forwarder field. Must contain one or more &#x60;-----BEGIN CERTIFICATE-----&#x60; blocks. | [optional] |
| **body** | **String** | Request body sent to the destination. When omitted, an empty body is sent (suitable for connectivity probes). When set, the body is sent verbatim — pair with an appropriate &#x60;Content-Type&#x60; entry in &#x60;headers&#x60; so the destination interprets it correctly. Limit 1 MiB. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::TestForwarderRequest.new(
  method: null,
  url: null,
  headers: null,
  success_status: null,
  timeout_ms: null,
  tls_verify: null,
  ca_cert: null,
  body: null
)
```

