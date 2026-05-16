# SmplkitGeneratedClient::App::UsersApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**get_current_user**](UsersApi.md#get_current_user) | **GET** /api/v1/users/current | Get Current User |
| [**get_user**](UsersApi.md#get_user) | **GET** /api/v1/users/{id} | Get User |
| [**get_user_settings**](UsersApi.md#get_user_settings) | **GET** /api/v1/users/current/settings | Get User Settings |
| [**list_users**](UsersApi.md#list_users) | **GET** /api/v1/users | List Users |
| [**put_user_settings**](UsersApi.md#put_user_settings) | **PUT** /api/v1/users/current/settings | Update User Settings |
| [**put_user_settings_key**](UsersApi.md#put_user_settings_key) | **PUT** /api/v1/users/current/settings/{key} | Update User Setting by Key |
| [**remove_user**](UsersApi.md#remove_user) | **DELETE** /api/v1/users/{id} | Remove User |
| [**update_current_user**](UsersApi.md#update_current_user) | **PUT** /api/v1/users/current | Update Current User |
| [**update_user_role**](UsersApi.md#update_user_role) | **PUT** /api/v1/users/{id} | Update User Role |


## get_current_user

> <UserResponse> get_current_user

Get Current User

Return the currently authenticated user. ``role`` and ``account`` are populated when the user has a membership; both are null when the caller is authenticated but has no account yet — e.g. a returning user who has just accepted an invitation email.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new

begin
  # Get Current User
  result = api_instance.get_current_user
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_current_user: #{e}"
end
```

#### Using the get_current_user_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UserResponse>, Integer, Hash)> get_current_user_with_http_info

```ruby
begin
  # Get Current User
  data, status_code, headers = api_instance.get_current_user_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UserResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_current_user_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_user

> <UserResponse> get_user(id)

Get User

Return a user by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get User
  result = api_instance.get_user(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_user: #{e}"
end
```

#### Using the get_user_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UserResponse>, Integer, Hash)> get_user_with_http_info(id)

```ruby
begin
  # Get User
  data, status_code, headers = api_instance.get_user_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UserResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_user_settings

> Hash&lt;String, Object&gt; get_user_settings

Get User Settings

Return the current user's settings as plain JSON.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new

begin
  # Get User Settings
  result = api_instance.get_user_settings
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_user_settings: #{e}"
end
```

#### Using the get_user_settings_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Hash&lt;String, Object&gt;, Integer, Hash)> get_user_settings_with_http_info

```ruby
begin
  # Get User Settings
  data, status_code, headers = api_instance.get_user_settings_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Hash&lt;String, Object&gt;
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->get_user_settings_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

**Hash&lt;String, Object&gt;**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_users

> <UserListResponse> list_users(opts)

List Users

List users in the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
opts = {
  filter_account: 'filter_account_example', # String | 
  filter_email: 'filter_email_example', # String | 
  filter_search: 'filter_search_example', # String | Case-insensitive substring match against display_name and email. If the value is a valid UUID, also matches user id exactly.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `email`. Allowed values: `created_at`, `-created_at`, `display_name`, `-display_name`, `email`, `-email`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Users
  result = api_instance.list_users(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->list_users: #{e}"
end
```

#### Using the list_users_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UserListResponse>, Integer, Hash)> list_users_with_http_info(opts)

```ruby
begin
  # List Users
  data, status_code, headers = api_instance.list_users_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UserListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->list_users_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_account** | **String** |  | [optional] |
| **filter_email** | **String** |  | [optional] |
| **filter_search** | **String** | Case-insensitive substring match against display_name and email. If the value is a valid UUID, also matches user id exactly. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;email&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;display_name&#x60;, &#x60;-display_name&#x60;, &#x60;email&#x60;, &#x60;-email&#x60;. | [optional][default to &#39;email&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**UserListResponse**](UserListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## put_user_settings

> Hash&lt;String, Object&gt; put_user_settings

Update User Settings

Replace the current user's settings with the provided JSON object.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new

begin
  # Update User Settings
  result = api_instance.put_user_settings
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->put_user_settings: #{e}"
end
```

#### Using the put_user_settings_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Hash&lt;String, Object&gt;, Integer, Hash)> put_user_settings_with_http_info

```ruby
begin
  # Update User Settings
  data, status_code, headers = api_instance.put_user_settings_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Hash&lt;String, Object&gt;
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->put_user_settings_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

**Hash&lt;String, Object&gt;**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## put_user_settings_key

> Hash&lt;String, Object&gt; put_user_settings_key(key)

Update User Setting by Key

Set a single key in the current user's settings. The key is stored as a flat literal key (dot-notation is NOT expanded to nested paths). Returns the full updated settings object.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
key = 'key_example' # String | 

begin
  # Update User Setting by Key
  result = api_instance.put_user_settings_key(key)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->put_user_settings_key: #{e}"
end
```

#### Using the put_user_settings_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Hash&lt;String, Object&gt;, Integer, Hash)> put_user_settings_key_with_http_info(key)

```ruby
begin
  # Update User Setting by Key
  data, status_code, headers = api_instance.put_user_settings_key_with_http_info(key)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Hash&lt;String, Object&gt;
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->put_user_settings_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key** | **String** |  |  |

### Return type

**Hash&lt;String, Object&gt;**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## remove_user

> remove_user(id)

Remove User

Remove a user from the account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Remove User
  api_instance.remove_user(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->remove_user: #{e}"
end
```

#### Using the remove_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> remove_user_with_http_info(id)

```ruby
begin
  # Remove User
  data, status_code, headers = api_instance.remove_user_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->remove_user_with_http_info: #{e}"
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


## update_current_user

> <UserResponse> update_current_user(user_request)

Update Current User

Update the currently authenticated user's profile.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
user_request = SmplkitGeneratedClient::App::UserRequest.new({data: SmplkitGeneratedClient::App::UserResource.new({type: 'user', attributes: SmplkitGeneratedClient::App::User.new({display_name: 'display_name_example'})})}) # UserRequest | 

begin
  # Update Current User
  result = api_instance.update_current_user(user_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->update_current_user: #{e}"
end
```

#### Using the update_current_user_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UserResponse>, Integer, Hash)> update_current_user_with_http_info(user_request)

```ruby
begin
  # Update Current User
  data, status_code, headers = api_instance.update_current_user_with_http_info(user_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UserResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->update_current_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user_request** | [**UserRequest**](UserRequest.md) |  |  |

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## update_user_role

> <UserResponse> update_user_role(id, user_request)

Update User Role

Update a user's role in the account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::UsersApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
user_request = SmplkitGeneratedClient::App::UserRequest.new({data: SmplkitGeneratedClient::App::UserResource.new({type: 'user', attributes: SmplkitGeneratedClient::App::User.new({display_name: 'display_name_example'})})}) # UserRequest | 

begin
  # Update User Role
  result = api_instance.update_user_role(id, user_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->update_user_role: #{e}"
end
```

#### Using the update_user_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UserResponse>, Integer, Hash)> update_user_role_with_http_info(id, user_request)

```ruby
begin
  # Update User Role
  data, status_code, headers = api_instance.update_user_role_with_http_info(id, user_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UserResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling UsersApi->update_user_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **user_request** | [**UserRequest**](UserRequest.md) |  |  |

### Return type

[**UserResponse**](UserResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

