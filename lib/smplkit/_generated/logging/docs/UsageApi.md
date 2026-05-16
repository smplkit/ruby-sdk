# SmplkitGeneratedClient::Logging::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_logging_usage**](UsageApi.md#list_logging_usage) | **GET** /api/v1/usage | List Logging Usage |


## list_logging_usage

> <UsageListResponse> list_logging_usage(opts)

List Logging Usage

Report the current-period usage counters for this account.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::UsageApi.new
opts = {
  filter_period: 'filter_period_example', # String | 
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Logging Usage
  result = api_instance.list_logging_usage(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling UsageApi->list_logging_usage: #{e}"
end
```

#### Using the list_logging_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageListResponse>, Integer, Hash)> list_logging_usage_with_http_info(opts)

```ruby
begin
  # List Logging Usage
  data, status_code, headers = api_instance.list_logging_usage_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling UsageApi->list_logging_usage_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_period** | **String** |  | [optional] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**UsageListResponse**](UsageListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

