# SmplkitGeneratedClient::Audit::ResourceTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_resource_types**](ResourceTypesApi.md#list_resource_types) | **GET** /api/v1/resource_types | List Resource Types |


## list_resource_types

> <ResourceTypeListResponse> list_resource_types(opts)

List Resource Types

List the distinct `resource_type` slugs recorded for this account.  The resource `id` is the slug itself. Default sort is `key` ascending; pass `sort=-key` for descending. Useful for populating filter dropdowns in a UI.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ResourceTypesApi.new
opts = {
  page_size: 56, # Integer | 
  page_after: 'page_after_example', # String | 
  sort: 'key' # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `key`, `-key`.
}

begin
  # List Resource Types
  result = api_instance.list_resource_types(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_resource_types: #{e}"
end
```

#### Using the list_resource_types_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ResourceTypeListResponse>, Integer, Hash)> list_resource_types_with_http_info(opts)

```ruby
begin
  # List Resource Types
  data, status_code, headers = api_instance.list_resource_types_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ResourceTypeListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_resource_types_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;key&#x60;, &#x60;-key&#x60;. | [optional][default to &#39;key&#39;] |

### Return type

[**ResourceTypeListResponse**](ResourceTypeListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

