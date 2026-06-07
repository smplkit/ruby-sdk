# SmplkitGeneratedClient::Audit::EventSearchRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter** | **Hash&lt;String, Object&gt;** | Optional JSON Logic expression evaluated against each row after column filters narrow the candidate set. Null, absent, or an empty object disables JSON Logic filtering. When present, the search is silently capped to the last 30 days by &#x60;occurred_at&#x60; (intersected with any explicit &#x60;filter[occurred_at]&#x60; the caller supplied). | [optional] |
| **filter_environment** | **String** | Comma-separated list of environment keys to scope results to (e.g. &#x60;production,staging&#x60;). When omitted, results are scoped to your single accessible environment; send the &#x60;X-Smplkit-Environment&#x60; header instead if you can access more than one. The reserved value &#x60;smplkit&#x60; selects platform change events that smplkit records about your own resources (flags, configuration, and so on); these are not tied to a deployment environment and are readable regardless of which environments you manage. | [optional] |
| **filter_event_type** | **String** | Exact match on the event&#39;s &#x60;event_type&#x60; field. | [optional] |
| **filter_resource_type** | **String** | Exact match on the event&#39;s &#x60;resource_type&#x60; field. | [optional] |
| **filter_resource_id** | **String** | Exact match on the event&#39;s &#x60;resource_id&#x60; field. Must be accompanied by &#x60;filter[resource_type]&#x60;. | [optional] |
| **filter_severity** | **String** | Exact match on the event&#39;s &#x60;severity&#x60; field. One of &#x60;TRACE&#x60;, &#x60;DEBUG&#x60;, &#x60;INFO&#x60;, &#x60;WARN&#x60;, &#x60;ERROR&#x60;, &#x60;FATAL&#x60;. | [optional] |
| **filter_category** | **String** | Exact match on the event&#39;s &#x60;category&#x60; field. | [optional] |
| **filter_actor_type** | **String** | Exact match on the event&#39;s &#x60;actor_type&#x60; field. | [optional] |
| **filter_actor_id** | **String** | Exact match on the event&#39;s &#x60;actor_id&#x60; field. | [optional] |
| **filter_occurred_at** | **String** | Date range using interval notation, e.g. &#x60;[2026-04-01T00:00:00Z,2026-04-15T00:00:00Z)&#x60;. Required by &#x60;filter[search]&#x60; when the resource pair isn&#39;t provided. When a JSON Logic &#x60;filter&#x60; is present, the effective range is intersected with the last 30 days. | [optional] |
| **filter_search** | **String** | Case-insensitive substring match on &#x60;resource_id&#x60; or &#x60;description&#x60;. Must be accompanied by either &#x60;filter[occurred_at]&#x60; or &#x60;filter[resource_type]&#x60; + &#x60;filter[resource_id]&#x60;. | [optional] |
| **filter_do_not_forward** | **Boolean** | When set, restrict to events whose &#x60;do_not_forward&#x60; flag matches the given boolean. Forwarder previews typically pass &#x60;false&#x60; to match live-pipeline semantics (events flagged &#x60;do_not_forward&#x3D;true&#x60; are skipped by the forwarder pipeline). | [optional] |
| **page_size** | **Integer** | Maximum events to return. Range 1..1000, default 1000 — matches every other list / search endpoint on the platform. Set explicitly to a smaller value when the consumer is rendering results card-by-card. | [optional][default to 1000] |
| **page_after** | **String** | Opaque cursor — pass the previous response&#39;s &#x60;links.next&#x60; cursor verbatim to fetch the next page. Keep the same &#x60;sort&#x60; value across paginated requests. | [optional] |
| **sort** | **String** | Sort field: &#x60;occurred_at&#x60; or &#x60;created_at&#x60;, optionally prefixed with &#x60;-&#x60; for descending order. Default &#x60;-occurred_at&#x60; (newest first). | [optional][default to &#39;-occurred_at&#39;] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::EventSearchRequest.new(
  filter: null,
  filter_environment: null,
  filter_event_type: null,
  filter_resource_type: null,
  filter_resource_id: null,
  filter_severity: null,
  filter_category: null,
  filter_actor_type: null,
  filter_actor_id: null,
  filter_occurred_at: null,
  filter_search: null,
  filter_do_not_forward: null,
  page_size: null,
  page_after: null,
  sort: null
)
```

