# SmplkitGeneratedClient::Audit::ResourceTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_resource_types**](ResourceTypesApi.md#list_resource_types) | **GET** /api/v1/resource_types | List Resource Types |


## list_resource_types

> <ResourceTypeListResponse> list_resource_types(opts)

List Resource Types

List the distinct `resource_type` slugs recorded for this account.  The resource `id` is the slug itself. Default sort is `key` ascending; pass `sort=-key` for descending. Useful for populating filter dropdowns in a UI. Results are scoped to the selected environments (see `filter[environment]`); platform resource types appear under the reserved `smplkit` value.

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
  filter_environment: 'filter_environment_example', # String | Comma-separated list of environment keys to scope results to (e.g. `production,staging`). When omitted, results are scoped to your single accessible environment; send the `X-Smplkit-Environment` header instead if you can access more than one. The reserved value `smplkit` selects platform change events that smplkit records about your own resources (flags, configuration, and so on); these are not tied to a deployment environment and are readable regardless of which environments you manage.
  sort: 'key', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `key`, `-key`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
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
| **filter_environment** | **String** | Comma-separated list of environment keys to scope results to (e.g. &#x60;production,staging&#x60;). When omitted, results are scoped to your single accessible environment; send the &#x60;X-Smplkit-Environment&#x60; header instead if you can access more than one. The reserved value &#x60;smplkit&#x60; selects platform change events that smplkit records about your own resources (flags, configuration, and so on); these are not tied to a deployment environment and are readable regardless of which environments you manage. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;key&#x60;, &#x60;-key&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**ResourceTypeListResponse**](ResourceTypeListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

