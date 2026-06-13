# SmplkitGeneratedClient::Audit::Event

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **event_type** | **String** | What happened, e.g. &#x60;user.created&#x60;. Any non-empty string. |  |
| **resource_type** | **String** | Kind of resource the event is about, e.g. &#x60;user&#x60;. Any non-empty string. |  |
| **resource_id** | **String** | Identifier of the specific resource the event is about. |  |
| **description** | **String** | Free-text description of the event. Included alongside &#x60;resource_id&#x60; in the &#x60;filter[search]&#x60; substring target. | [optional] |
| **severity** | [**Severity**](Severity.md) | One of &#x60;TRACE&#x60;, &#x60;DEBUG&#x60;, &#x60;INFO&#x60;, &#x60;WARN&#x60;, &#x60;ERROR&#x60;, &#x60;FATAL&#x60;. Omit to record the event at &#x60;INFO&#x60;. Always present on read. | [optional] |
| **category** | **String** | Free-form bucket label, e.g. &#x60;auth&#x60;, &#x60;billing&#x60;, &#x60;config-change&#x60;. Stored exactly as supplied. Drives the &#x60;filter[category]&#x60; filter and the &#x60;GET /api/v1/categories&#x60; discovery endpoint. | [optional] |
| **occurred_at** | **Time** | When the event actually happened. Defaults to the server receipt time (&#x60;created_at&#x60;). | [optional] |
| **actor_type** | **String** | Kind of actor that caused the event, e.g. &#x60;USER&#x60;, &#x60;API_KEY&#x60;, &#x60;SYSTEM&#x60;, or any other label you choose. Free-form string; the API does not constrain or interpret it. | [optional] |
| **actor_id** | **String** | Identifier of the actor that caused the event. Free-form string — any identifier scheme is accepted. | [optional] |
| **actor_label** | **String** | Human-readable label for the actor (e.g. an email address or API key name) at the time the event was recorded. | [optional] |
| **data** | **Hash&lt;String, Object&gt;** | Free-form payload attached to the event. Use it for resource snapshots (by convention under &#x60;data.snapshot&#x60;), request identifiers, or any other context the event needs to carry. | [optional] |
| **do_not_forward** | **Boolean** | When &#x60;true&#x60;, the event is recorded but not delivered to any forwarder, and no delivery log entries are created for it. | [optional][default to false] |
| **environment** | **String** | The environment the event occurred in. On write, optionally names the target environment: omit it and a single-environment credential implies it (a multi-environment credential must name it), and a named environment must be one the caller may access. Always present on read as the resolved environment. The same content recorded in two environments produces two distinct events. | [optional] |
| **created_at** | **Time** | When the event was received and recorded. | [optional][readonly] |
| **idempotency_key** | **String** | The idempotency key used to deduplicate the record. Echoes the &#x60;Idempotency-Key&#x60; header if one was supplied, otherwise a key derived from the event&#39;s content. | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Event.new(
  event_type: null,
  resource_type: null,
  resource_id: null,
  description: null,
  severity: null,
  category: null,
  occurred_at: null,
  actor_type: null,
  actor_id: null,
  actor_label: null,
  data: null,
  do_not_forward: null,
  environment: null,
  created_at: null,
  idempotency_key: null
)
```

