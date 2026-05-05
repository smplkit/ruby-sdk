# SmplkitGeneratedClient::Logging::LoggersApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk_register_loggers**](LoggersApi.md#bulk_register_loggers) | **POST** /api/v1/loggers/bulk | Bulk Register Loggers |
| [**delete_logger**](LoggersApi.md#delete_logger) | **DELETE** /api/v1/loggers/{id} | Delete Logger |
| [**get_logger**](LoggersApi.md#get_logger) | **GET** /api/v1/loggers/{id} | Get Logger |
| [**list_loggers**](LoggersApi.md#list_loggers) | **GET** /api/v1/loggers | List Loggers |
| [**update_logger**](LoggersApi.md#update_logger) | **PUT** /api/v1/loggers/{id} | Update or Create Logger |


## bulk_register_loggers

> <LoggerBulkResponse> bulk_register_loggers(logger_bulk_request)

Bulk Register Loggers

Register loggers discovered by an SDK. Creates new loggers or updates source observations on existing ones.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggersApi.new
logger_bulk_request = SmplkitGeneratedClient::Logging::LoggerBulkRequest.new({loggers: [SmplkitGeneratedClient::Logging::LoggerBulkItem.new({id: 'id_example'})]}) # LoggerBulkRequest | 

begin
  # Bulk Register Loggers
  result = api_instance.bulk_register_loggers(logger_bulk_request)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->bulk_register_loggers: #{e}"
end
```

#### Using the bulk_register_loggers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerBulkResponse>, Integer, Hash)> bulk_register_loggers_with_http_info(logger_bulk_request)

```ruby
begin
  # Bulk Register Loggers
  data, status_code, headers = api_instance.bulk_register_loggers_with_http_info(logger_bulk_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerBulkResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->bulk_register_loggers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **logger_bulk_request** | [**LoggerBulkRequest**](LoggerBulkRequest.md) |  |  |

### Return type

[**LoggerBulkResponse**](LoggerBulkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_logger

> delete_logger(id)

Delete Logger

Delete a logger by its key.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggersApi.new
id = 'id_example' # String | 

begin
  # Delete Logger
  api_instance.delete_logger(id)
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->delete_logger: #{e}"
end
```

#### Using the delete_logger_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_logger_with_http_info(id)

```ruby
begin
  # Delete Logger
  data, status_code, headers = api_instance.delete_logger_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->delete_logger_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_logger

> <LoggerResponse> get_logger(id)

Get Logger

Return a logger by its key.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggersApi.new
id = 'id_example' # String | 

begin
  # Get Logger
  result = api_instance.get_logger(id)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->get_logger: #{e}"
end
```

#### Using the get_logger_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerResponse>, Integer, Hash)> get_logger_with_http_info(id)

```ruby
begin
  # Get Logger
  data, status_code, headers = api_instance.get_logger_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->get_logger_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**LoggerResponse**](LoggerResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_loggers

> <LoggerListResponse> list_loggers(opts)

List Loggers

List all loggers for the authenticated account. Optionally filter by managed status, service, or last-seen time window.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggersApi.new
opts = {
  filter_managed: true, # Boolean | 
  filter_service: 'filter_service_example', # String | 
  filter_last_seen: 'filter_last_seen_example' # String | 
}

begin
  # List Loggers
  result = api_instance.list_loggers(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->list_loggers: #{e}"
end
```

#### Using the list_loggers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerListResponse>, Integer, Hash)> list_loggers_with_http_info(opts)

```ruby
begin
  # List Loggers
  data, status_code, headers = api_instance.list_loggers_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->list_loggers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_managed** | **Boolean** |  | [optional] |
| **filter_service** | **String** |  | [optional] |
| **filter_last_seen** | **String** |  | [optional] |

### Return type

[**LoggerListResponse**](LoggerListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_logger

> <LoggerResponse> update_logger(id, logger_response)

Update or Create Logger

Create or update a logger (upsert). If the logger does not exist it is created. Fields absent from the body are preserved on update; explicit null clears them.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LoggersApi.new
id = 'id_example' # String | 
logger_response = SmplkitGeneratedClient::Logging::LoggerResponse.new({data: SmplkitGeneratedClient::Logging::LoggerResource.new({type: 'logger', attributes: SmplkitGeneratedClient::Logging::Logger.new({name: 'name_example'})})}) # LoggerResponse | 

begin
  # Update or Create Logger
  result = api_instance.update_logger(id, logger_response)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->update_logger: #{e}"
end
```

#### Using the update_logger_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerResponse>, Integer, Hash)> update_logger_with_http_info(id, logger_response)

```ruby
begin
  # Update or Create Logger
  data, status_code, headers = api_instance.update_logger_with_http_info(id, logger_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LoggerResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->update_logger_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **logger_response** | [**LoggerResponse**](LoggerResponse.md) |  |  |

### Return type

[**LoggerResponse**](LoggerResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

