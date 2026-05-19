# SmplkitGeneratedClient::Audit::ForwarderTypeHeader

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Header name. |  |
| **value** | **String** | Header value template. Strings of the form &#x60;{name}&#x60; are placeholders the customer fills in; look up &#x60;name&#x60; in &#x60;placeholders&#x60; for the UI metadata. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypeHeader.new(
  name: null,
  value: null
)
```

