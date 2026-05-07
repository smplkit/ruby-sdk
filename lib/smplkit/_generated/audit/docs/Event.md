# SmplkitGeneratedClient::Audit::Event

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **action** | **String** |  |  |
| **resource_type** | **String** |  |  |
| **resource_id** | **String** |  |  |
| **occurred_at** | **Time** |  | [optional] |
| **snapshot** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **data** | **Hash&lt;String, Object&gt;** |  | [optional] |
| **do_not_forward** | **Boolean** | When true, this event is recorded normally but is not forwarded to any configured SIEM forwarder. A forwarder_delivery row with status&#x3D;skipped_do_not_forward is recorded for each enabled forwarder so the skip is visible in the delivery log. | [optional][default to false] |
| **created_at** | **Time** |  | [optional][readonly] |
| **actor_type** | **String** |  | [optional][readonly] |
| **actor_id** | **String** |  | [optional][readonly] |
| **actor_label** | **String** |  | [optional][readonly] |
| **idempotency_key** | **String** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Event.new(
  action: null,
  resource_type: null,
  resource_id: null,
  occurred_at: null,
  snapshot: null,
  data: null,
  do_not_forward: null,
  created_at: null,
  actor_type: null,
  actor_id: null,
  actor_label: null,
  idempotency_key: null
)
```

