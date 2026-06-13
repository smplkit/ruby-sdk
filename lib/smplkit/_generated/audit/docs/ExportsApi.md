# SmplkitGeneratedClient::Audit::ExportsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_export**](ExportsApi.md#create_export) | **POST** /api/v1/exports | Create Export |
| [**download_export**](ExportsApi.md#download_export) | **GET** /api/v1/exports/{token} | Download Export |


## create_export

> <ExportResponse> create_export(export_request)

Create Export

Mint a short-lived signed URL to stream an events download.  The request body specifies `format` (`CSV` or `JSONL`) and any subset of the event filters accepted by `GET /api/v1/events`. An export is scoped to a single environment: name it in the body's `environment` field, or omit it and a single-environment credential implies it (a multi-environment credential must name it). The response returns the signed URL plus its expiry (30 seconds from mint). Open the URL in a browser to stream the file to disk; no `Authorization` header is required at download time.  Filter rules match `GET /api/v1/events`: `filter[resource_id]` requires `filter[resource_type]`; `filter[search]` requires either `filter[occurred_at]` or `filter[resource_type]` + `filter[resource_id]`. Violations are rejected here at mint time.  Reads are allowed on lapsed subscriptions per the smplcore convention — same gate as the events list.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ExportsApi.new
export_request = SmplkitGeneratedClient::Audit::ExportRequest.new({data: SmplkitGeneratedClient::Audit::ExportResource.new({attributes: SmplkitGeneratedClient::Audit::Export.new({format: 'CSV'})})}) # ExportRequest | 

begin
  # Create Export
  result = api_instance.create_export(export_request)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ExportsApi->create_export: #{e}"
end
```

#### Using the create_export_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ExportResponse>, Integer, Hash)> create_export_with_http_info(export_request)

```ruby
begin
  # Create Export
  data, status_code, headers = api_instance.create_export_with_http_info(export_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ExportResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ExportsApi->create_export_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **export_request** | [**ExportRequest**](ExportRequest.md) |  |  |

### Return type

[**ExportResponse**](ExportResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## download_export

> download_export(token)

Download Export

Stream a signed audit-events download — no `Authorization` header required.  Authorization is the token itself: it carries the account, the chosen format, and the filters, all integrity-protected by HMAC. The endpoint verifies the signature and expiry, scopes the events query to the token's account, and streams the response.  Any failure (bad signature, wrong audience, expired, malformed payload) returns `404 Not Found` — the response shape never leaks which check failed.  The token is stateless and replayable until it expires (≤30s). Concurrent or duplicate GETs (browser retries, AV scanners, prefetchers) all succeed; there is no single-use behavior.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'

api_instance = SmplkitGeneratedClient::Audit::ExportsApi.new
token = 'token_example' # String | Opaque signed download token from `POST /api/v1/exports`. Treat as a single short-lived URL — do not parse or store long-term.

begin
  # Download Export
  api_instance.download_export(token)
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ExportsApi->download_export: #{e}"
end
```

#### Using the download_export_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> download_export_with_http_info(token)

```ruby
begin
  # Download Export
  data, status_code, headers = api_instance.download_export_with_http_info(token)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ExportsApi->download_export_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token** | **String** | Opaque signed download token from &#x60;POST /api/v1/exports&#x60;. Treat as a single short-lived URL — do not parse or store long-term. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined

