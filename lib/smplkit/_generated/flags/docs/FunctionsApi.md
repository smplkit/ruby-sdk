# SmplkitGeneratedClient::Flags::FunctionsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**remove_references**](FunctionsApi.md#remove_references) | **POST** /api/v1/functions/remove_references/actions/execute | Execute Remove References |


## remove_references

> <RemoveReferencesResultEnvelope> remove_references(remove_references_request)

Execute Remove References

Remove every rule that references a specific context across every flag.  Provide exactly one of `context` (matches a single instance, formatted as `{type}:{key}`) or `context_type` (matches any attribute of that context type). Rules whose reference sits inside an AND expression are not removed automatically; they are returned in `rules_needing_manual_review` for the caller to handle.

### Examples

```ruby
require 'time'
require 'smplkit_flags_client'
# setup authorization
SmplkitGeneratedClient::Flags.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Flags::FunctionsApi.new
remove_references_request = SmplkitGeneratedClient::Flags::RemoveReferencesRequest.new # RemoveReferencesRequest | 

begin
  # Execute Remove References
  result = api_instance.remove_references(remove_references_request)
  p result
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FunctionsApi->remove_references: #{e}"
end
```

#### Using the remove_references_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RemoveReferencesResultEnvelope>, Integer, Hash)> remove_references_with_http_info(remove_references_request)

```ruby
begin
  # Execute Remove References
  data, status_code, headers = api_instance.remove_references_with_http_info(remove_references_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RemoveReferencesResultEnvelope>
rescue SmplkitGeneratedClient::Flags::ApiError => e
  puts "Error when calling FunctionsApi->remove_references_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **remove_references_request** | [**RemoveReferencesRequest**](RemoveReferencesRequest.md) |  |  |

### Return type

[**RemoveReferencesResultEnvelope**](RemoveReferencesResultEnvelope.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

