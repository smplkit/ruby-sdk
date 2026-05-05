# SmplkitGeneratedClient::Flags::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_flags_usage**](UsageApi.md#list_flags_usage) | **GET** /api/v1/usage | List Flags Usage |


## list_flags_usage

> <UsageListResponse> list_flags_usage(opts)

List Flags Usage

Return current resource usage counts for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::UsageApi.new
opts = {
  filter_period: 'filter_period_example' # String | 
}

begin
  # List Flags Usage
  result = api_instance.list_flags_usage(opts)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling UsageApi->list_flags_usage: #{e}"
end
```

#### Using the list_flags_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageListResponse>, Integer, Hash)> list_flags_usage_with_http_info(opts)

```ruby
begin
  # List Flags Usage
  data, status_code, headers = api_instance.list_flags_usage_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageListResponse>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling UsageApi->list_flags_usage_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_period** | **String** |  | [optional] |

### Return type

[**UsageListResponse**](UsageListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

