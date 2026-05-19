# SmplkitGeneratedClient::Audit::ForwarderTypeResource

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Lowercase forwarder type id — matches &#x60;forwarder.forwarder_type&#x60; values and is the filename stem of &#x60;forwarder_types/&lt;id&gt;.yaml&#x60;. |  |
| **type** | **String** |  | [optional][default to &#39;forwarder_type&#39;] |
| **attributes** | [**ForwarderTypeAttributes**](ForwarderTypeAttributes.md) |  |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypeResource.new(
  id: null,
  type: null,
  attributes: null
)
```

