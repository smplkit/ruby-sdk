# SmplkitGeneratedClient::Audit::RetryFailedDeliveriesSummary

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **attempted** | **Integer** | Number of failed deliveries that were re-attempted. |  |
| **succeeded** | **Integer** | Number of re-attempts that succeeded. |  |
| **failed** | **Integer** | Number of re-attempts that failed again. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::RetryFailedDeliveriesSummary.new(
  attempted: null,
  succeeded: null,
  failed: null
)
```

