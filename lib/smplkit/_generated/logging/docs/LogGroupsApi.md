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

> <LogGroupResponse> create_log_group(log_group_response)

Create Log Group

Create a new log group. The caller provides the key in data.id, or it is auto-generated from name.

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
log_group_response = SmplkitGeneratedClient::Logging::LogGroupResponse.new({data: SmplkitGeneratedClient::Logging::LogGroupResource.new({type: 'log_group', attributes: SmplkitGeneratedClient::Logging::LogGroup.new({name: 'name_example'})})}) # LogGroupResponse | 

begin
  # Create Log Group
  result = api_instance.create_log_group(log_group_response)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->create_log_group: #{e}"
end
```

#### Using the create_log_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupResponse>, Integer, Hash)> create_log_group_with_http_info(log_group_response)

```ruby
begin
  # Create Log Group
  data, status_code, headers = api_instance.create_log_group_with_http_info(log_group_response)
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
| **log_group_response** | [**LogGroupResponse**](LogGroupResponse.md) |  |  |

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

Delete a log group by its key.

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

Return a log group by its key.

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

> <LogGroupListResponse> list_log_groups

List Log Groups

List all log groups for the authenticated account.

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

begin
  # List Log Groups
  result = api_instance.list_log_groups
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->list_log_groups: #{e}"
end
```

#### Using the list_log_groups_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupListResponse>, Integer, Hash)> list_log_groups_with_http_info

```ruby
begin
  # List Log Groups
  data, status_code, headers = api_instance.list_log_groups_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LogGroupListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->list_log_groups_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**LogGroupListResponse**](LogGroupListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_log_group

> <LogGroupResponse> update_log_group(id, log_group_response)

Update Log Group

Replace a log group entirely.

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
log_group_response = SmplkitGeneratedClient::Logging::LogGroupResponse.new({data: SmplkitGeneratedClient::Logging::LogGroupResource.new({type: 'log_group', attributes: SmplkitGeneratedClient::Logging::LogGroup.new({name: 'name_example'})})}) # LogGroupResponse | 

begin
  # Update Log Group
  result = api_instance.update_log_group(id, log_group_response)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling LogGroupsApi->update_log_group: #{e}"
end
```

#### Using the update_log_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LogGroupResponse>, Integer, Hash)> update_log_group_with_http_info(id, log_group_response)

```ruby
begin
  # Update Log Group
  data, status_code, headers = api_instance.update_log_group_with_http_info(id, log_group_response)
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
| **log_group_response** | [**LogGroupResponse**](LogGroupResponse.md) |  |  |

### Return type

[**LogGroupResponse**](LogGroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

