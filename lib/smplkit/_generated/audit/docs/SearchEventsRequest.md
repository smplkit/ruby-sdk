# SmplkitGeneratedClient::Audit::SearchEventsRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter** | **Hash&lt;String, Object&gt;** | The HTTP request as it was sent to the destination. Header values are redacted. | [optional] |
| **filter_action** | **String** | Exact match on the event&#39;s &#x60;action&#x60; field. | [optional] |
| **filter_resource_type** | **String** | Exact match on the event&#39;s &#x60;resource_type&#x60; field. | [optional] |
| **filter_resource_id** | **String** | Exact match on the event&#39;s &#x60;resource_id&#x60; field. Must be accompanied by &#x60;filter[resource_type]&#x60;. | [optional] |
| **filter_actor_type** | **String** | Exact match on the event&#39;s &#x60;actor_type&#x60; field. | [optional] |
| **filter_actor_id** | **String** | Exact match on the event&#39;s &#x60;actor_id&#x60; field. | [optional] |
| **filter_occurred_at** | **String** | Date range using interval notation, e.g. &#x60;[2026-04-01T00:00:00Z,2026-04-15T00:00:00Z)&#x60;. Required by &#x60;filter[search]&#x60; when the resource pair isn&#39;t provided. When a JSON Logic &#x60;filter&#x60; is present, the effective range is intersected with the last 30 days. | [optional] |
| **filter_search** | **String** | Case-insensitive substring match on &#x60;resource_id&#x60; or &#x60;description&#x60;. Must be accompanied by either &#x60;filter[occurred_at]&#x60; or &#x60;filter[resource_type]&#x60; + &#x60;filter[resource_id]&#x60;. | [optional] |
| **page_size** | **Integer** | Maximum events to return. Range 1..1000, default 10. The default is intentionally smaller than the list endpoint&#39;s default of 1000 because the search UI typically renders results one card at a time. | [optional][default to 10] |
| **page_after** | **String** | Opaque cursor — pass the previous response&#39;s &#x60;links.next&#x60; cursor verbatim to fetch the next page. Keep the same &#x60;sort&#x60; value across paginated requests. | [optional] |
| **sort** | **String** | Sort field: &#x60;occurred_at&#x60; or &#x60;created_at&#x60;, optionally prefixed with &#x60;-&#x60; for descending order. Default &#x60;-occurred_at&#x60; (newest first). | [optional][default to &#39;-occurred_at&#39;] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::SearchEventsRequest.new(
  filter: null,
  filter_action: null,
  filter_resource_type: null,
  filter_resource_id: null,
  filter_actor_type: null,
  filter_actor_id: null,
  filter_occurred_at: null,
  filter_search: null,
  page_size: null,
  page_after: null,
  sort: null
)
```

