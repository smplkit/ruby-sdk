# SmplkitGeneratedClient::App::AccountApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**delete_account**](AccountApi.md#delete_account) | **DELETE** /api/v1/accounts/current | Delete Current Account |
| [**get_account**](AccountApi.md#get_account) | **GET** /api/v1/accounts/current | Get Current Account |
| [**get_account_settings**](AccountApi.md#get_account_settings) | **GET** /api/v1/accounts/current/settings | Get Account Settings |
| [**put_account_settings**](AccountApi.md#put_account_settings) | **PUT** /api/v1/accounts/current/settings | Update Account Settings |
| [**update_account**](AccountApi.md#update_account) | **PUT** /api/v1/accounts/current | Update Current Account |
| [**wipe_account_data**](AccountApi.md#wipe_account_data) | **POST** /api/v1/accounts/current/actions/wipe | Wipe Account Data |


## delete_account

> delete_account

Delete Current Account

Permanently delete the current account and all associated data.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new

begin
  # Delete Current Account
  api_instance.delete_account
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->delete_account: #{e}"
end
```

#### Using the delete_account_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_account_with_http_info

```ruby
begin
  # Delete Current Account
  data, status_code, headers = api_instance.delete_account_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->delete_account_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_account

> <AccountResponse> get_account

Get Current Account

Return the account for the currently authenticated user.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new

begin
  # Get Current Account
  result = api_instance.get_account
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->get_account: #{e}"
end
```

#### Using the get_account_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AccountResponse>, Integer, Hash)> get_account_with_http_info

```ruby
begin
  # Get Current Account
  data, status_code, headers = api_instance.get_account_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AccountResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->get_account_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**AccountResponse**](AccountResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_account_settings

> Hash&lt;String, Object&gt; get_account_settings

Get Account Settings

Return the current account's settings as plain JSON.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new

begin
  # Get Account Settings
  result = api_instance.get_account_settings
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->get_account_settings: #{e}"
end
```

#### Using the get_account_settings_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Hash&lt;String, Object&gt;, Integer, Hash)> get_account_settings_with_http_info

```ruby
begin
  # Get Account Settings
  data, status_code, headers = api_instance.get_account_settings_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Hash&lt;String, Object&gt;
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->get_account_settings_with_http_info: #{e}"
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


## put_account_settings

> Hash&lt;String, Object&gt; put_account_settings(request_body)

Update Account Settings

Replace the current account's settings with the provided JSON object. Requires admin role.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new
request_body = { key: 3.56} # Hash<String, Object> | 

begin
  # Update Account Settings
  result = api_instance.put_account_settings(request_body)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->put_account_settings: #{e}"
end
```

#### Using the put_account_settings_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(Hash&lt;String, Object&gt;, Integer, Hash)> put_account_settings_with_http_info(request_body)

```ruby
begin
  # Update Account Settings
  data, status_code, headers = api_instance.put_account_settings_with_http_info(request_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => Hash&lt;String, Object&gt;
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->put_account_settings_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **request_body** | [**Hash&lt;String, Object&gt;**](Object.md) |  |  |

### Return type

**Hash&lt;String, Object&gt;**

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## update_account

> <AccountResponse> update_account(account_request)

Update Current Account

Update the current account's settings.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new
account_request = SmplkitGeneratedClient::App::AccountRequest.new({data: SmplkitGeneratedClient::App::AccountResource.new({type: 'account', attributes: SmplkitGeneratedClient::App::Account.new({name: 'name_example'})})}) # AccountRequest | 

begin
  # Update Current Account
  result = api_instance.update_account(account_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->update_account: #{e}"
end
```

#### Using the update_account_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AccountResponse>, Integer, Hash)> update_account_with_http_info(account_request)

```ruby
begin
  # Update Current Account
  data, status_code, headers = api_instance.update_account_with_http_info(account_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AccountResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->update_account_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **account_request** | [**AccountRequest**](AccountRequest.md) |  |  |

### Return type

[**AccountResponse**](AccountResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## wipe_account_data

> wipe_account_data(account_wipe_request)

Wipe Account Data

Delete every config, flag, logger, log group, context, context type, environment, and customer API key (except the caller's current key) on the account. The `common` config is preserved as a structural anchor but its items are reset. Requires `OWNER` role and a body of `{\"confirm\": true}` — any other value returns 400. Pass `\"generate_sample_data\": true` to re-seed the account with the standard sample dataset after the wipe (best-effort; seeding failures are logged but do not fail the wipe). Returns 204 on success; 500 if any sub-delete fails.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AccountApi.new
account_wipe_request = SmplkitGeneratedClient::App::AccountWipeRequest.new({confirm: false}) # AccountWipeRequest | 

begin
  # Wipe Account Data
  api_instance.wipe_account_data(account_wipe_request)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->wipe_account_data: #{e}"
end
```

#### Using the wipe_account_data_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> wipe_account_data_with_http_info(account_wipe_request)

```ruby
begin
  # Wipe Account Data
  data, status_code, headers = api_instance.wipe_account_data_with_http_info(account_wipe_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AccountApi->wipe_account_data_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **account_wipe_request** | [**AccountWipeRequest**](AccountWipeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

