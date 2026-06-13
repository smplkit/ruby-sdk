# SmplkitGeneratedClient::Audit::Export

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **format** | **String** | Output format for the download. &#x60;CSV&#x60; writes one row per event with the event payload (&#x60;data&#x60;) serialized as a JSON-encoded cell. &#x60;JSONL&#x60; writes one JSON object per line with &#x60;data&#x60; preserved as a nested object. |  |
| **environment** | **String** | The single environment the export is scoped to. Omit it and a single-environment credential implies it (a multi-environment credential must name it), and a named environment must be one the caller may access. An export always covers exactly one environment. | [optional] |
| **filter_occurred_at** | **String** | Date range using interval notation, e.g. &#x60;[2026-04-01T00:00:00Z,2026-04-15T00:00:00Z)&#x60;. | [optional] |
| **filter_actor_type** | **String** | Exact match on the event&#39;s &#x60;actor_type&#x60; field. | [optional] |
| **filter_actor_id** | **String** | Exact match on the event&#39;s &#x60;actor_id&#x60; field. | [optional] |
| **filter_event_type** | **String** | Exact match on the event&#39;s &#x60;event_type&#x60; field. | [optional] |
| **filter_resource_type** | **String** | Exact match on the event&#39;s &#x60;resource_type&#x60; field. | [optional] |
| **filter_resource_id** | **String** | Exact match on the event&#39;s &#x60;resource_id&#x60; field. Must be accompanied by &#x60;filter[resource_type]&#x60;. | [optional] |
| **filter_search** | **String** | Case-insensitive substring match against &#x60;resource_id&#x60; or &#x60;description&#x60;. Must be accompanied by either &#x60;filter[occurred_at]&#x60; or &#x60;filter[resource_type]&#x60; + &#x60;filter[resource_id]&#x60;. | [optional] |
| **filter_do_not_forward** | **Boolean** | When set, restrict to events whose &#x60;do_not_forward&#x60; flag matches the given boolean. | [optional] |
| **url** | **String** | Absolute, signed download URL. Open in a browser to stream the export to disk. Expires shortly after mint — see &#x60;expires_at&#x60;. | [optional][readonly] |
| **expires_at** | **Time** | When the signed URL stops being valid (ISO-8601 UTC). Open the URL well before this time — the signed token is stateless, so a single mint cannot be &#39;refreshed&#39;; mint a new export if the URL has expired. | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Export.new(
  format: null,
  environment: null,
  filter_occurred_at: null,
  filter_actor_type: null,
  filter_actor_id: null,
  filter_event_type: null,
  filter_resource_type: null,
  filter_resource_id: null,
  filter_search: null,
  filter_do_not_forward: null,
  url: null,
  expires_at: null
)
```

