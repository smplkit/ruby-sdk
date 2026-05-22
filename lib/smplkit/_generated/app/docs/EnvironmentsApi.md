# SmplkitGeneratedClient::App::EnvironmentsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_environment**](EnvironmentsApi.md#create_environment) | **POST** /api/v1/environments | Create Environment |
| [**delete_environment**](EnvironmentsApi.md#delete_environment) | **DELETE** /api/v1/environments/{id} | Delete Environment |
| [**get_environment**](EnvironmentsApi.md#get_environment) | **GET** /api/v1/environments/{id} | Get Environment |
| [**get_environment_usage**](EnvironmentsApi.md#get_environment_usage) | **GET** /api/v1/environments/{id}/usage | Report Environment Usage |
| [**list_environments**](EnvironmentsApi.md#list_environments) | **GET** /api/v1/environments | List Environments |
| [**update_environment**](EnvironmentsApi.md#update_environment) | **PUT** /api/v1/environments/{id} | Update Environment |


## create_environment

> <EnvironmentResponse> create_environment(environment_request)

Create Environment

Create a new environment. The caller provides the id (key) in the request body.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
environment_request = SmplkitGeneratedClient::App::EnvironmentRequest.new({data: SmplkitGeneratedClient::App::EnvironmentResource.new({type: 'environment', attributes: SmplkitGeneratedClient::App::Environment.new({name: 'name_example'})})}) # EnvironmentRequest | 

begin
  # Create Environment
  result = api_instance.create_environment(environment_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->create_environment: #{e}"
end
```

#### Using the create_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> create_environment_with_http_info(environment_request)

```ruby
begin
  # Create Environment
  data, status_code, headers = api_instance.create_environment_with_http_info(environment_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->create_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **environment_request** | [**EnvironmentRequest**](EnvironmentRequest.md) |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_environment

> delete_environment(id, opts)

Delete Environment

Delete an environment by id. When `cascade=true` is set, also remove every per-environment reference held by flags, configs, and loggers in the corresponding services before deleting the environment row. The default `cascade=false` deletes only the environment row, leaving downstream references in place.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 
opts = {
  cascade: true # Boolean | When `true`, remove every flag rule, env-level flag default, config override, and logger override scoped to this environment before deleting the environment row.
}

begin
  # Delete Environment
  api_instance.delete_environment(id, opts)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->delete_environment: #{e}"
end
```

#### Using the delete_environment_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_environment_with_http_info(id, opts)

```ruby
begin
  # Delete Environment
  data, status_code, headers = api_instance.delete_environment_with_http_info(id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->delete_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **cascade** | **Boolean** | When &#x60;true&#x60;, remove every flag rule, env-level flag default, config override, and logger override scoped to this environment before deleting the environment row. | [optional][default to false] |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_environment

> <EnvironmentResponse> get_environment(id)

Get Environment

Return an environment by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 

begin
  # Get Environment
  result = api_instance.get_environment(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment: #{e}"
end
```

#### Using the get_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> get_environment_with_http_info(id)

```ruby
begin
  # Get Environment
  data, status_code, headers = api_instance.get_environment_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_environment_usage

> <EnvironmentUsageResponse> get_environment_usage(id)

Report Environment Usage

Report how many flag rules, env-level flag defaults, config overrides, and logger overrides reference this environment. Used by the console's delete dialog so the user can see what would survive a non-cascading delete.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 

begin
  # Report Environment Usage
  result = api_instance.get_environment_usage(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment_usage: #{e}"
end
```

#### Using the get_environment_usage_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentUsageResponse>, Integer, Hash)> get_environment_usage_with_http_info(id)

```ruby
begin
  # Report Environment Usage
  data, status_code, headers = api_instance.get_environment_usage_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentUsageResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->get_environment_usage_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**EnvironmentUsageResponse**](EnvironmentUsageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_environments

> <EnvironmentListResponse> list_environments(opts)

List Environments

List all environments for the authenticated account. `filter[search]` does a case-insensitive substring match against the environment `key` and `name`. `filter[classification]` narrows the result to one classification (`STANDARD` or `AD_HOC`). `filter[managed]` narrows by managed state (`true` or `false`).

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
opts = {
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against the environment `key` and `name`. An environment is returned if either field contains the search term.
  filter_classification: 'filter_classification_example', # String | Narrow the result to environments with the given classification. One of `STANDARD` or `AD_HOC`.
  filter_managed: true, # Boolean | Narrow the result to managed (`true`) or unmanaged (`false`) environments. Omit to return both.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Environments
  result = api_instance.list_environments(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->list_environments: #{e}"
end
```

#### Using the list_environments_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentListResponse>, Integer, Hash)> list_environments_with_http_info(opts)

```ruby
begin
  # List Environments
  data, status_code, headers = api_instance.list_environments_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->list_environments_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_search** | **String** | Case-insensitive substring match against the environment &#x60;key&#x60; and &#x60;name&#x60;. An environment is returned if either field contains the search term. | [optional] |
| **filter_classification** | **String** | Narrow the result to environments with the given classification. One of &#x60;STANDARD&#x60; or &#x60;AD_HOC&#x60;. | [optional] |
| **filter_managed** | **Boolean** | Narrow the result to managed (&#x60;true&#x60;) or unmanaged (&#x60;false&#x60;) environments. Omit to return both. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;name&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**EnvironmentListResponse**](EnvironmentListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_environment

> <EnvironmentResponse> update_environment(id, environment_request)

Update Environment

Update an environment by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::EnvironmentsApi.new
id = 'id_example' # String | 
environment_request = SmplkitGeneratedClient::App::EnvironmentRequest.new({data: SmplkitGeneratedClient::App::EnvironmentResource.new({type: 'environment', attributes: SmplkitGeneratedClient::App::Environment.new({name: 'name_example'})})}) # EnvironmentRequest | 

begin
  # Update Environment
  result = api_instance.update_environment(id, environment_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->update_environment: #{e}"
end
```

#### Using the update_environment_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EnvironmentResponse>, Integer, Hash)> update_environment_with_http_info(id, environment_request)

```ruby
begin
  # Update Environment
  data, status_code, headers = api_instance.update_environment_with_http_info(id, environment_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EnvironmentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling EnvironmentsApi->update_environment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **environment_request** | [**EnvironmentRequest**](EnvironmentRequest.md) |  |  |

### Return type

[**EnvironmentResponse**](EnvironmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

