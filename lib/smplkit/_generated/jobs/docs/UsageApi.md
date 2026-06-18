# SmplkitGeneratedClient::Jobs::UsageApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_usage**](UsageApi.md#get_usage) | **GET** /api/v1/usage | Get Usage |


## get_usage

> <UsageResponse> get_usage(opts)

Get Usage

Report this account's current-period usage against its plan allotments.  `runs_used` is the number of runs metered so far this calendar month; `active_jobs` is the number of recurring (scheduled) jobs, which is what the plan's job limit bounds.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::UsageApi.new
opts = {
  filter_period: 'filter_period_example' # String | 
}

begin
  # Get Usage
  result = api_instance.get_usage(opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling UsageApi->get_usage: #{e}"
end
```

#### Using the get_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UsageResponse>, Integer, Hash)> get_usage_with_http_info(opts)

```ruby
begin
  # Get Usage
  data, status_code, headers = api_instance.get_usage_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UsageResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling UsageApi->get_usage_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_period** | **String** |  | [optional][default to &#39;current&#39;] |

### Return type

[**UsageResponse**](UsageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

