# SmplkitGeneratedClient::Logging::ServicesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_services**](ServicesApi.md#list_services) | **GET** /api/v1/services | List Services |


## list_services

> <ServiceListResponse> list_services

List Services

List the services that have reported a logger for this account.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::ServicesApi.new

begin
  # List Services
  result = api_instance.list_services
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling ServicesApi->list_services: #{e}"
end
```

#### Using the list_services_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ServiceListResponse>, Integer, Hash)> list_services_with_http_info

```ruby
begin
  # List Services
  data, status_code, headers = api_instance.list_services_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ServiceListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling ServicesApi->list_services_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ServiceListResponse**](ServiceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

