# SmplkitGeneratedClient::App::EnvironmentsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_environment**](EnvironmentsApi.md#create_environment) | **POST** /api/v1/environments | Create Environment |
| [**delete_environment**](EnvironmentsApi.md#delete_environment) | **DELETE** /api/v1/environments/{id} | Delete Environment |
| [**get_environment**](EnvironmentsApi.md#get_environment) | **GET** /api/v1/environments/{id} | Get Environment |
| [**list_environments**](EnvironmentsApi.md#list_environments) | **GET** /api/v1/environments | List Environments |
| [**update_environment**](EnvironmentsApi.md#update_environment) | **PUT** /api/v1/environments/{id} | Update Environment |


## create_environment

> <EnvironmentResponse> create_environment(environment_request)

Create Environment

Create a new environment. The caller provides the id (key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
environment_request = SmplkitGeneratedClient::App::EnvironmentRequest.new({data: SmplkitGeneratedClient::App::EnvironmentResource.new({type: 'environment', attributes: SmplkitGeneratedClient::App::Environment.new({name: 'name_example'})})}) # EnvironmentRequest | 

begin
  # Create Environment
  result = api_instance.create_environment(environment_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->create_environment: #{e}"
end
```

#### Using the create_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> create_environment_with_http_info(environment_request)

```ruby
begin
  # Create Environment
  data, status_code, headers = api_instance.create_environment_with_http_info(environment_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->create_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **environment_request** | [**EnvironmentRequest**](EnvironmentRequest.md) |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_environment

> delete_environment(id)

Delete Environment

Delete an environment by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 

begin
  # Delete Environment
  api_instance.delete_environment(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->delete_environment: #{e}"
end
```

#### Using the delete_environment_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_environment_with_http_info(id)

```ruby
begin
  # Delete Environment
  data, status_code, headers = api_instance.delete_environment_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->delete_environment_with_http_info: #{e}"
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


## get_environment

> <EnvironmentResponse> get_environment(id)

Get Environment

Return an environment by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 

begin
  # Get Environment
  result = api_instance.get_environment(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment: #{e}"
end
```

#### Using the get_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> get_environment_with_http_info(id)

```ruby
begin
  # Get Environment
  data, status_code, headers = api_instance.get_environment_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_environments

> <EnvironmentListResponse> list_environments

List Environments

List all environments for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new

begin
  # List Environments
  result = api_instance.list_environments
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->list_environments: #{e}"
end
```

#### Using the list_environments_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentListResponse>, Integer, Hash)> list_environments_with_http_info

```ruby
begin
  # List Environments
  data, status_code, headers = api_instance.list_environments_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->list_environments_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**EnvironmentListResponse**](EnvironmentListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_environment

> <EnvironmentResponse> update_environment(id, environment_request)

Update Environment

Update an environment by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 
environment_request = SmplkitGeneratedClient::App::EnvironmentRequest.new({data: SmplkitGeneratedClient::App::EnvironmentResource.new({type: 'environment', attributes: SmplkitGeneratedClient::App::Environment.new({name: 'name_example'})})}) # EnvironmentRequest | 

begin
  # Update Environment
  result = api_instance.update_environment(id, environment_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->update_environment: #{e}"
end
```

#### Using the update_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> update_environment_with_http_info(id, environment_request)

```ruby
begin
  # Update Environment
  data, status_code, headers = api_instance.update_environment_with_http_info(id, environment_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->update_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **environment_request** | [**EnvironmentRequest**](EnvironmentRequest.md) |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

