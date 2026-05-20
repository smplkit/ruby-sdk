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

Register loggers discovered by an SDK.  Creates new logger entries for previously unseen keys and refreshes the per-(service, environment) observation for keys already known. Returns the number of items processed.

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

Delete a logger.

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

Retrieve a logger by its key.

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

List loggers for this account.  Default sort is `key` ascending. Supports `filter[managed]` to narrow to managed (or unmanaged) loggers, `filter[service]` to keep only loggers observed in a specific service, `filter[last_seen]` (interval notation `[<from>,*)`) to keep only loggers with a source observation at or after the given timestamp, and `filter[search]` for a case-insensitive substring match against `key` or `name`.  ``filter[service]`` and ``filter[last_seen]`` are applied via a cross-table membership check in Python after the SQL fetch, so pagination for those calls is applied in memory after the filter; the common path (no source-bound filter) paginates at the SQL level.

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
  filter_last_seen: 'filter_last_seen_example', # String | 
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against the logger `key` and `name`. A logger is returned if either field contains the search term.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
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
| **filter_search** | **String** | Case-insensitive substring match against the logger &#x60;key&#x60; and &#x60;name&#x60;. A logger is returned if either field contains the search term. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**LoggerListResponse**](LoggerListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_logger

> <LoggerResponse> update_logger(id, logger_request)

Update or Create Logger

Create or replace a logger at the given key.  If the logger does not yet exist, it is created. Fields omitted from the request body are preserved; explicit `null` clears them. Setting `level`, `group`, or `environments` on an unmanaged logger promotes it to managed automatically.

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
logger_request = SmplkitGeneratedClient::Logging::LoggerRequest.new({data: SmplkitGeneratedClient::Logging::LoggerResource.new({type: 'logger', attributes: SmplkitGeneratedClient::Logging::Logger.new({name: 'name_example'})})}) # LoggerRequest | 

begin
  # Update or Create Logger
  result = api_instance.update_logger(id, logger_request)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LoggersApi->update_logger: #{e}"
end
```

#### Using the update_logger_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LoggerResponse>, Integer, Hash)> update_logger_with_http_info(id, logger_request)

```ruby
begin
  # Update or Create Logger
  data, status_code, headers = api_instance.update_logger_with_http_info(id, logger_request)
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
| **logger_request** | [**LoggerRequest**](LoggerRequest.md) |  |  |

### Return type

[**LoggerResponse**](LoggerResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

