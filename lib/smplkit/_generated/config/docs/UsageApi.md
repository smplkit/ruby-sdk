# SmplkitGeneratedClient::Config::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_config_usage**](UsageApi.md#list_config_usage) | **GET** /api/v1/usage | List Config Usage |


## list_config_usage

> <UsageListResponse> list_config_usage(opts)

List Config Usage

Return current resource usage counts for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::UsageApi.new
opts = {
  filter_period: 'filter_period_example' # String | 
}

begin
  # List Config Usage
  result = api_instance.list_config_usage(opts)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling UsageApi->list_config_usage: #{e}"
end
```

#### Using the list_config_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageListResponse>, Integer, Hash)> list_config_usage_with_http_info(opts)

```ruby
begin
  # List Config Usage
  data, status_code, headers = api_instance.list_config_usage_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageListResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling UsageApi->list_config_usage_with_http_info: #{e}"
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

