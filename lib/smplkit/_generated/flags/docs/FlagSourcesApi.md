# SmplkitGeneratedClient::Flags::FlagSourcesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_all_flag_sources**](FlagSourcesApi.md#list_all_flag_sources) | **GET** /api/v1/flag_sources | List All Flag Sources |
| [**list_flag_sources**](FlagSourcesApi.md#list_flag_sources) | **GET** /api/v1/flags/{id}/sources | List Flag Sources |


## list_all_flag_sources

> <FlagSourceListResponse> list_all_flag_sources(opts)

List All Flag Sources

List all flag sources across all flags. Optionally filter by environment or service.

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
  filter_service: 'filter_service_example' # String | 
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

### Return type

[**FlagSourceListResponse**](FlagSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_flag_sources

> <FlagSourceListResponse> list_flag_sources(id)

List Flag Sources

List all sources (service/environment observations) for a specific flag.

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

begin
  # List Flag Sources
  result = api_instance.list_flag_sources(id)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagSourcesApi->list_flag_sources: #{e}"
end
```

#### Using the list_flag_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagSourceListResponse>, Integer, Hash)> list_flag_sources_with_http_info(id)

```ruby
begin
  # List Flag Sources
  data, status_code, headers = api_instance.list_flag_sources_with_http_info(id)
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

### Return type

[**FlagSourceListResponse**](FlagSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

