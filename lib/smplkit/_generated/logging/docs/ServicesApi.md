# SmplkitGeneratedClient::Logging::ServicesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_services**](ServicesApi.md#list_services) | **GET** /api/v1/services | List Services |


## list_services

> <ServiceListResponse> list_services(opts)

List Services

List the services that have reported a logger for this account.  Default sort is `name` ascending.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::ServicesApi.new
opts = {
  sort: 'name', # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `name`, `-name`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Services
  result = api_instance.list_services(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling ServicesApi->list_services: #{e}"
end
```

#### Using the list_services_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceListResponse>, Integer, Hash)> list_services_with_http_info(opts)

```ruby
begin
  # List Services
  data, status_code, headers = api_instance.list_services_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling ServicesApi->list_services_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;name&#x60;, &#x60;-name&#x60;. | [optional][default to &#39;name&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**ServiceListResponse**](ServiceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

