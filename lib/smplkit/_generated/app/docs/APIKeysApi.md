# SmplkitGeneratedClient::App::APIKeysApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_api_key**](APIKeysApi.md#create_api_key) | **POST** /api/v1/api_keys | Create API Key |
| [**delete_api_key**](APIKeysApi.md#delete_api_key) | **DELETE** /api/v1/api_keys/{id} | Delete API Key |
| [**get_api_key**](APIKeysApi.md#get_api_key) | **GET** /api/v1/api_keys/{id} | Get API Key |
| [**list_api_keys**](APIKeysApi.md#list_api_keys) | **GET** /api/v1/api_keys | List API Keys |
| [**revoke_api_key**](APIKeysApi.md#revoke_api_key) | **POST** /api/v1/api_keys/{id}/actions/revoke | Revoke API Key |
| [**update_api_key**](APIKeysApi.md#update_api_key) | **PUT** /api/v1/api_keys/{id} | Update API Key |


## create_api_key

> <ApiKeyResponse> create_api_key(api_key_response)

Create API Key

Create a new API key. The id and key value are server-generated.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
api_key_response = SmplkitGeneratedClient::App::ApiKeyResponse.new({data: SmplkitGeneratedClient::App::ApiKeyResource.new({type: 'api_key', attributes: SmplkitGeneratedClient::App::ApiKey.new({name: 'name_example'})})}) # ApiKeyResponse | 

begin
  # Create API Key
  result = api_instance.create_api_key(api_key_response)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->create_api_key: #{e}"
end
```

#### Using the create_api_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiKeyResponse>, Integer, Hash)> create_api_key_with_http_info(api_key_response)

```ruby
begin
  # Create API Key
  data, status_code, headers = api_instance.create_api_key_with_http_info(api_key_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiKeyResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->create_api_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **api_key_response** | [**ApiKeyResponse**](ApiKeyResponse.md) |  |  |

### Return type

[**ApiKeyResponse**](ApiKeyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_api_key

> delete_api_key(id)

Delete API Key

Delete an API key by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Delete API Key
  api_instance.delete_api_key(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->delete_api_key: #{e}"
end
```

#### Using the delete_api_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_api_key_with_http_info(id)

```ruby
begin
  # Delete API Key
  data, status_code, headers = api_instance.delete_api_key_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->delete_api_key_with_http_info: #{e}"
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


## get_api_key

> <ApiKeyResponse> get_api_key(id)

Get API Key

Return an API key by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get API Key
  result = api_instance.get_api_key(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->get_api_key: #{e}"
end
```

#### Using the get_api_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiKeyResponse>, Integer, Hash)> get_api_key_with_http_info(id)

```ruby
begin
  # Get API Key
  data, status_code, headers = api_instance.get_api_key_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiKeyResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->get_api_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ApiKeyResponse**](ApiKeyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_api_keys

> <ApiKeyListResponse> list_api_keys(opts)

List API Keys

List all API keys for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
opts = {
  filter_status: 'filter_status_example' # String | 
}

begin
  # List API Keys
  result = api_instance.list_api_keys(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->list_api_keys: #{e}"
end
```

#### Using the list_api_keys_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiKeyListResponse>, Integer, Hash)> list_api_keys_with_http_info(opts)

```ruby
begin
  # List API Keys
  data, status_code, headers = api_instance.list_api_keys_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiKeyListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->list_api_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_status** | **String** |  | [optional] |

### Return type

[**ApiKeyListResponse**](ApiKeyListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## revoke_api_key

> <ApiKeyResponse> revoke_api_key(id)

Revoke API Key

Permanently revoke an API key.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Revoke API Key
  result = api_instance.revoke_api_key(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->revoke_api_key: #{e}"
end
```

#### Using the revoke_api_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiKeyResponse>, Integer, Hash)> revoke_api_key_with_http_info(id)

```ruby
begin
  # Revoke API Key
  data, status_code, headers = api_instance.revoke_api_key_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiKeyResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->revoke_api_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ApiKeyResponse**](ApiKeyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_api_key

> <ApiKeyResponse> update_api_key(id, api_key_response)

Update API Key

Update an API key by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::APIKeysApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
api_key_response = SmplkitGeneratedClient::App::ApiKeyResponse.new({data: SmplkitGeneratedClient::App::ApiKeyResource.new({type: 'api_key', attributes: SmplkitGeneratedClient::App::ApiKey.new({name: 'name_example'})})}) # ApiKeyResponse | 

begin
  # Update API Key
  result = api_instance.update_api_key(id, api_key_response)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->update_api_key: #{e}"
end
```

#### Using the update_api_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ApiKeyResponse>, Integer, Hash)> update_api_key_with_http_info(id, api_key_response)

```ruby
begin
  # Update API Key
  data, status_code, headers = api_instance.update_api_key_with_http_info(id, api_key_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ApiKeyResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling APIKeysApi->update_api_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **api_key_response** | [**ApiKeyResponse**](ApiKeyResponse.md) |  |  |

### Return type

[**ApiKeyResponse**](ApiKeyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

