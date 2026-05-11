# SmplkitGeneratedClient::Audit::ActionsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_actions**](ActionsApi.md#list_actions) | **GET** /api/v1/actions | List Actions |


## list_actions

> <ActionListResponse> list_actions(opts)

List Actions

List the distinct `action` slugs recorded for this account.  Without `filter[resource_type]`, returns one row per distinct action. With `filter[resource_type]`, returns the actions recorded for that specific resource type.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ActionsApi.new
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
  puts "Error when calling ActionsApi->list_actions: #{e}"
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
  puts "Error when calling ActionsApi->list_actions_with_http_info: #{e}"
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

