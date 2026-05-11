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

Retrieve a single audit event by id.  Returns 404 if no event with that id exists in the caller's account — RLS enforces tenant isolation; this endpoint never leaks the existence of another tenant's event.

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

List audit events for the authenticated account.  Default sort is ``-created_at``; cursor pagination via ``page[after]`` (the opaque cursor returned in ``links.next``). Filters are exact-match except ``filter[occurred_at]`` which uses the platform's range notation (``[2026-01-01T00:00:00Z,*)``) and ``filter[search]`` which is a case-insensitive substring match (per ADR-014; targets ``resource_id`` only at this revision).

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
  filter_actor_id: '38400000-8cf0-11bd-b23e-10b96e4ef00d', # String | 
  filter_action: 'filter_action_example', # String | 
  filter_resource_type: 'filter_resource_type_example', # String | 
  filter_resource_id: 'filter_resource_id_example', # String | 
  filter_search: 'filter_search_example', # String | Case-insensitive substring match. Searches against ``resource_id`` only — see ADR-014 for the platform-wide ``filter[search]`` convention. Use ``filter[resource_id]`` for an exact match.
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
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
| **filter_action** | **String** |  | [optional] |
| **filter_resource_type** | **String** |  | [optional] |
| **filter_resource_id** | **String** |  | [optional] |
| **filter_search** | **String** | Case-insensitive substring match. Searches against &#x60;&#x60;resource_id&#x60;&#x60; only — see ADR-014 for the platform-wide &#x60;&#x60;filter[search]&#x60;&#x60; convention. Use &#x60;&#x60;filter[resource_id]&#x60;&#x60; for an exact match. | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

### Return type

[**EventListResponse**](EventListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## record_event

> <EventResponse> record_event(event_response, opts)

Record Event

Record an audit event for the authenticated account.  Returns ``201 Created`` on first write, ``200 OK`` if the request was a duplicate (matched by ``Idempotency-Key`` or auto-derived key).  Customers may not emit events whose ``resource_type`` starts with ``smpl.`` — that namespace is reserved for smplkit-emitted events about platform resources.

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
event_response = SmplkitGeneratedClient::Audit::EventResponse.new({data: SmplkitGeneratedClient::Audit::EventResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Audit::Event.new({action: 'action_example', resource_type: 'resource_type_example', resource_id: 'resource_id_example'})})}) # EventResponse | 
opts = {
  idempotency_key: 'idempotency_key_example' # String | 
}

begin
  # Record Event
  result = api_instance.record_event(event_response, opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventsApi->record_event: #{e}"
end
```

#### Using the record_event_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EventResponse>, Integer, Hash)> record_event_with_http_info(event_response, opts)

```ruby
begin
  # Record Event
  data, status_code, headers = api_instance.record_event_with_http_info(event_response, opts)
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
| **event_response** | [**EventResponse**](EventResponse.md) |  |  |
| **idempotency_key** | **String** |  | [optional] |

### Return type

[**EventResponse**](EventResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

