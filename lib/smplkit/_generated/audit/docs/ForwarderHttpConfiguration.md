# SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** | HTTP method used when delivering the request. | [optional][default to &#39;POST&#39;] |
| **url** | **String** | Destination URL. Must be an absolute &#x60;http://&#x60; or &#x60;https://&#x60; URL with a hostname (e.g. &#x60;https://siem.example.com/in&#x60;). |  |
| **headers** | **Hash&lt;String, String&gt;** | HTTP headers attached to each delivery, as a name→value object (e.g. &#x60;{\&quot;DD-API-KEY\&quot;: \&quot;s3cr3t\&quot;}&#x60;). A header is overridden in a specific environment by its name via a &#x60;headers.&lt;name&gt;&#x60; entry in that environment&#39;s overrides; header names match case-insensitively. | [optional] |
| **success_status** | **String** | HTTP response status that indicates success. Either a specific status code (e.g. &#x60;200&#x60;, &#x60;204&#x60;) or a status class (&#x60;1xx&#x60;, &#x60;2xx&#x60;, &#x60;3xx&#x60;, &#x60;4xx&#x60;, &#x60;5xx&#x60;). | [optional][default to &#39;2xx&#39;] |
| **tls_verify** | **Boolean** | Whether to verify the destination server&#39;s TLS certificate against trusted certificate authorities. Defaults to &#x60;true&#x60; and should be left on for any production destination. Set to &#x60;false&#x60; only for development or short-lived testing against a destination that presents an untrusted certificate (e.g. a Splunk Cloud trial stack on &#x60;:8088&#x60; serving its default self-signed certificate). When &#x60;false&#x60;, deliveries proceed without certificate verification — they are vulnerable to man-in-the-middle attacks. For long-lived self-signed setups, pin the issuing CA via &#x60;ca_cert&#x60; instead of disabling verification entirely. | [optional][default to true] |
| **ca_cert** | **String** | Optional PEM-encoded certificate (or bundle) used to verify the destination server&#39;s TLS certificate, in addition to the system trust store. Use this to pin a private or self-signed CA (e.g. Splunk&#39;s default &#x60;SplunkCommonCA&#x60;) without disabling verification entirely via &#x60;tls_verify&#x60;. Must contain one or more &#x60;-----BEGIN CERTIFICATE-----&#x60; blocks. Ignored when &#x60;tls_verify&#x60; is &#x60;false&#x60;. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration.new(
  method: null,
  url: null,
  headers: null,
  success_status: null,
  tls_verify: null,
  ca_cert: null
)
```

