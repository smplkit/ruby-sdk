# SmplkitGeneratedClient::Audit::ResourceTypesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_actions**](ResourceTypesApi.md#list_actions) | **GET** /api/v1/actions | List Actions |
| [**list_resource_types**](ResourceTypesApi.md#list_resource_types) | **GET** /api/v1/resource_types | List Resource Types |


## list_actions

> <ActionListResponse> list_actions(opts)

List Actions

List the distinct ``action`` slugs seen in the account.  Without ``filter[resource_type]``, returns one row per distinct action — the same action may have been recorded with multiple resource types and the unfiltered dropdown shows it once.  With ``filter[resource_type]``, returns the actions seen with that specific resource type, powering the Activity tab's cascading filter behavior.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ResourceTypesApi.new
opts = {
  filter_resource_type: 'filter_resource_type_example', # String | 
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
}

begin
  # List Actions
  result = api_instance.list_actions(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_actions: #{e}"
end
```

#### Using the list_actions_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ActionListResponse>, Integer, Hash)> list_actions_with_http_info(opts)

```ruby
begin
  # List Actions
  data, status_code, headers = api_instance.list_actions_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ActionListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_actions_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_resource_type** | **String** |  | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

### Return type

[**ActionListResponse**](ActionListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_resource_types

> <ResourceTypeListResponse> list_resource_types(opts)

List Resource Types

List the distinct ``resource_type`` slugs seen in the account.  Each row's ``id`` is the slug itself, mirroring the smplkit convention of using customer-provided identifiers as the public-facing resource id (ADR-014).

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ResourceTypesApi.new
opts = {
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
}

begin
  # List Resource Types
  result = api_instance.list_resource_types(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_resource_types: #{e}"
end
```

#### Using the list_resource_types_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ResourceTypeListResponse>, Integer, Hash)> list_resource_types_with_http_info(opts)

```ruby
begin
  # List Resource Types
  data, status_code, headers = api_instance.list_resource_types_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ResourceTypeListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ResourceTypesApi->list_resource_types_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

### Return type

[**ResourceTypeListResponse**](ResourceTypeListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

