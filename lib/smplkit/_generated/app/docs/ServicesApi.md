# SmplkitGeneratedClient::App::ServicesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_service**](ServicesApi.md#create_service) | **POST** /api/v1/services | Create Service |
| [**delete_service**](ServicesApi.md#delete_service) | **DELETE** /api/v1/services/{id} | Delete Service |
| [**get_service**](ServicesApi.md#get_service) | **GET** /api/v1/services/{id} | Get Service |
| [**list_services**](ServicesApi.md#list_services) | **GET** /api/v1/services | List Services |
| [**update_service**](ServicesApi.md#update_service) | **PUT** /api/v1/services/{id} | Update Service |


## create_service

> <ServiceResponse> create_service(service_request)

Create Service

Create a new service. The caller provides the id (key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ServicesApi.new
service_request = SmplkitGeneratedClient::App::ServiceRequest.new({data: SmplkitGeneratedClient::App::ServiceResource.new({type: 'service', attributes: SmplkitGeneratedClient::App::Service.new({name: 'name_example'})})}) # ServiceRequest | 

begin
  # Create Service
  result = api_instance.create_service(service_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->create_service: #{e}"
end
```

#### Using the create_service_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceResponse>, Integer, Hash)> create_service_with_http_info(service_request)

```ruby
begin
  # Create Service
  data, status_code, headers = api_instance.create_service_with_http_info(service_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->create_service_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **service_request** | [**ServiceRequest**](ServiceRequest.md) |  |  |

### Return type

[**ServiceResponse**](ServiceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_service

> delete_service(id)

Delete Service

Delete a service by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ServicesApi.new
id = 'id_example' # String | 

begin
  # Delete Service
  api_instance.delete_service(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->delete_service: #{e}"
end
```

#### Using the delete_service_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_service_with_http_info(id)

```ruby
begin
  # Delete Service
  data, status_code, headers = api_instance.delete_service_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->delete_service_with_http_info: #{e}"
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


## get_service

> <ServiceResponse> get_service(id)

Get Service

Return a service by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ServicesApi.new
id = 'id_example' # String | 

begin
  # Get Service
  result = api_instance.get_service(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->get_service: #{e}"
end
```

#### Using the get_service_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceResponse>, Integer, Hash)> get_service_with_http_info(id)

```ruby
begin
  # Get Service
  data, status_code, headers = api_instance.get_service_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->get_service_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ServiceResponse**](ServiceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_services

> <ServiceListResponse> list_services(opts)

List Services

List all services for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ServicesApi.new
opts = {
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
}

begin
  # List Services
  result = api_instance.list_services(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->list_services: #{e}"
end
```

#### Using the list_services_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceListResponse>, Integer, Hash)> list_services_with_http_info(opts)

```ruby
begin
  # List Services
  data, status_code, headers = api_instance.list_services_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->list_services_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;name&#39;] |

### Return type

[**ServiceListResponse**](ServiceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_service

> <ServiceResponse> update_service(id, service_request)

Update Service

Update a service by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ServicesApi.new
id = 'id_example' # String | 
service_request = SmplkitGeneratedClient::App::ServiceRequest.new({data: SmplkitGeneratedClient::App::ServiceResource.new({type: 'service', attributes: SmplkitGeneratedClient::App::Service.new({name: 'name_example'})})}) # ServiceRequest | 

begin
  # Update Service
  result = api_instance.update_service(id, service_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->update_service: #{e}"
end
```

#### Using the update_service_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceResponse>, Integer, Hash)> update_service_with_http_info(id, service_request)

```ruby
begin
  # Update Service
  data, status_code, headers = api_instance.update_service_with_http_info(id, service_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ServicesApi->update_service_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **service_request** | [**ServiceRequest**](ServiceRequest.md) |  |  |

### Return type

[**ServiceResponse**](ServiceResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

