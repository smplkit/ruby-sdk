# SmplkitGeneratedClient::Flags::FlagsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk_register_flags**](FlagsApi.md#bulk_register_flags) | **POST** /api/v1/flags/bulk | Bulk Register Flags |
| [**create_flag**](FlagsApi.md#create_flag) | **POST** /api/v1/flags | Create Flag |
| [**delete_flag**](FlagsApi.md#delete_flag) | **DELETE** /api/v1/flags/{id} | Delete Flag |
| [**get_flag**](FlagsApi.md#get_flag) | **GET** /api/v1/flags/{id} | Get Flag |
| [**list_flags**](FlagsApi.md#list_flags) | **GET** /api/v1/flags | List Flags |
| [**update_flag**](FlagsApi.md#update_flag) | **PUT** /api/v1/flags/{id} | Update Flag |


## bulk_register_flags

> <FlagBulkResponse> bulk_register_flags(flag_bulk_request)

Bulk Register Flags

Register flags discovered by an SDK.  Creates a new flag for each unreported key and refreshes the service/environment source observation on each already-known key.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
flag_bulk_request = SmplkitGeneratedClient::Flags::FlagBulkRequest.new({flags: [SmplkitGeneratedClient::Flags::FlagBulkItem.new({id: 'id_example', type: 'BOOLEAN', default: 3.56})]}) # FlagBulkRequest | 

begin
  # Bulk Register Flags
  result = api_instance.bulk_register_flags(flag_bulk_request)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->bulk_register_flags: #{e}"
end
```

#### Using the bulk_register_flags_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagBulkResponse>, Integer, Hash)> bulk_register_flags_with_http_info(flag_bulk_request)

```ruby
begin
  # Bulk Register Flags
  data, status_code, headers = api_instance.bulk_register_flags_with_http_info(flag_bulk_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagBulkResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->bulk_register_flags_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **flag_bulk_request** | [**FlagBulkRequest**](FlagBulkRequest.md) |  |  |

### Return type

[**FlagBulkResponse**](FlagBulkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## create_flag

> <FlagResponse> create_flag(flag_request)

Create Flag

Create a new feature flag. The caller provides the id (the flag key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
flag_request = SmplkitGeneratedClient::Flags::FlagRequest.new({data: SmplkitGeneratedClient::Flags::FlagResource.new({type: 'flag', attributes: SmplkitGeneratedClient::Flags::Flag.new({name: 'name_example', type: 'BOOLEAN', default: 3.56})})}) # FlagRequest | 

begin
  # Create Flag
  result = api_instance.create_flag(flag_request)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->create_flag: #{e}"
end
```

#### Using the create_flag_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagResponse>, Integer, Hash)> create_flag_with_http_info(flag_request)

```ruby
begin
  # Create Flag
  data, status_code, headers = api_instance.create_flag_with_http_info(flag_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->create_flag_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **flag_request** | [**FlagRequest**](FlagRequest.md) |  |  |

### Return type

[**FlagResponse**](FlagResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_flag

> delete_flag(id)

Delete Flag

Delete a feature flag by its key.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
id = 'id_example' # String | 

begin
  # Delete Flag
  api_instance.delete_flag(id)
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->delete_flag: #{e}"
end
```

#### Using the delete_flag_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_flag_with_http_info(id)

```ruby
begin
  # Delete Flag
  data, status_code, headers = api_instance.delete_flag_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->delete_flag_with_http_info: #{e}"
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
- **Accept**: Not defined


## get_flag

> <FlagResponse> get_flag(id)

Get Flag

Retrieve a feature flag by its key.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
id = 'id_example' # String | 

begin
  # Get Flag
  result = api_instance.get_flag(id)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->get_flag: #{e}"
end
```

#### Using the get_flag_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagResponse>, Integer, Hash)> get_flag_with_http_info(id)

```ruby
begin
  # Get Flag
  data, status_code, headers = api_instance.get_flag_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->get_flag_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**FlagResponse**](FlagResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_flags

> <FlagListResponse> list_flags(opts)

List Flags

List feature flags for this account.  Default sort is `key` ascending. ``filter[references_context]`` and ``filter[references_context_type]`` walk the rules JSON in Python after the SQL fetch, so pagination for those calls is applied in memory after the filter; for the common case (no rules-traversal filter) pagination is applied at the SQL level.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
opts = {
  filter_type: 'filter_type_example', # String | 
  filter_managed: true, # Boolean | 
  filter_references_context: 'filter_references_context_example', # String | Return flags whose rules reference this context instance. Format: {type}:{key}
  filter_references_context_type: 'filter_references_context_type_example', # String | Return flags whose rules reference any attribute of the given context type.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `type`, `-type`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Flags
  result = api_instance.list_flags(opts)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->list_flags: #{e}"
end
```

#### Using the list_flags_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagListResponse>, Integer, Hash)> list_flags_with_http_info(opts)

```ruby
begin
  # List Flags
  data, status_code, headers = api_instance.list_flags_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagListResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->list_flags_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_type** | **String** |  | [optional] |
| **filter_managed** | **Boolean** |  | [optional] |
| **filter_references_context** | **String** | Return flags whose rules reference this context instance. Format: {type}:{key} | [optional] |
| **filter_references_context_type** | **String** | Return flags whose rules reference any attribute of the given context type. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;type&#x60;, &#x60;-type&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**FlagListResponse**](FlagListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_flag

> <FlagResponse> update_flag(id, flag_request)

Update Flag

Replace a feature flag entirely. Every writable field is overwritten.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FlagsApi.new
id = 'id_example' # String | 
flag_request = SmplkitGeneratedClient::Flags::FlagRequest.new({data: SmplkitGeneratedClient::Flags::FlagResource.new({type: 'flag', attributes: SmplkitGeneratedClient::Flags::Flag.new({name: 'name_example', type: 'BOOLEAN', default: 3.56})})}) # FlagRequest | 

begin
  # Update Flag
  result = api_instance.update_flag(id, flag_request)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->update_flag: #{e}"
end
```

#### Using the update_flag_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<FlagResponse>, Integer, Hash)> update_flag_with_http_info(id, flag_request)

```ruby
begin
  # Update Flag
  data, status_code, headers = api_instance.update_flag_with_http_info(id, flag_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <FlagResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FlagsApi->update_flag_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **flag_request** | [**FlagRequest**](FlagRequest.md) |  |  |

### Return type

[**FlagResponse**](FlagResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

