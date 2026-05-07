# SmplkitGeneratedClient::Audit::ForwarderHttp

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method** | **String** |  | [optional][default to &#39;POST&#39;] |
| **url** | **String** |  |  |
| **headers** | [**Array&lt;HttpHeader&gt;**](HttpHeader.md) |  | [optional] |
| **body** | **String** |  | [optional] |
| **success_status** | [**SuccessStatus**](SuccessStatus.md) |  | [optional] |

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

