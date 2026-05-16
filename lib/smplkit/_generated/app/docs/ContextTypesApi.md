# SmplkitGeneratedClient::App::ContextTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_context_type**](ContextTypesApi.md#create_context_type) | **POST** /api/v1/context_types | Create Context Type |
| [**delete_context_type**](ContextTypesApi.md#delete_context_type) | **DELETE** /api/v1/context_types/{id} | Delete Context Type |
| [**get_context_type**](ContextTypesApi.md#get_context_type) | **GET** /api/v1/context_types/{id} | Get Context Type |
| [**list_context_types**](ContextTypesApi.md#list_context_types) | **GET** /api/v1/context_types | List Context Types |
| [**update_context_type**](ContextTypesApi.md#update_context_type) | **PUT** /api/v1/context_types/{id} | Update Context Type |


## create_context_type

> <ContextTypeResponse> create_context_type(context_type_request)

Create Context Type

Create a new context type. The caller provides the id (key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextTypesApi.new
context_type_request = SmplkitGeneratedClient::App::ContextTypeRequest.new({data: SmplkitGeneratedClient::App::ContextTypeResource.new({type: 'context_type', attributes: SmplkitGeneratedClient::App::ContextType.new({name: 'name_example'})})}) # ContextTypeRequest | 

begin
  # Create Context Type
  result = api_instance.create_context_type(context_type_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->create_context_type: #{e}"
end
```

#### Using the create_context_type_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextTypeResponse>, Integer, Hash)> create_context_type_with_http_info(context_type_request)

```ruby
begin
  # Create Context Type
  data, status_code, headers = api_instance.create_context_type_with_http_info(context_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextTypeResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->create_context_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **context_type_request** | [**ContextTypeRequest**](ContextTypeRequest.md) |  |  |

### Return type

[**ContextTypeResponse**](ContextTypeResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_context_type

> delete_context_type(id)

Delete Context Type

Delete a context type and all its associated context instances by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextTypesApi.new
id = 'id_example' # String | 

begin
  # Delete Context Type
  api_instance.delete_context_type(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->delete_context_type: #{e}"
end
```

#### Using the delete_context_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_context_type_with_http_info(id)

```ruby
begin
  # Delete Context Type
  data, status_code, headers = api_instance.delete_context_type_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->delete_context_type_with_http_info: #{e}"
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


## get_context_type

> <ContextTypeResponse> get_context_type(id)

Get Context Type

Return a context type by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextTypesApi.new
id = 'id_example' # String | 

begin
  # Get Context Type
  result = api_instance.get_context_type(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->get_context_type: #{e}"
end
```

#### Using the get_context_type_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextTypeResponse>, Integer, Hash)> get_context_type_with_http_info(id)

```ruby
begin
  # Get Context Type
  data, status_code, headers = api_instance.get_context_type_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextTypeResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->get_context_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ContextTypeResponse**](ContextTypeResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_context_types

> <ContextTypeListResponse> list_context_types(opts)

List Context Types

List all context types for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextTypesApi.new
opts = {
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Context Types
  result = api_instance.list_context_types(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->list_context_types: #{e}"
end
```

#### Using the list_context_types_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextTypeListResponse>, Integer, Hash)> list_context_types_with_http_info(opts)

```ruby
begin
  # List Context Types
  data, status_code, headers = api_instance.list_context_types_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextTypeListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->list_context_types_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**ContextTypeListResponse**](ContextTypeListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_context_type

> <ContextTypeResponse> update_context_type(id, context_type_request)

Update Context Type

Update a context type by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextTypesApi.new
id = 'id_example' # String | 
context_type_request = SmplkitGeneratedClient::App::ContextTypeRequest.new({data: SmplkitGeneratedClient::App::ContextTypeResource.new({type: 'context_type', attributes: SmplkitGeneratedClient::App::ContextType.new({name: 'name_example'})})}) # ContextTypeRequest | 

begin
  # Update Context Type
  result = api_instance.update_context_type(id, context_type_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->update_context_type: #{e}"
end
```

#### Using the update_context_type_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextTypeResponse>, Integer, Hash)> update_context_type_with_http_info(id, context_type_request)

```ruby
begin
  # Update Context Type
  data, status_code, headers = api_instance.update_context_type_with_http_info(id, context_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextTypeResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextTypesApi->update_context_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **context_type_request** | [**ContextTypeRequest**](ContextTypeRequest.md) |  |  |

### Return type

[**ContextTypeResponse**](ContextTypeResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

