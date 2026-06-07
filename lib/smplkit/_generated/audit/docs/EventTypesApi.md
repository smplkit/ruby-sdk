# SmplkitGeneratedClient::Audit::EventTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_event_types**](EventTypesApi.md#list_event_types) | **GET** /api/v1/event_types | List Event Types |


## list_event_types

> <EventTypeListResponse> list_event_types(opts)

List Event Types

List the distinct `event_type` slugs recorded for this account.  Default sort is `key` ascending; pass `sort=-key` for descending. Scoped to the selected environments (see `filter[environment]`). Without `filter[resource_type]`, returns one row per distinct event_type. With `filter[resource_type]`, returns the event_types recorded for that specific resource type.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::EventTypesApi.new
opts = {
  filter_environment: 'filter_environment_example', # String | Comma-separated list of environment keys to scope results to (e.g. `production,staging`). When omitted, results are scoped to your single accessible environment; send the `X-Smplkit-Environment` header instead if you can access more than one. The reserved value `smplkit` selects platform change events that smplkit records about your own resources (flags, configuration, and so on); these are not tied to a deployment environment and are readable regardless of which environments you manage.
  filter_resource_type: 'filter_resource_type_example', # String | 
  sort: 'key', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `key`, `-key`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Event Types
  result = api_instance.list_event_types(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventTypesApi->list_event_types: #{e}"
end
```

#### Using the list_event_types_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EventTypeListResponse>, Integer, Hash)> list_event_types_with_http_info(opts)

```ruby
begin
  # List Event Types
  data, status_code, headers = api_instance.list_event_types_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EventTypeListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling EventTypesApi->list_event_types_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_environment** | **String** | Comma-separated list of environment keys to scope results to (e.g. &#x60;production,staging&#x60;). When omitted, results are scoped to your single accessible environment; send the &#x60;X-Smplkit-Environment&#x60; header instead if you can access more than one. The reserved value &#x60;smplkit&#x60; selects platform change events that smplkit records about your own resources (flags, configuration, and so on); these are not tied to a deployment environment and are readable regardless of which environments you manage. | [optional] |
| **filter_resource_type** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;key&#x60;, &#x60;-key&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**EventTypeListResponse**](EventTypeListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

