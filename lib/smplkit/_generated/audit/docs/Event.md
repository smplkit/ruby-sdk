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
  created_at: null,
  actor_type: null,
  actor_id: null,
  actor_label: null,
  idempotency_key: null
)
```

