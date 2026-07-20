# SmplkitGeneratedClient::App::GroupsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_group**](GroupsApi.md#create_group) | **POST** /api/v1/groups | Create Group |
| [**delete_group**](GroupsApi.md#delete_group) | **DELETE** /api/v1/groups/{id} | Delete Group |
| [**get_group**](GroupsApi.md#get_group) | **GET** /api/v1/groups/{id} | Get Group |
| [**list_groups**](GroupsApi.md#list_groups) | **GET** /api/v1/groups | List Groups |
| [**update_group**](GroupsApi.md#update_group) | **PUT** /api/v1/groups/{id} | Update Group |


## create_group

> <GroupResponse> create_group(group_create_request)

Create Group

Create an Environment Access Group. The caller provides the group id (a kebab-case key, unique within the account) in the request body. The id is immutable thereafter. Returns `409` if a group with that id already exists, or `422` if `managed_environments` is not exactly `['*']` or a subset of the account's standard environment keys.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupsApi.new
group_create_request = SmplkitGeneratedClient::App::GroupCreateRequest.new({data: SmplkitGeneratedClient::App::GroupCreateResource.new({id: 'id_example', type: 'group', attributes: SmplkitGeneratedClient::App::Group.new({name: 'name_example'})})}) # GroupCreateRequest | 

begin
  # Create Group
  result = api_instance.create_group(group_create_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->create_group: #{e}"
end
```

#### Using the create_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupResponse>, Integer, Hash)> create_group_with_http_info(group_create_request)

```ruby
begin
  # Create Group
  data, status_code, headers = api_instance.create_group_with_http_info(group_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->create_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_create_request** | [**GroupCreateRequest**](GroupCreateRequest.md) |  |  |

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_group

> delete_group(id)

Delete Group

Delete a group by id. Returns `409` for the reserved `default` group, which every account requires. Deleting a group also cascades to its memberships.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupsApi.new
id = 'id_example' # String | 

begin
  # Delete Group
  api_instance.delete_group(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->delete_group: #{e}"
end
```

#### Using the delete_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_group_with_http_info(id)

```ruby
begin
  # Delete Group
  data, status_code, headers = api_instance.delete_group_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->delete_group_with_http_info: #{e}"
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
- **Accept**: application/vnd.api+json


## get_group

> <GroupResponse> get_group(id)

Get Group

Return a group by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupsApi.new
id = 'id_example' # String | 

begin
  # Get Group
  result = api_instance.get_group(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->get_group: #{e}"
end
```

#### Using the get_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupResponse>, Integer, Hash)> get_group_with_http_info(id)

```ruby
begin
  # Get Group
  data, status_code, headers = api_instance.get_group_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->get_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_groups

> <GroupListResponse> list_groups(opts)

List Groups

List Environment Access Groups for the authenticated account. `filter[search]` does a case-insensitive substring match against the group `key` and `name`.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupsApi.new
opts = {
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against the group `key` and `name`. A group is returned if either field contains the search term.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `created_at`, `-created_at`, `key`, `-key`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Groups
  result = api_instance.list_groups(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->list_groups: #{e}"
end
```

#### Using the list_groups_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupListResponse>, Integer, Hash)> list_groups_with_http_info(opts)

```ruby
begin
  # List Groups
  data, status_code, headers = api_instance.list_groups_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->list_groups_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_search** | **String** | Case-insensitive substring match against the group &#x60;key&#x60; and &#x60;name&#x60;. A group is returned if either field contains the search term. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;key&#x60;, &#x60;-key&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;name&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**GroupListResponse**](GroupListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_group

> <GroupResponse> update_group(id, group_request)

Update Group

Update a group's name, description, and managed environments. Whole-resource semantics — submit every writable attribute. For the reserved `default` group, `managed_environments` may be changed (this is the lever that narrows the account-wide baseline), but renaming or other identity changes are rejected with `409`. Invalid `managed_environments` is `422`.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupsApi.new
id = 'id_example' # String | 
group_request = SmplkitGeneratedClient::App::GroupRequest.new({data: SmplkitGeneratedClient::App::GroupResource.new({type: 'group', attributes: SmplkitGeneratedClient::App::Group.new({name: 'name_example'})})}) # GroupRequest | 

begin
  # Update Group
  result = api_instance.update_group(id, group_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->update_group: #{e}"
end
```

#### Using the update_group_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupResponse>, Integer, Hash)> update_group_with_http_info(id, group_request)

```ruby
begin
  # Update Group
  data, status_code, headers = api_instance.update_group_with_http_info(id, group_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupsApi->update_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **group_request** | [**GroupRequest**](GroupRequest.md) |  |  |

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

