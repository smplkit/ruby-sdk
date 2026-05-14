# SmplkitGeneratedClient::Flags::FlagSourcesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_all_flag_sources**](FlagSourcesApi.md#list_all_flag_sources) | **GET** /api/v1/flag_sources | List All Flag Sources |
| [**list_flag_sources**](FlagSourcesApi.md#list_flag_sources) | **GET** /api/v1/flags/{id}/sources | List Flag Sources |


## list_all_flag_sources

> <FlagSourceListResponse> list_all_flag_sources(opts)

List All Flag Sources

List service/environment observations across all flags for this account.  Default sort is `-last_seen` (most recently seen first). Filter by `environment` or `service` (or both) to narrow the result.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagSourcesApi.new
opts = {
  filter_environment: 'filter_environment_example', # String | 
  filter_service: 'filter_service_example', # String | 
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `-last_seen`. Allowed values: `created_at`, `-created_at`, `environment`, `-environment`, `last_seen`, `-last_seen`, `service`, `-service`.
}

begin
  # List All Flag Sources
  result = api_instance.list_all_flag_sources(opts)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagSourcesApi->list_all_flag_sources: #{e}"
end
```

#### Using the list_all_flag_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagSourceListResponse>, Integer, Hash)> list_all_flag_sources_with_http_info(opts)

```ruby
begin
  # List All Flag Sources
  data, status_code, headers = api_instance.list_all_flag_sources_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagSourceListResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagSourcesApi->list_all_flag_sources_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_environment** | **String** |  | [optional] |
| **filter_service** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-last_seen&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;environment&#x60;, &#x60;-environment&#x60;, &#x60;last_seen&#x60;, &#x60;-last_seen&#x60;, &#x60;service&#x60;, &#x60;-service&#x60;. | [optional][default to &#39;-last_seen&#39;] |

### Return type

[**FlagSourceListResponse**](FlagSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_flag_sources

> <FlagSourceListResponse> list_flag_sources(id, opts)

List Flag Sources

List the service/environment observations recorded for a single flag.  Default sort is `-last_seen` (most recently seen first).

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagSourcesApi.new
id = 'id_example' # String | 
opts = {
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `-last_seen`. Allowed values: `created_at`, `-created_at`, `environment`, `-environment`, `last_seen`, `-last_seen`, `service`, `-service`.
}

begin
  # List Flag Sources
  result = api_instance.list_flag_sources(id, opts)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagSourcesApi->list_flag_sources: #{e}"
end
```

#### Using the list_flag_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagSourceListResponse>, Integer, Hash)> list_flag_sources_with_http_info(id, opts)

```ruby
begin
  # List Flag Sources
  data, status_code, headers = api_instance.list_flag_sources_with_http_info(id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagSourceListResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagSourcesApi->list_flag_sources_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-last_seen&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;environment&#x60;, &#x60;-environment&#x60;, &#x60;last_seen&#x60;, &#x60;-last_seen&#x60;, &#x60;service&#x60;, &#x60;-service&#x60;. | [optional][default to &#39;-last_seen&#39;] |

### Return type

[**FlagSourceListResponse**](FlagSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

