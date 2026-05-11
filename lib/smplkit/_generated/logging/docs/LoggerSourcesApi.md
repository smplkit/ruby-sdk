# SmplkitGeneratedClient::Logging::LoggerSourcesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_all_logger_sources**](LoggerSourcesApi.md#list_all_logger_sources) | **GET** /api/v1/logger_sources | List All Logger Sources |
| [**list_logger_sources**](LoggerSourcesApi.md#list_logger_sources) | **GET** /api/v1/loggers/{id}/sources | List Logger Sources |


## list_all_logger_sources

> <LoggerSourceListResponse> list_all_logger_sources(opts)

List All Logger Sources

List every logger source observation for this account.  Supports `filter[environment]` and `filter[service]` to narrow to a specific environment or service.

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
  filter_service: 'filter_service_example' # String | 
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

### Return type

[**LoggerSourceListResponse**](LoggerSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_logger_sources

> <LoggerSourceListResponse> list_logger_sources(id)

List Logger Sources

List the service / environment observations recorded for a logger.

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

begin
  # List Logger Sources
  result = api_instance.list_logger_sources(id)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggerSourcesApi->list_logger_sources: #{e}"
end
```

#### Using the list_logger_sources_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerSourceListResponse>, Integer, Hash)> list_logger_sources_with_http_info(id)

```ruby
begin
  # List Logger Sources
  data, status_code, headers = api_instance.list_logger_sources_with_http_info(id)
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

### Return type

[**LoggerSourceListResponse**](LoggerSourceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

