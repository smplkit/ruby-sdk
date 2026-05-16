# SmplkitGeneratedClient::Logging::LogGroupsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_log_group**](LogGroupsApi.md#create_log_group) | **POST** /api/v1/log_groups | Create Log Group |
| [**delete_log_group**](LogGroupsApi.md#delete_log_group) | **DELETE** /api/v1/log_groups/{id} | Delete Log Group |
| [**get_log_group**](LogGroupsApi.md#get_log_group) | **GET** /api/v1/log_groups/{id} | Get Log Group |
| [**list_log_groups**](LogGroupsApi.md#list_log_groups) | **GET** /api/v1/log_groups | List Log Groups |
| [**update_log_group**](LogGroupsApi.md#update_log_group) | **PUT** /api/v1/log_groups/{id} | Update Log Group |


## create_log_group

> <LogGroupResponse> create_log_group(log_group_request)

Create Log Group

Create a log group.  The caller may supply a key in `data.id`; if omitted, the server generates one from `name`.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LogGroupsApi.new
log_group_request = SmplkitGeneratedClient::Logging::LogGroupRequest.new({data: SmplkitGeneratedClient::Logging::LogGroupResource.new({type: 'log_group', attributes: SmplkitGeneratedClient::Logging::LogGroup.new({name: 'name_example'})})}) # LogGroupRequest | 

begin
  # Create Log Group
  result = api_instance.create_log_group(log_group_request)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->create_log_group: #{e}"
end
```

#### Using the create_log_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupResponse>, Integer, Hash)> create_log_group_with_http_info(log_group_request)

```ruby
begin
  # Create Log Group
  data, status_code, headers = api_instance.create_log_group_with_http_info(log_group_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LogGroupResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->create_log_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **log_group_request** | [**LogGroupRequest**](LogGroupRequest.md) |  |  |

### Return type

[**LogGroupResponse**](LogGroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_log_group

> delete_log_group(id)

Delete Log Group

Delete a log group.  Loggers that referenced this group are detached; they remain in the account with no group assignment.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LogGroupsApi.new
id = 'id_example' # String | 

begin
  # Delete Log Group
  api_instance.delete_log_group(id)
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->delete_log_group: #{e}"
end
```

#### Using the delete_log_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_log_group_with_http_info(id)

```ruby
begin
  # Delete Log Group
  data, status_code, headers = api_instance.delete_log_group_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->delete_log_group_with_http_info: #{e}"
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


## get_log_group

> <LogGroupResponse> get_log_group(id)

Get Log Group

Retrieve a log group by its key.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LogGroupsApi.new
id = 'id_example' # String | 

begin
  # Get Log Group
  result = api_instance.get_log_group(id)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->get_log_group: #{e}"
end
```

#### Using the get_log_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupResponse>, Integer, Hash)> get_log_group_with_http_info(id)

```ruby
begin
  # Get Log Group
  data, status_code, headers = api_instance.get_log_group_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LogGroupResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->get_log_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**LogGroupResponse**](LogGroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_log_groups

> <LogGroupListResponse> list_log_groups(opts)

List Log Groups

List log groups for this account.  Default sort is `key` ascending.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LogGroupsApi.new
opts = {
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Log Groups
  result = api_instance.list_log_groups(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->list_log_groups: #{e}"
end
```

#### Using the list_log_groups_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupListResponse>, Integer, Hash)> list_log_groups_with_http_info(opts)

```ruby
begin
  # List Log Groups
  data, status_code, headers = api_instance.list_log_groups_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LogGroupListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->list_log_groups_with_http_info: #{e}"
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

[**LogGroupListResponse**](LogGroupListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_log_group

> <LogGroupResponse> update_log_group(id, log_group_request)

Update Log Group

Replace a log group. Every writable field is overwritten.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::LogGroupsApi.new
id = 'id_example' # String | 
log_group_request = SmplkitGeneratedClient::Logging::LogGroupRequest.new({data: SmplkitGeneratedClient::Logging::LogGroupResource.new({type: 'log_group', attributes: SmplkitGeneratedClient::Logging::LogGroup.new({name: 'name_example'})})}) # LogGroupRequest | 

begin
  # Update Log Group
  result = api_instance.update_log_group(id, log_group_request)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->update_log_group: #{e}"
end
```

#### Using the update_log_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupResponse>, Integer, Hash)> update_log_group_with_http_info(id, log_group_request)

```ruby
begin
  # Update Log Group
  data, status_code, headers = api_instance.update_log_group_with_http_info(id, log_group_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LogGroupResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->update_log_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **log_group_request** | [**LogGroupRequest**](LogGroupRequest.md) |  |  |

### Return type

[**LogGroupResponse**](LogGroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

