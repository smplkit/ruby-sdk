# SmplkitGeneratedClient::Audit::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_usage**](UsageApi.md#list_usage) | **GET** /api/v1/usage | List Usage |


## list_usage

> <UsageResponse> list_usage(filter_period)

List Usage

Current-period usage and quota for the audit product.  Only ``filter[period]=current`` is supported; historical usage is a follow-up.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::UsageApi.new
filter_period = 'filter_period_example' # String | 

begin
  # List Usage
  result = api_instance.list_usage(filter_period)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling UsageApi->list_usage: #{e}"
end
```

#### Using the list_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageResponse>, Integer, Hash)> list_usage_with_http_info(filter_period)

```ruby
begin
  # List Usage
  data, status_code, headers = api_instance.list_usage_with_http_info(filter_period)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling UsageApi->list_usage_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_period** | **String** |  |  |

### Return type

[**UsageResponse**](UsageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

