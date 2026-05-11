# SmplkitGeneratedClient::Audit::ForwardersApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_forwarder**](ForwardersApi.md#create_forwarder) | **POST** /api/v1/forwarders | Create Forwarder |
| [**delete_forwarder**](ForwardersApi.md#delete_forwarder) | **DELETE** /api/v1/forwarders/{forwarder_id} | Delete Forwarder |
| [**execute_test_forwarder**](ForwardersApi.md#execute_test_forwarder) | **POST** /api/v1/functions/test_forwarder/actions/execute | Execute Test Forwarder |
| [**get_forwarder**](ForwardersApi.md#get_forwarder) | **GET** /api/v1/forwarders/{forwarder_id} | Get Forwarder |
| [**list_forwarder_deliveries**](ForwardersApi.md#list_forwarder_deliveries) | **GET** /api/v1/forwarders/{forwarder_id}/deliveries | List Forwarder Deliveries |
| [**list_forwarders**](ForwardersApi.md#list_forwarders) | **GET** /api/v1/forwarders | List Forwarders |
| [**retry_failed_forwarder_deliveries**](ForwardersApi.md#retry_failed_forwarder_deliveries) | **POST** /api/v1/forwarders/{forwarder_id}/actions/retry_failed_deliveries | Retry Failed Forwarder Deliveries |
| [**retry_forwarder_delivery**](ForwardersApi.md#retry_forwarder_delivery) | **POST** /api/v1/forwarders/{forwarder_id}/deliveries/{delivery_id}/actions/retry | Retry Forwarder Delivery |
| [**update_forwarder**](ForwardersApi.md#update_forwarder) | **PUT** /api/v1/forwarders/{forwarder_id} | Update Forwarder |


## create_forwarder

> <ForwarderResponse> create_forwarder(forwarder_response)

Create Forwarder

Create a forwarder. Requires the ``audit.siem_streaming`` entitlement on the account; lower-tier accounts get 402.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_response = SmplkitGeneratedClient::Audit::ForwarderResponse.new({data: SmplkitGeneratedClient::Audit::ForwarderResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Audit::Forwarder.new({name: 'name_example', forwarder_type: SmplkitGeneratedClient::Audit::ForwarderType::HTTP, http: SmplkitGeneratedClient::Audit::ForwarderHttp.new({url: 'url_example'})})})}) # ForwarderResponse | 

begin
  # Create Forwarder
  result = api_instance.create_forwarder(forwarder_response)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->create_forwarder: #{e}"
end
```

#### Using the create_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderResponse>, Integer, Hash)> create_forwarder_with_http_info(forwarder_response)

```ruby
begin
  # Create Forwarder
  data, status_code, headers = api_instance.create_forwarder_with_http_info(forwarder_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->create_forwarder_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_response** | [**ForwarderResponse**](ForwarderResponse.md) |  |  |

### Return type

[**ForwarderResponse**](ForwarderResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_forwarder

> delete_forwarder(forwarder_id)

Delete Forwarder

Soft-delete a forwarder. Delivery rows are retained per the normal forwarder_delivery retention; a future create with the same slug is allowed (the unique index is partial on deleted_at IS NULL).

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Delete Forwarder
  api_instance.delete_forwarder(forwarder_id)
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->delete_forwarder: #{e}"
end
```

#### Using the delete_forwarder_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_forwarder_with_http_info(forwarder_id)

```ruby
begin
  # Delete Forwarder
  data, status_code, headers = api_instance.delete_forwarder_with_http_info(forwarder_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->delete_forwarder_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## execute_test_forwarder

> <TestForwarderResponse> execute_test_forwarder(test_forwarder_request)

Execute Test Forwarder

Execute a prepared HTTP request server-side and return the response.  The same SSRF guard that gates the in-line forwarder loop is applied here — internal/private addresses, link-local IPs (including the EC2 metadata service at 169.254.169.254), unique-local IPv6, and ports outside the configured allowlist are all rejected.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
test_forwarder_request = SmplkitGeneratedClient::Audit::TestForwarderRequest.new({url: 'url_example'}) # TestForwarderRequest | 

begin
  # Execute Test Forwarder
  result = api_instance.execute_test_forwarder(test_forwarder_request)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->execute_test_forwarder: #{e}"
end
```

#### Using the execute_test_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<TestForwarderResponse>, Integer, Hash)> execute_test_forwarder_with_http_info(test_forwarder_request)

```ruby
begin
  # Execute Test Forwarder
  data, status_code, headers = api_instance.execute_test_forwarder_with_http_info(test_forwarder_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <TestForwarderResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->execute_test_forwarder_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **test_forwarder_request** | [**TestForwarderRequest**](TestForwarderRequest.md) |  |  |

### Return type

[**TestForwarderResponse**](TestForwarderResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## get_forwarder

> <ForwarderResponse> get_forwarder(forwarder_id)

Get Forwarder

Retrieve a single forwarder by id.  Returns 404 if no forwarder with that id exists in the caller's account, including if the forwarder is soft-deleted. Header values in the response are returned in plaintext so callers can perform a GET-modify-PUT round-trip without re-entering secrets (ADR-014). The persisted ``forwarder_delivery.request`` log column is what keeps redaction; that read path is unaffected by this route.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get Forwarder
  result = api_instance.get_forwarder(forwarder_id)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->get_forwarder: #{e}"
end
```

#### Using the get_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderResponse>, Integer, Hash)> get_forwarder_with_http_info(forwarder_id)

```ruby
begin
  # Get Forwarder
  data, status_code, headers = api_instance.get_forwarder_with_http_info(forwarder_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->get_forwarder_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |

### Return type

[**ForwarderResponse**](ForwarderResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_forwarder_deliveries

> <ForwarderDeliveryListResponse> list_forwarder_deliveries(forwarder_id, opts)

List Forwarder Deliveries

List delivery rows for a forwarder.  Default sort is ``-created_at``. Cursor pagination via ``page[after]``. Filter by status (``SUCCEEDED`` / ``FAILED`` / ``FILTERED_OUT`` / ``SKIPPED_DO_NOT_FORWARD``, case-insensitive) or by a ``created_at`` range using the platform's interval notation (``[2026-01-01T00:00:00Z,*)``). Reads do not require the entitlement — a downgraded account can still inspect historical deliveries from when the forwarder was active.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
opts = {
  filter_status: 'filter_status_example', # String | 
  filter_created_at: 'filter_created_at_example', # String | 
  filter_event_id: 'filter_event_id_example', # String | 
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
}

begin
  # List Forwarder Deliveries
  result = api_instance.list_forwarder_deliveries(forwarder_id, opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->list_forwarder_deliveries: #{e}"
end
```

#### Using the list_forwarder_deliveries_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderDeliveryListResponse>, Integer, Hash)> list_forwarder_deliveries_with_http_info(forwarder_id, opts)

```ruby
begin
  # List Forwarder Deliveries
  data, status_code, headers = api_instance.list_forwarder_deliveries_with_http_info(forwarder_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderDeliveryListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->list_forwarder_deliveries_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |
| **filter_status** | **String** |  | [optional] |
| **filter_created_at** | **String** |  | [optional] |
| **filter_event_id** | **String** |  | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

### Return type

[**ForwarderDeliveryListResponse**](ForwarderDeliveryListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_forwarders

> <ForwarderListResponse> list_forwarders(opts)

List Forwarders

List forwarders for the authenticated account.  Reads do not require the entitlement — a downgraded account can still inspect what they configured, they just can't create new ones.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
opts = {
  filter_forwarder_type: 'filter_forwarder_type_example', # String | 
  filter_enabled: true, # Boolean | 
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
}

begin
  # List Forwarders
  result = api_instance.list_forwarders(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->list_forwarders: #{e}"
end
```

#### Using the list_forwarders_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderListResponse>, Integer, Hash)> list_forwarders_with_http_info(opts)

```ruby
begin
  # List Forwarders
  data, status_code, headers = api_instance.list_forwarders_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->list_forwarders_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_forwarder_type** | **String** |  | [optional] |
| **filter_enabled** | **Boolean** |  | [optional] |
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

### Return type

[**ForwarderListResponse**](ForwarderListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## retry_failed_forwarder_deliveries

> <RetryFailedDeliveriesSummary> retry_failed_forwarder_deliveries(forwarder_id)

Retry Failed Forwarder Deliveries

Retry every failed delivery for the forwarder.  For each failed delivery row, re-attempt with the latest forwarder configuration and the original event payload. Returns counts.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Retry Failed Forwarder Deliveries
  result = api_instance.retry_failed_forwarder_deliveries(forwarder_id)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->retry_failed_forwarder_deliveries: #{e}"
end
```

#### Using the retry_failed_forwarder_deliveries_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RetryFailedDeliveriesSummary>, Integer, Hash)> retry_failed_forwarder_deliveries_with_http_info(forwarder_id)

```ruby
begin
  # Retry Failed Forwarder Deliveries
  data, status_code, headers = api_instance.retry_failed_forwarder_deliveries_with_http_info(forwarder_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RetryFailedDeliveriesSummary>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->retry_failed_forwarder_deliveries_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |

### Return type

[**RetryFailedDeliveriesSummary**](RetryFailedDeliveriesSummary.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## retry_forwarder_delivery

> <ForwarderDeliveryResponse> retry_forwarder_delivery(forwarder_id, delivery_id)

Retry Forwarder Delivery

Retry a single failed delivery. Returns the new delivery row with its outcome. Prior delivery rows are not modified.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
delivery_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Retry Forwarder Delivery
  result = api_instance.retry_forwarder_delivery(forwarder_id, delivery_id)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->retry_forwarder_delivery: #{e}"
end
```

#### Using the retry_forwarder_delivery_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderDeliveryResponse>, Integer, Hash)> retry_forwarder_delivery_with_http_info(forwarder_id, delivery_id)

```ruby
begin
  # Retry Forwarder Delivery
  data, status_code, headers = api_instance.retry_forwarder_delivery_with_http_info(forwarder_id, delivery_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderDeliveryResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->retry_forwarder_delivery_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |
| **delivery_id** | **String** |  |  |

### Return type

[**ForwarderDeliveryResponse**](ForwarderDeliveryResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_forwarder

> <ForwarderResponse> update_forwarder(forwarder_id, forwarder_response)

Update Forwarder

Full-replace update. PUT semantics — every field is overwritten.  The GET path returns plaintext header values, so the standard get-mutate-put round-trip (ADR-014) preserves secrets without any extra work from the caller: GET, change one field, PUT the result.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::ForwardersApi.new
forwarder_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
forwarder_response = SmplkitGeneratedClient::Audit::ForwarderResponse.new({data: SmplkitGeneratedClient::Audit::ForwarderResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Audit::Forwarder.new({name: 'name_example', forwarder_type: SmplkitGeneratedClient::Audit::ForwarderType::HTTP, http: SmplkitGeneratedClient::Audit::ForwarderHttp.new({url: 'url_example'})})})}) # ForwarderResponse | 

begin
  # Update Forwarder
  result = api_instance.update_forwarder(forwarder_id, forwarder_response)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->update_forwarder: #{e}"
end
```

#### Using the update_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderResponse>, Integer, Hash)> update_forwarder_with_http_info(forwarder_id, forwarder_response)

```ruby
begin
  # Update Forwarder
  data, status_code, headers = api_instance.update_forwarder_with_http_info(forwarder_id, forwarder_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ForwarderResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->update_forwarder_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **forwarder_id** | **String** |  |  |
| **forwarder_response** | [**ForwarderResponse**](ForwarderResponse.md) |  |  |

### Return type

[**ForwarderResponse**](ForwarderResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

