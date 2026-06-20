# SmplkitGeneratedClient::Jobs::RetryPoliciesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_retry_policy**](RetryPoliciesApi.md#create_retry_policy) | **POST** /api/v1/retry-policies | Create Retry Policy |
| [**delete_retry_policy**](RetryPoliciesApi.md#delete_retry_policy) | **DELETE** /api/v1/retry-policies/{policy_id} | Delete Retry Policy |
| [**get_retry_policy**](RetryPoliciesApi.md#get_retry_policy) | **GET** /api/v1/retry-policies/{policy_id} | Get Retry Policy |
| [**list_retry_policies**](RetryPoliciesApi.md#list_retry_policies) | **GET** /api/v1/retry-policies | List Retry Policies |
| [**update_retry_policy**](RetryPoliciesApi.md#update_retry_policy) | **PUT** /api/v1/retry-policies/{policy_id} | Update Retry Policy |


## create_retry_policy

> <RetryPolicyResponse> create_retry_policy(retry_policy_create_request)

Create Retry Policy

Create a retry policy for this account.  The caller supplies the policy's id as `data.id`. Ids are unique within an account and immutable. `Default` is reserved for the built-in policy and cannot be created.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new
retry_policy_create_request = SmplkitGeneratedClient::Jobs::RetryPolicyCreateRequest.new({data: SmplkitGeneratedClient::Jobs::RetryPolicyCreateResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Jobs::RetryPolicy.new({name: 'name_example', max_retries: 37, backoff: 'fixed', delay_seconds: 37})})}) # RetryPolicyCreateRequest | 

begin
  # Create Retry Policy
  result = api_instance.create_retry_policy(retry_policy_create_request)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->create_retry_policy: #{e}"
end
```

#### Using the create_retry_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RetryPolicyResponse>, Integer, Hash)> create_retry_policy_with_http_info(retry_policy_create_request)

```ruby
begin
  # Create Retry Policy
  data, status_code, headers = api_instance.create_retry_policy_with_http_info(retry_policy_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RetryPolicyResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->create_retry_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **retry_policy_create_request** | [**RetryPolicyCreateRequest**](RetryPolicyCreateRequest.md) |  |  |

### Return type

[**RetryPolicyResponse**](RetryPolicyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_retry_policy

> delete_retry_policy(policy_id)

Delete Retry Policy

Delete a retry policy.  The built-in `Default` policy cannot be deleted (`403`). A policy still referenced by any job — at the base level or in a per-environment override — cannot be deleted (`409`); the error lists the referencing job ids under `meta.referencing_jobs` so they can be reassigned to `Default` first.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new
policy_id = 'policy_id_example' # String | 

begin
  # Delete Retry Policy
  api_instance.delete_retry_policy(policy_id)
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->delete_retry_policy: #{e}"
end
```

#### Using the delete_retry_policy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_retry_policy_with_http_info(policy_id)

```ruby
begin
  # Delete Retry Policy
  data, status_code, headers = api_instance.delete_retry_policy_with_http_info(policy_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->delete_retry_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policy_id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## get_retry_policy

> <RetryPolicyResponse> get_retry_policy(policy_id)

Get Retry Policy

Retrieve a single retry policy by its id.  `Default` returns the built-in do-not-retry policy.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new
policy_id = 'policy_id_example' # String | 

begin
  # Get Retry Policy
  result = api_instance.get_retry_policy(policy_id)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->get_retry_policy: #{e}"
end
```

#### Using the get_retry_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RetryPolicyResponse>, Integer, Hash)> get_retry_policy_with_http_info(policy_id)

```ruby
begin
  # Get Retry Policy
  data, status_code, headers = api_instance.get_retry_policy_with_http_info(policy_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RetryPolicyResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->get_retry_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policy_id** | **String** |  |  |

### Return type

[**RetryPolicyResponse**](RetryPolicyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_retry_policies

> <RetryPolicyListResponse> list_retry_policies(opts)

List Retry Policies

List this account's retry policies.  Default sort is `name` ascending. Sort by `name`, `created_at`, or `updated_at` (prefix `-` for descending). The built-in `Default` policy is not included here — it always exists and is retrievable at `/retry-policies/Default`.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new
opts = {
  filter_name: 'filter_name_example', # String | Case-insensitive substring match on the policy `name` (matches when the name contains the given text).
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `created_at`, `-created_at`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Retry Policies
  result = api_instance.list_retry_policies(opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->list_retry_policies: #{e}"
end
```

#### Using the list_retry_policies_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RetryPolicyListResponse>, Integer, Hash)> list_retry_policies_with_http_info(opts)

```ruby
begin
  # List Retry Policies
  data, status_code, headers = api_instance.list_retry_policies_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RetryPolicyListResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->list_retry_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_name** | **String** | Case-insensitive substring match on the policy &#x60;name&#x60; (matches when the name contains the given text). | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;name&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**RetryPolicyListResponse**](RetryPolicyListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_retry_policy

> <RetryPolicyResponse> update_retry_policy(policy_id, retry_policy_request)

Update Retry Policy

Replace an existing retry policy. Every writable field is overwritten.  The built-in `Default` policy cannot be modified.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RetryPoliciesApi.new
policy_id = 'policy_id_example' # String | 
retry_policy_request = SmplkitGeneratedClient::Jobs::RetryPolicyRequest.new({data: SmplkitGeneratedClient::Jobs::RetryPolicyResource.new({attributes: SmplkitGeneratedClient::Jobs::RetryPolicy.new({name: 'name_example', max_retries: 37, backoff: 'fixed', delay_seconds: 37})})}) # RetryPolicyRequest | 

begin
  # Update Retry Policy
  result = api_instance.update_retry_policy(policy_id, retry_policy_request)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->update_retry_policy: #{e}"
end
```

#### Using the update_retry_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RetryPolicyResponse>, Integer, Hash)> update_retry_policy_with_http_info(policy_id, retry_policy_request)

```ruby
begin
  # Update Retry Policy
  data, status_code, headers = api_instance.update_retry_policy_with_http_info(policy_id, retry_policy_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RetryPolicyResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RetryPoliciesApi->update_retry_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **policy_id** | **String** |  |  |
| **retry_policy_request** | [**RetryPolicyRequest**](RetryPolicyRequest.md) |  |  |

### Return type

[**RetryPolicyResponse**](RetryPolicyResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

