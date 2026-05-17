# SmplkitGeneratedClient::Audit::SearchApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**search_events**](SearchApi.md#search_events) | **POST** /api/v1/search/events | Search Events |


## search_events

> <SearchEventsResponse> search_events(search_events_request)

Search Events

Search audit events with column filters and an optional JSON Logic expression.  Without a JSON Logic `filter`: behaves like `GET /api/v1/events` with the same column filters.  With a JSON Logic `filter`: the search is silently capped to the last 30 days by `occurred_at` (intersected with any explicit `filter[occurred_at]` the caller supplied), the column filters narrow the candidate set in SQL, and the JSON Logic expression runs in memory against each candidate row using the same `json-logic-qubit` evaluator the forwarder pipeline uses. Up to 50,000 rows are scanned per request; the response's `meta.scan` block reports the scan stats so a selective filter doesn't look like \"0 matches\" when the truth is \"ceiling reached.\"

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::SearchApi.new
search_events_request = SmplkitGeneratedClient::Audit::SearchEventsRequest.new # SearchEventsRequest | 

begin
  # Search Events
  result = api_instance.search_events(search_events_request)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling SearchApi->search_events: #{e}"
end
```

#### Using the search_events_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SearchEventsResponse>, Integer, Hash)> search_events_with_http_info(search_events_request)

```ruby
begin
  # Search Events
  data, status_code, headers = api_instance.search_events_with_http_info(search_events_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SearchEventsResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling SearchApi->search_events_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **search_events_request** | [**SearchEventsRequest**](SearchEventsRequest.md) |  |  |

### Return type

[**SearchEventsResponse**](SearchEventsResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

