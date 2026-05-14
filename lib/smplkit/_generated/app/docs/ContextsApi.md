# SmplkitGeneratedClient::App::ContextsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk_register_contexts**](ContextsApi.md#bulk_register_contexts) | **POST** /api/v1/contexts/bulk | Bulk Register Contexts |
| [**delete_context**](ContextsApi.md#delete_context) | **DELETE** /api/v1/contexts/{id} | Delete Context |
| [**get_context**](ContextsApi.md#get_context) | **GET** /api/v1/contexts/{id} | Get Context |
| [**list_contexts**](ContextsApi.md#list_contexts) | **GET** /api/v1/contexts | List Contexts |
| [**update_context**](ContextsApi.md#update_context) | **PUT** /api/v1/contexts/{id} | Update Context |


## bulk_register_contexts

> <ContextBatchResponse> bulk_register_contexts(context_bulk_register)

Bulk Register Contexts

Register context instances in bulk. Creates context types automatically if they don't exist.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextsApi.new
context_bulk_register = SmplkitGeneratedClient::App::ContextBulkRegister.new({contexts: [SmplkitGeneratedClient::App::ContextBulkItem.new({type: 'type_example', key: 'key_example'})]}) # ContextBulkRegister | 

begin
  # Bulk Register Contexts
  result = api_instance.bulk_register_contexts(context_bulk_register)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->bulk_register_contexts: #{e}"
end
```

#### Using the bulk_register_contexts_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextBatchResponse>, Integer, Hash)> bulk_register_contexts_with_http_info(context_bulk_register)

```ruby
begin
  # Bulk Register Contexts
  data, status_code, headers = api_instance.bulk_register_contexts_with_http_info(context_bulk_register)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextBatchResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->bulk_register_contexts_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **context_bulk_register** | [**ContextBulkRegister**](ContextBulkRegister.md) |  |  |

### Return type

[**ContextBatchResponse**](ContextBatchResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_context

> delete_context(id)

Delete Context

Delete a context instance by composite id (type:key).

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextsApi.new
id = 'id_example' # String | 

begin
  # Delete Context
  api_instance.delete_context(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->delete_context: #{e}"
end
```

#### Using the delete_context_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_context_with_http_info(id)

```ruby
begin
  # Delete Context
  data, status_code, headers = api_instance.delete_context_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->delete_context_with_http_info: #{e}"
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


## get_context

> <ContextResponse> get_context(id)

Get Context

Return a context instance by composite id (type:key).

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextsApi.new
id = 'id_example' # String | 

begin
  # Get Context
  result = api_instance.get_context(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->get_context: #{e}"
end
```

#### Using the get_context_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextResponse>, Integer, Hash)> get_context_with_http_info(id)

```ruby
begin
  # Get Context
  data, status_code, headers = api_instance.get_context_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->get_context_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ContextResponse**](ContextResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_contexts

> <ContextListResponse> list_contexts(opts)

List Contexts

List all context instances for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextsApi.new
opts = {
  filter_context_type: 'filter_context_type_example', # String | 
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
}

begin
  # List Contexts
  result = api_instance.list_contexts(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->list_contexts: #{e}"
end
```

#### Using the list_contexts_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextListResponse>, Integer, Hash)> list_contexts_with_http_info(opts)

```ruby
begin
  # List Contexts
  data, status_code, headers = api_instance.list_contexts_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->list_contexts_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_context_type** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;key&#39;] |

### Return type

[**ContextListResponse**](ContextListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_context

> <ContextResponse> update_context(id, context_request)

Update Context

Update a context instance by composite id (type:key). Only the human-readable display name is mutable here; `context_type` and observed `attributes` are written by SDK registration and ignored on this endpoint.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextsApi.new
id = 'id_example' # String | 
context_request = SmplkitGeneratedClient::App::ContextRequest.new({data: SmplkitGeneratedClient::App::ContextResource.new({type: 'context', attributes: SmplkitGeneratedClient::App::Context.new({context_type: 'context_type_example'})})}) # ContextRequest | 

begin
  # Update Context
  result = api_instance.update_context(id, context_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->update_context: #{e}"
end
```

#### Using the update_context_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextResponse>, Integer, Hash)> update_context_with_http_info(id, context_request)

```ruby
begin
  # Update Context
  data, status_code, headers = api_instance.update_context_with_http_info(id, context_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextsApi->update_context_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **context_request** | [**ContextRequest**](ContextRequest.md) |  |  |

### Return type

[**ContextResponse**](ContextResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

