# SmplkitGeneratedClient::Audit::RetryFailedDeliveriesRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **environment** | **String** | The single environment whose failed deliveries are re-attempted. Omit it and a single-environment credential implies it (a multi-environment credential must name it), and a named environment must be one the caller may access. The action always targets exactly one environment. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::RetryFailedDeliveriesRequest.new(
  environment: null
)
```

