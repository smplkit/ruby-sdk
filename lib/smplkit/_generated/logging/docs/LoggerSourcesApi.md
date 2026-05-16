# SmplkitGeneratedClient::Logging::LoggerSourcesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_all_logger_sources**](LoggerSourcesApi.md#list_all_logger_sources) | **GET** /api/v1/logger_sources | List All Logger Sources |
| [**list_logger_sources**](LoggerSourcesApi.md#list_logger_sources) | **GET** /api/v1/loggers/{id}/sources | List Logger Sources |


## list_all_logger_sources

> <LoggerSourceListResponse> list_all_logger_sources(opts)

List All Logger Sources

List every logger source observation for this account.  Default sort is `-last_seen` (most recently observed first). Supports `filter[environment]` and `filter[service]` to narrow to a specific environment or service.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggerSourcesApi.new
opts = {
  filter_environment: 'filter_environment_example', # String | 
  filter_service: 'filter_service_example', # String | 
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `-last_seen`. Allowed values: `created_at`, `-created_at`, `environment`, `-environment`, `last_seen`, `-last_seen`, `service`, `-service`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List All Logger Sources
  result = api_instance.list_all_logger_sources(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggerSourcesApi->list_all_logger_sources: #{e}"
end
```

#### Using the list_all_logger_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerSourceListResponse>, Integer, Hash)> list_all_logger_sources_with_http_info(opts)

```ruby
begin
  # List All Logger Sources
  data, status_code, headers = api_instance.list_all_logger_sources_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerSourceListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggerSourcesApi->list_all_logger_sources_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_environment** | **String** |  | [optional] |
| **filter_service** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-last_seen&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;environment&#x60;, &#x60;-environment&#x60;, &#x60;last_seen&#x60;, &#x60;-last_seen&#x60;, &#x60;service&#x60;, &#x60;-service&#x60;. | [optional][default to &#39;-last_seen&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**LoggerSourceListResponse**](LoggerSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_logger_sources

> <LoggerSourceListResponse> list_logger_sources(id, opts)

List Logger Sources

List the service / environment observations recorded for a logger.  Default sort is `-last_seen` (most recently observed first).

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggerSourcesApi.new
id = 'id_example' # String | 
opts = {
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `-last_seen`. Allowed values: `created_at`, `-created_at`, `environment`, `-environment`, `last_seen`, `-last_seen`, `service`, `-service`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Logger Sources
  result = api_instance.list_logger_sources(id, opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggerSourcesApi->list_logger_sources: #{e}"
end
```

#### Using the list_logger_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerSourceListResponse>, Integer, Hash)> list_logger_sources_with_http_info(id, opts)

```ruby
begin
  # List Logger Sources
  data, status_code, headers = api_instance.list_logger_sources_with_http_info(id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerSourceListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggerSourcesApi->list_logger_sources_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-last_seen&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;environment&#x60;, &#x60;-environment&#x60;, &#x60;last_seen&#x60;, &#x60;-last_seen&#x60;, &#x60;service&#x60;, &#x60;-service&#x60;. | [optional][default to &#39;-last_seen&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**LoggerSourceListResponse**](LoggerSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

