# SmplkitGeneratedClient::Audit::EventsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_event**](EventsApi.md#get_event) | **GET** /api/v1/events/{event_id} | Get Event |
| [**list_events**](EventsApi.md#list_events) | **GET** /api/v1/events | List Events |
| [**record_event**](EventsApi.md#record_event) | **POST** /api/v1/events | Record Event |


## get_event

> <EventResponse> get_event(event_id)

Get Event

Retrieve a single audit event by id.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::EventsApi.new
event_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get Event
  result = api_instance.get_event(event_id)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->get_event: #{e}"
end
```

#### Using the get_event_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EventResponse>, Integer, Hash)> get_event_with_http_info(event_id)

```ruby
begin
  # Get Event
  data, status_code, headers = api_instance.get_event_with_http_info(event_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EventResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->get_event_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **event_id** | **String** |  |  |

### Return type

[**EventResponse**](EventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_events

> <EventListResponse> list_events(opts)

List Events

List audit events for this account.  Default sort is `-occurred_at` (newest occurrence first). Sort by `occurred_at` or `created_at`, ascending or descending — keep the same `sort` value across paginated requests so the cursor stays consistent. Filters are exact-match except `filter[occurred_at]`, which uses interval notation (e.g. `[2026-01-01T00:00:00Z,2026-01-31T00:00:00Z)`), and `filter[search]`, which is a case-insensitive substring match against `resource_id` or `description`.  Two filter-combination rules:  - `filter[resource_id]` must be accompanied by `filter[resource_type]`   (the index is keyed on the pair). - `filter[search]` must be accompanied by either `filter[occurred_at]`   or `filter[resource_type]` + `filter[resource_id]` (substring   matching has no index, so an unbounded substring scan is rejected).  No other filter combinations are required — calling the endpoint with no query parameters returns the latest events for the account, paginated.  `page[size]` defaults to 1000 and must not exceed 1000.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::EventsApi.new
opts = {
  filter_occurred_at: 'filter_occurred_at_example', # String | 
  filter_actor_type: 'filter_actor_type_example', # String | 
  filter_actor_id: 'filter_actor_id_example', # String | 
  filter_event_type: 'filter_event_type_example', # String | 
  filter_resource_type: 'filter_resource_type_example', # String | 
  filter_resource_id: 'filter_resource_id_example', # String | 
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against `resource_id` or `description`. Use `filter[resource_id]` for an exact match on `resource_id`.
  filter_do_not_forward: true, # Boolean | When set, restrict to events whose `do_not_forward` flag matches the given boolean. Forwarder previews typically pass `false` to match live-pipeline semantics (events flagged `do_not_forward=true` are skipped by the forwarder pipeline).
  page_size: 56, # Integer | 
  page_after: 'page_after_example', # String | 
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `-occurred_at`. Allowed values: `created_at`, `-created_at`, `occurred_at`, `-occurred_at`.
}

begin
  # List Events
  result = api_instance.list_events(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->list_events: #{e}"
end
```

#### Using the list_events_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EventListResponse>, Integer, Hash)> list_events_with_http_info(opts)

```ruby
begin
  # List Events
  data, status_code, headers = api_instance.list_events_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EventListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->list_events_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_occurred_at** | **String** |  | [optional] |
| **filter_actor_type** | **String** |  | [optional] |
| **filter_actor_id** | **String** |  | [optional] |
| **filter_event_type** | **String** |  | [optional] |
| **filter_resource_type** | **String** |  | [optional] |
| **filter_resource_id** | **String** |  | [optional] |
| **filter_search** | **String** | Case-insensitive substring match against &#x60;resource_id&#x60; or &#x60;description&#x60;. Use &#x60;filter[resource_id]&#x60; for an exact match on &#x60;resource_id&#x60;. | [optional] |
| **filter_do_not_forward** | **Boolean** | When set, restrict to events whose &#x60;do_not_forward&#x60; flag matches the given boolean. Forwarder previews typically pass &#x60;false&#x60; to match live-pipeline semantics (events flagged &#x60;do_not_forward&#x3D;true&#x60; are skipped by the forwarder pipeline). | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-occurred_at&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;occurred_at&#x60;, &#x60;-occurred_at&#x60;. | [optional][default to &#39;-occurred_at&#39;] |

### Return type

[**EventListResponse**](EventListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## record_event

> <EventResponse> record_event(event_request, opts)

Record Event

Record an audit event for this account.  Returns `201 Created` on first write, `200 OK` if the request was a duplicate (matched by `Idempotency-Key` or a key derived from the event's content).  `resource_type` values beginning with `smpl.` are reserved for events that smplkit emits about its own resources and cannot be used here.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::EventsApi.new
event_request = SmplkitGeneratedClient::Audit::EventRequest.new({data: SmplkitGeneratedClient::Audit::EventResource.new({attributes: SmplkitGeneratedClient::Audit::Event.new({event_type: 'event_type_example', resource_type: 'resource_type_example', resource_id: 'resource_id_example'})})}) # EventRequest | 
opts = {
  idempotency_key: 'idempotency_key_example' # String | 
}

begin
  # Record Event
  result = api_instance.record_event(event_request, opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->record_event: #{e}"
end
```

#### Using the record_event_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EventResponse>, Integer, Hash)> record_event_with_http_info(event_request, opts)

```ruby
begin
  # Record Event
  data, status_code, headers = api_instance.record_event_with_http_info(event_request, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EventResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->record_event_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **event_request** | [**EventRequest**](EventRequest.md) |  |  |
| **idempotency_key** | **String** |  | [optional] |

### Return type

[**EventResponse**](EventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

