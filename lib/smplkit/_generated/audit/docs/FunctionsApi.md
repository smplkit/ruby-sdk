# SmplkitGeneratedClient::Audit::FunctionsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**execute_wipe**](FunctionsApi.md#execute_wipe) | **POST** /api/v1/functions/wipe/actions/execute | Execute Wipe |


## execute_wipe

> <WipeResponse> execute_wipe(body)

Execute Wipe

Delete every audit-database row scoped to the authenticated account.  Returns the per-table row counts that were deleted along with the completion timestamp. The action is atomic within the audit database — either every account-scoped row is gone, or none is. The body is required to be ``{}``; no parameters are accepted.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::FunctionsApi.new
body = { ... } # Object | 

begin
  # Execute Wipe
  result = api_instance.execute_wipe(body)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling FunctionsApi->execute_wipe: #{e}"
end
```

#### Using the execute_wipe_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<WipeResponse>, Integer, Hash)> execute_wipe_with_http_info(body)

```ruby
begin
  # Execute Wipe
  data, status_code, headers = api_instance.execute_wipe_with_http_info(body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <WipeResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling FunctionsApi->execute_wipe_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **body** | **Object** |  |  |

### Return type

[**WipeResponse**](WipeResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

