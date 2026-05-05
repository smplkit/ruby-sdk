# SmplkitGeneratedClient::Config::ConfigsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_config**](ConfigsApi.md#create_config) | **POST** /api/v1/configs | Create Config |
| [**delete_config**](ConfigsApi.md#delete_config) | **DELETE** /api/v1/configs/{id} | Delete Config |
| [**get_config**](ConfigsApi.md#get_config) | **GET** /api/v1/configs/{id} | Get Config |
| [**list_configs**](ConfigsApi.md#list_configs) | **GET** /api/v1/configs | List Configs |
| [**update_config**](ConfigsApi.md#update_config) | **PUT** /api/v1/configs/{id} | Update Config |


## create_config

> <ConfigResponse> create_config(config_response)

Create Config

Create a new configuration. The caller provides the id (key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
config_response = SmplkitGeneratedClient::Config::ConfigResponse.new({data: SmplkitGeneratedClient::Config::ConfigResource.new({type: 'config', attributes: SmplkitGeneratedClient::Config::Config.new({name: 'name_example'})})}) # ConfigResponse | 

begin
  # Create Config
  result = api_instance.create_config(config_response)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->create_config: #{e}"
end
```

#### Using the create_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> create_config_with_http_info(config_response)

```ruby
begin
  # Create Config
  data, status_code, headers = api_instance.create_config_with_http_info(config_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->create_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **config_response** | [**ConfigResponse**](ConfigResponse.md) |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_config

> delete_config(id)

Delete Config

Delete a configuration by its key.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 

begin
  # Delete Config
  api_instance.delete_config(id)
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->delete_config: #{e}"
end
```

#### Using the delete_config_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_config_with_http_info(id)

```ruby
begin
  # Delete Config
  data, status_code, headers = api_instance.delete_config_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->delete_config_with_http_info: #{e}"
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


## get_config

> <ConfigResponse> get_config(id)

Get Config

Return a configuration by its key.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 

begin
  # Get Config
  result = api_instance.get_config(id)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->get_config: #{e}"
end
```

#### Using the get_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> get_config_with_http_info(id)

```ruby
begin
  # Get Config
  data, status_code, headers = api_instance.get_config_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->get_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_configs

> <ConfigListResponse> list_configs(opts)

List Configs

List all configurations for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
opts = {
  filter_parent: 'filter_parent_example' # String | 
}

begin
  # List Configs
  result = api_instance.list_configs(opts)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->list_configs: #{e}"
end
```

#### Using the list_configs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigListResponse>, Integer, Hash)> list_configs_with_http_info(opts)

```ruby
begin
  # List Configs
  data, status_code, headers = api_instance.list_configs_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigListResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->list_configs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_parent** | **String** |  | [optional] |

### Return type

[**ConfigListResponse**](ConfigListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_config

> <ConfigResponse> update_config(id, config_response)

Update Config

Replace a configuration entirely.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 
config_response = SmplkitGeneratedClient::Config::ConfigResponse.new({data: SmplkitGeneratedClient::Config::ConfigResource.new({type: 'config', attributes: SmplkitGeneratedClient::Config::Config.new({name: 'name_example'})})}) # ConfigResponse | 

begin
  # Update Config
  result = api_instance.update_config(id, config_response)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->update_config: #{e}"
end
```

#### Using the update_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> update_config_with_http_info(id, config_response)

```ruby
begin
  # Update Config
  data, status_code, headers = api_instance.update_config_with_http_info(id, config_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->update_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **config_response** | [**ConfigResponse**](ConfigResponse.md) |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

