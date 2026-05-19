# SmplkitGeneratedClient::Audit::ForwarderTypeHttpConfiguration

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** | HTTP method. |  |
| **url** | **String** | URL template. &#x60;null&#x60; for the synthetic &#x60;http&#x60; (Custom HTTP) entry, where the customer supplies the URL from scratch. May contain &#x60;{name}&#x60; placeholders that map to the &#x60;placeholders&#x60; block. |  |
| **success_status** | **String** | HTTP response status indicating a successful delivery — either a specific code (&#x60;200&#x60;, &#x60;204&#x60;) or a class (&#x60;2xx&#x60;). |  |
| **headers** | [**Array&lt;ForwarderTypeHeader&gt;**](ForwarderTypeHeader.md) | Headers attached to each delivery request. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypeHttpConfiguration.new(
  method: null,
  url: null,
  success_status: null,
  headers: null
)
```

