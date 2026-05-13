# SmplkitGeneratedClient::Audit::Event

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **action** | **String** | Slug for what happened, e.g. &#x60;user.created&#x60;. Lowercase, dot-separated. |  |
| **resource_type** | **String** | Slug for the kind of resource the event is about, e.g. &#x60;user&#x60;. Lowercase, dot-separated. |  |
| **resource_id** | **String** | Identifier of the specific resource the event is about. |  |
| **description** | **String** | Free-text description of the event. Included alongside &#x60;resource_id&#x60; in the &#x60;filter[search]&#x60; substring target. | [optional] |
| **occurred_at** | **Time** | When the event actually happened. Defaults to the server receipt time (&#x60;created_at&#x60;). | [optional] |
| **data** | **Hash&lt;String, Object&gt;** | Free-form payload attached to the event. Use it for resource snapshots (by convention under &#x60;data.snapshot&#x60;), request identifiers, or any other context the event needs to carry. | [optional] |
| **do_not_forward** | **Boolean** | When &#x60;true&#x60;, the event is recorded but not delivered to any forwarder. A delivery log entry with status &#x60;SKIPPED_DO_NOT_FORWARD&#x60; is written for each enabled forwarder so the skip is visible in the delivery log. | [optional][default to false] |
| **created_at** | **Time** | When the event was received and recorded. | [optional][readonly] |
| **actor_type** | **String** | Kind of credential that emitted the event, e.g. &#x60;USER&#x60; or &#x60;API_KEY&#x60;. Resolved server-side from the request credential. | [optional][readonly] |
| **actor_id** | **String** | Identifier of the actor that emitted the event. | [optional][readonly] |
| **actor_label** | **String** | Human-readable label for the actor (e.g. the user&#39;s email address or the API key name) at the time the event was recorded. | [optional][readonly] |
| **idempotency_key** | **String** | The idempotency key used to deduplicate the record. Echoes the &#x60;Idempotency-Key&#x60; header if one was supplied, otherwise a key derived from the event&#39;s content. | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Event.new(
  action: null,
  resource_type: null,
  resource_id: null,
  description: null,
  occurred_at: null,
  data: null,
  do_not_forward: null,
  created_at: null,
  actor_type: null,
  actor_id: null,
  actor_label: null,
  idempotency_key: null
)
```

