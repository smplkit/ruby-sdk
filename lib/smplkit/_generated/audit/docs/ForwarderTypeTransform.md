# SmplkitGeneratedClient::Audit::ForwarderTypeTransform

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** | Engine name. Today only &#x60;JSONATA&#x60;. |  |
| **default** | **String** | Default template; customers can override per forwarder. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypeTransform.new(
  type: null,
  default: null
)
```

