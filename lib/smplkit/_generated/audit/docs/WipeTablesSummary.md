# SmplkitGeneratedClient::Audit::WipeTablesSummary

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **audit_event** | **Integer** | Number of audit events deleted. |  |
| **audit_event_quota** | **Integer** | Number of monthly usage-quota counters deleted. |  |
| **forwarder** | **Integer** | Number of forwarders deleted. |  |
| **forwarder_delivery** | **Integer** | Number of forwarder delivery log entries deleted. |  |
| **resource_type** | **Integer** | Number of distinct &#x60;resource_type&#x60; entries deleted. |  |
| **action** | **Integer** | Number of distinct &#x60;action&#x60; entries deleted. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::WipeTablesSummary.new(
  audit_event: null,
  audit_event_quota: null,
  forwarder: null,
  forwarder_delivery: null,
  resource_type: null,
  action: null
)
```

