# SmplkitGeneratedClient::Logging::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_logging_usage**](UsageApi.md#list_logging_usage) | **GET** /api/v1/usage | List Logging Usage |


## list_logging_usage

> <UsageListResponse> list_logging_usage(opts)

List Logging Usage

Return current resource usage counts for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_logging_client'
# setup authorization
SmplkitGeneratedClient::Logging.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Logging::UsageApi.new
opts = {
  filter_period: 'filter_period_example' # String | 
}

begin
  # List Logging Usage
  result = api_instance.list_logging_usage(opts)
  p result
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling UsageApi->list_logging_usage: #{e}"
end
```

#### Using the list_logging_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageListResponse>, Integer, Hash)> list_logging_usage_with_http_info(opts)

```ruby
begin
  # List Logging Usage
  data, status_code, headers = api_instance.list_logging_usage_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageListResponse>
rescue SmplkitGeneratedClient::Logging::ApiError => e
  puts "Error when calling UsageApi->list_logging_usage_with_http_info: #{e}"
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

