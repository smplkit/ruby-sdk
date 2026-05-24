# SmplkitGeneratedClient::Config::ConfigsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk_register_configs**](ConfigsApi.md#bulk_register_configs) | **POST** /api/v1/configs/bulk | Bulk Register Configs |
| [**create_config**](ConfigsApi.md#create_config) | **POST** /api/v1/configs | Create Config |
| [**delete_config**](ConfigsApi.md#delete_config) | **DELETE** /api/v1/configs/{id} | Delete Config |
| [**get_config**](ConfigsApi.md#get_config) | **GET** /api/v1/configs/{id} | Get Config |
| [**list_configs**](ConfigsApi.md#list_configs) | **GET** /api/v1/configs | List Configs |
| [**update_config**](ConfigsApi.md#update_config) | **PUT** /api/v1/configs/{id} | Update Config |


## bulk_register_configs

> <ConfigBulkResponse> bulk_register_configs(config_bulk_request)

Bulk Register Configs

Register configs declared by an SDK.  For each item in the batch: - If no config with that key exists, create one with ``managed=false``   (auto-discovered) using the declared items, parent, name, and   description. - If a config with that key already exists, leave the config row   untouched (per ADR-024 §2.9). - Either way, upsert a ``config_source`` row for ``(config, service,   environment)`` and refresh its ``last_seen`` timestamp.  Per ADR-022 §2.11 rule 2 this endpoint never enforces ``config.managed_configurations`` — discovered configs do not consume a managed slot.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
config_bulk_request = SmplkitGeneratedClient::Config::ConfigBulkRequest.new({configs: [SmplkitGeneratedClient::Config::ConfigBulkItem.new({id: 'id_example'})]}) # ConfigBulkRequest | 

begin
  # Bulk Register Configs
  result = api_instance.bulk_register_configs(config_bulk_request)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->bulk_register_configs: #{e}"
end
```

#### Using the bulk_register_configs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigBulkResponse>, Integer, Hash)> bulk_register_configs_with_http_info(config_bulk_request)

```ruby
begin
  # Bulk Register Configs
  data, status_code, headers = api_instance.bulk_register_configs_with_http_info(config_bulk_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigBulkResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->bulk_register_configs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **config_bulk_request** | [**ConfigBulkRequest**](ConfigBulkRequest.md) |  |  |

### Return type

[**ConfigBulkResponse**](ConfigBulkResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## create_config

> <ConfigResponse> create_config(config_create_request)

Create Config

Create a config for this account.  The caller supplies the config's key as `data.id`. Keys are unique within an account and immutable for the lifetime of the config.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
config_create_request = SmplkitGeneratedClient::Config::ConfigCreateRequest.new({data: SmplkitGeneratedClient::Config::ConfigCreateResource.new({id: 'id_example', type: 'config', attributes: SmplkitGeneratedClient::Config::Config.new({name: 'name_example'})})}) # ConfigCreateRequest | 

begin
  # Create Config
  result = api_instance.create_config(config_create_request)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->create_config: #{e}"
end
```

#### Using the create_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> create_config_with_http_info(config_create_request)

```ruby
begin
  # Create Config
  data, status_code, headers = api_instance.create_config_with_http_info(config_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->create_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **config_create_request** | [**ConfigCreateRequest**](ConfigCreateRequest.md) |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_config

> delete_config(id)

Delete Config

Delete a config by its key.  A config that is referenced as `parent` by another config cannot be deleted; reparent or remove the parent reference on every child first. The `common` config cannot be deleted.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 

begin
  # Delete Config
  api_instance.delete_config(id)
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->delete_config: #{e}"
end
```

#### Using the delete_config_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_config_with_http_info(id)

```ruby
begin
  # Delete Config
  data, status_code, headers = api_instance.delete_config_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->delete_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## get_config

> <ConfigResponse> get_config(id)

Get Config

Retrieve a single config by its key.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 

begin
  # Get Config
  result = api_instance.get_config(id)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->get_config: #{e}"
end
```

#### Using the get_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> get_config_with_http_info(id)

```ruby
begin
  # Get Config
  data, status_code, headers = api_instance.get_config_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->get_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_configs

> <ConfigListResponse> list_configs(opts)

List Configs

List configs for this account.  Default sort is `key` ascending. Pass `filter[parent]=<parent_key>` to return only the direct children of a specific config, `filter[search]=<term>` to filter by a case-insensitive substring against `key` or `name`, or `filter[managed]=true|false` to restrict to managed or discovered configs respectively.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
opts = {
  filter_parent: 'filter_parent_example', # String | 
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against the config `key` and `name`. A config is returned if either field contains the search term.
  filter_managed: true, # Boolean | Restrict the result to managed (`true`) or discovered (`false`) configs. Omit to return both. Configs created via the console or `POST /api/v1/configs` are managed; configs registered via `POST /api/v1/configs/bulk` start out discovered.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Configs
  result = api_instance.list_configs(opts)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->list_configs: #{e}"
end
```

#### Using the list_configs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigListResponse>, Integer, Hash)> list_configs_with_http_info(opts)

```ruby
begin
  # List Configs
  data, status_code, headers = api_instance.list_configs_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigListResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->list_configs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_parent** | **String** |  | [optional] |
| **filter_search** | **String** | Case-insensitive substring match against the config &#x60;key&#x60; and &#x60;name&#x60;. A config is returned if either field contains the search term. | [optional] |
| **filter_managed** | **Boolean** | Restrict the result to managed (&#x60;true&#x60;) or discovered (&#x60;false&#x60;) configs. Omit to return both. Configs created via the console or &#x60;POST /api/v1/configs&#x60; are managed; configs registered via &#x60;POST /api/v1/configs/bulk&#x60; start out discovered. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**ConfigListResponse**](ConfigListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_config

> <ConfigResponse> update_config(id, config_request)

Update Config

Replace a config entirely. Every writable field is overwritten.

### Examples

```ruby
require 'time'
require 'smplkit_config_client'
# setup authorization
SmplkitGeneratedClient::Config.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Config::ConfigsApi.new
id = 'id_example' # String | 
config_request = SmplkitGeneratedClient::Config::ConfigRequest.new({data: SmplkitGeneratedClient::Config::ConfigResource.new({type: 'config', attributes: SmplkitGeneratedClient::Config::Config.new({name: 'name_example'})})}) # ConfigRequest | 

begin
  # Update Config
  result = api_instance.update_config(id, config_request)
  p result
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->update_config: #{e}"
end
```

#### Using the update_config_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ConfigResponse>, Integer, Hash)> update_config_with_http_info(id, config_request)

```ruby
begin
  # Update Config
  data, status_code, headers = api_instance.update_config_with_http_info(id, config_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ConfigResponse>
rescue SmplkitGeneratedClient::Config::ApiError => e
  puts "Error when calling ConfigsApi->update_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **config_request** | [**ConfigRequest**](ConfigRequest.md) |  |  |

### Return type

[**ConfigResponse**](ConfigResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

