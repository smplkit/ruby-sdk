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

> <ForwarderResponse> create_forwarder(forwarder_create_request)

Create Forwarder

Create a forwarder for this account.  The caller supplies the forwarder's key as `data.id`. Keys are unique within an account and immutable for the lifetime of the forwarder.

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
forwarder_create_request = SmplkitGeneratedClient::Audit::ForwarderCreateRequest.new({data: SmplkitGeneratedClient::Audit::ForwarderCreateResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Audit::Forwarder.new({name: 'name_example', forwarder_type: SmplkitGeneratedClient::Audit::ForwarderType::DATADOG, configuration: SmplkitGeneratedClient::Audit::HttpConfiguration.new({url: 'url_example'})})})}) # ForwarderCreateRequest | 

begin
  # Create Forwarder
  result = api_instance.create_forwarder(forwarder_create_request)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->create_forwarder: #{e}"
end
```

#### Using the create_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderResponse>, Integer, Hash)> create_forwarder_with_http_info(forwarder_create_request)

```ruby
begin
  # Create Forwarder
  data, status_code, headers = api_instance.create_forwarder_with_http_info(forwarder_create_request)
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
| **forwarder_create_request** | [**ForwarderCreateRequest**](ForwarderCreateRequest.md) |  |  |

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

Delete a forwarder.  Past delivery log entries are retained. A new forwarder may be created later under the same id.

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
forwarder_id = 'forwarder_id_example' # String | 

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

Send a test HTTP request to a forwarder destination and return the result.  Useful for verifying a destination URL, credentials, or transform before saving the forwarder. The same network-safety rules that apply to live deliveries (private/internal address blocking, port allowlist) apply here.

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

Retrieve a single forwarder by id.  Header values are returned in plaintext so the resource can be round-tripped with `GET`, mutate, `PUT` without re-entering secrets.

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
forwarder_id = 'forwarder_id_example' # String | 

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

List delivery log entries for a forwarder.  Default sort is `-created_at` (newest first). Filter by `status` (`SUCCEEDED` or `FAILED`, case-insensitive), by `event_id`, or by a `created_at` range using interval notation (e.g. `[2026-01-01T00:00:00Z,*)`).

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
forwarder_id = 'forwarder_id_example' # String | 
opts = {
  filter_status: 'filter_status_example', # String | 
  filter_created_at: 'filter_created_at_example', # String | 
  filter_event_id: 'filter_event_id_example', # String | 
  page_size: 56, # Integer | 
  page_after: 'page_after_example', # String | 
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `-created_at`. Allowed values: `created_at`, `-created_at`.
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
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-created_at&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;. | [optional][default to &#39;-created_at&#39;] |

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

List forwarders for this account.  Default sort is `-created_at` (newest first).

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
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `-created_at`. Allowed values: `created_at`, `-created_at`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
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
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-created_at&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;-created_at&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

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

Retry every failed delivery for this forwarder.  Each failed delivery is re-attempted using the forwarder's current configuration and the original event. Returns the counts.

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
forwarder_id = 'forwarder_id_example' # String | 

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

Retry a single failed delivery.  Returns the new delivery log entry. The prior entry is left in place.

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
forwarder_id = 'forwarder_id_example' # String | 
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

> <ForwarderResponse> update_forwarder(forwarder_id, forwarder_request)

Update Forwarder

Replace an existing forwarder. Every writable field is overwritten.

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
forwarder_id = 'forwarder_id_example' # String | 
forwarder_request = SmplkitGeneratedClient::Audit::ForwarderRequest.new({data: SmplkitGeneratedClient::Audit::ForwarderResource.new({attributes: SmplkitGeneratedClient::Audit::Forwarder.new({name: 'name_example', forwarder_type: SmplkitGeneratedClient::Audit::ForwarderType::DATADOG, configuration: SmplkitGeneratedClient::Audit::HttpConfiguration.new({url: 'url_example'})})})}) # ForwarderRequest | 

begin
  # Update Forwarder
  result = api_instance.update_forwarder(forwarder_id, forwarder_request)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling ForwardersApi->update_forwarder: #{e}"
end
```

#### Using the update_forwarder_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ForwarderResponse>, Integer, Hash)> update_forwarder_with_http_info(forwarder_id, forwarder_request)

```ruby
begin
  # Update Forwarder
  data, status_code, headers = api_instance.update_forwarder_with_http_info(forwarder_id, forwarder_request)
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
| **forwarder_request** | [**ForwarderRequest**](ForwarderRequest.md) |  |  |

### Return type

[**ForwarderResponse**](ForwarderResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

