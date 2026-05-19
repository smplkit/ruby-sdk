# SmplkitGeneratedClient::Audit::ForwarderTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_forwarder_type_api_v1_forwarder_types_id_get**](ForwarderTypesApi.md#get_forwarder_type_api_v1_forwarder_types_id_get) | **GET** /api/v1/forwarder_types/{id} | Get Forwarder Type |
| [**list_forwarder_types_api_v1_forwarder_types_get**](ForwarderTypesApi.md#list_forwarder_types_api_v1_forwarder_types_get) | **GET** /api/v1/forwarder_types | List Forwarder Types |


## get_forwarder_type_api_v1_forwarder_types_id_get

> <ForwarderTypeResponse> get_forwarder_type_api_v1_forwarder_types_id_get(id)

Get Forwarder Type

Fetch a single forwarder type from the catalog.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'

api_instance = SmplkitGeneratedClient::Audit::ForwarderTypesApi.new
id = 'id_example' # String | 

begin
  # Get Forwarder Type
  result = api_instance.get_forwarder_type_api_v1_forwarder_types_id_get(id)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwarderTypesApi->get_forwarder_type_api_v1_forwarder_types_id_get: #{e}"
end
```

#### Using the get_forwarder_type_api_v1_forwarder_types_id_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderTypeResponse>, Integer, Hash)> get_forwarder_type_api_v1_forwarder_types_id_get_with_http_info(id)

```ruby
begin
  # Get Forwarder Type
  data, status_code, headers = api_instance.get_forwarder_type_api_v1_forwarder_types_id_get_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderTypeResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwarderTypesApi->get_forwarder_type_api_v1_forwarder_types_id_get_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ForwarderTypeResponse**](ForwarderTypeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_forwarder_types_api_v1_forwarder_types_get

> <ForwarderTypeListResponse> list_forwarder_types_api_v1_forwarder_types_get

List Forwarder Types

List all forwarder types in the catalog.  Returns every branded HTTP forwarder type defined in `forwarder_types/*.yaml` plus the synthetic `http` (Custom HTTP) entry. The response drives the console's create-forwarder UX, the docs vendor-reference page, and audit's own server-side template validation.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'

api_instance = SmplkitGeneratedClient::Audit::ForwarderTypesApi.new

begin
  # List Forwarder Types
  result = api_instance.list_forwarder_types_api_v1_forwarder_types_get
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwarderTypesApi->list_forwarder_types_api_v1_forwarder_types_get: #{e}"
end
```

#### Using the list_forwarder_types_api_v1_forwarder_types_get_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderTypeListResponse>, Integer, Hash)> list_forwarder_types_api_v1_forwarder_types_get_with_http_info

```ruby
begin
  # List Forwarder Types
  data, status_code, headers = api_instance.list_forwarder_types_api_v1_forwarder_types_get_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderTypeListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwarderTypesApi->list_forwarder_types_api_v1_forwarder_types_get_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ForwarderTypeListResponse**](ForwarderTypeListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

