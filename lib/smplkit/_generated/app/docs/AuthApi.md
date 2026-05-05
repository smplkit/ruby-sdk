# SmplkitGeneratedClient::App::AuthApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**begin_oidc_login**](AuthApi.md#begin_oidc_login) | **GET** /api/v1/auth/oidc/{provider} | Begin OIDC Login |
| [**handle_oidc_callback**](AuthApi.md#handle_oidc_callback) | **GET** /api/v1/auth/callback/{provider} | Handle OIDC Callback |
| [**login**](AuthApi.md#login) | **POST** /api/v1/auth/login | Login |
| [**register**](AuthApi.md#register) | **POST** /api/v1/auth/register | Register |
| [**resend_verification**](AuthApi.md#resend_verification) | **POST** /api/v1/auth/resend-verification | Resend Verification Email |
| [**verify_email**](AuthApi.md#verify_email) | **POST** /api/v1/auth/verify-email | Verify Email |


## begin_oidc_login

> begin_oidc_login(provider, opts)

Begin OIDC Login

Initiates the OIDC authorization flow by redirecting the user to the provider's login page.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::AuthApi.new
provider = SmplkitGeneratedClient::App::OidcProvider::GOOGLE # OidcProvider | 
opts = {
  mode: 'mode_example', # String | 
  source: 'source_example', # String | 
  entry_point: 'entry_point_example' # String | 
}

begin
  # Begin OIDC Login
  api_instance.begin_oidc_login(provider, opts)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->begin_oidc_login: #{e}"
end
```

#### Using the begin_oidc_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> begin_oidc_login_with_http_info(provider, opts)

```ruby
begin
  # Begin OIDC Login
  data, status_code, headers = api_instance.begin_oidc_login_with_http_info(provider, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->begin_oidc_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **provider** | [**OidcProvider**](.md) |  |  |
| **mode** | **String** |  | [optional][default to &#39;signin&#39;] |
| **source** | **String** |  | [optional] |
| **entry_point** | **String** |  | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## handle_oidc_callback

> handle_oidc_callback(provider, opts)

Handle OIDC Callback

Handles the callback from the OIDC provider, exchanges the authorization code for tokens, and redirects to the frontend.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::AuthApi.new
provider = SmplkitGeneratedClient::App::OidcProvider::GOOGLE # OidcProvider | 
opts = {
  code: 'code_example', # String | 
  state: 'state_example', # String | 
  error: 'error_example', # String | 
  error_description: 'error_description_example' # String | 
}

begin
  # Handle OIDC Callback
  api_instance.handle_oidc_callback(provider, opts)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->handle_oidc_callback: #{e}"
end
```

#### Using the handle_oidc_callback_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> handle_oidc_callback_with_http_info(provider, opts)

```ruby
begin
  # Handle OIDC Callback
  data, status_code, headers = api_instance.handle_oidc_callback_with_http_info(provider, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->handle_oidc_callback_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **provider** | [**OidcProvider**](.md) |  |  |
| **code** | **String** |  | [optional] |
| **state** | **String** |  | [optional] |
| **error** | **String** |  | [optional] |
| **error_description** | **String** |  | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## login

> <AuthTokenResponse> login(login_request)

Login

Authenticates with email and password and returns an authentication token.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::AuthApi.new
login_request = SmplkitGeneratedClient::App::LoginRequest.new({email: 'email_example', password: 'password_example'}) # LoginRequest | 

begin
  # Login
  result = api_instance.login(login_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->login: #{e}"
end
```

#### Using the login_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuthTokenResponse>, Integer, Hash)> login_with_http_info(login_request)

```ruby
begin
  # Login
  data, status_code, headers = api_instance.login_with_http_info(login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuthTokenResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **login_request** | [**LoginRequest**](LoginRequest.md) |  |  |

### Return type

[**AuthTokenResponse**](AuthTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## register

> <AuthTokenResponse> register(register_request)

Register

Creates a new account with email and password and returns an authentication token.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::AuthApi.new
register_request = SmplkitGeneratedClient::App::RegisterRequest.new({email: 'email_example', password: 'password_example'}) # RegisterRequest | 

begin
  # Register
  result = api_instance.register(register_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->register: #{e}"
end
```

#### Using the register_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuthTokenResponse>, Integer, Hash)> register_with_http_info(register_request)

```ruby
begin
  # Register
  data, status_code, headers = api_instance.register_with_http_info(register_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuthTokenResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->register_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **register_request** | [**RegisterRequest**](RegisterRequest.md) |  |  |

### Return type

[**AuthTokenResponse**](AuthTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## resend_verification

> resend_verification

Resend Verification Email

Resends the email verification link to the authenticated user.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::AuthApi.new

begin
  # Resend Verification Email
  api_instance.resend_verification
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->resend_verification: #{e}"
end
```

#### Using the resend_verification_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> resend_verification_with_http_info

```ruby
begin
  # Resend Verification Email
  data, status_code, headers = api_instance.resend_verification_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->resend_verification_with_http_info: #{e}"
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
- **Accept**: application/json


## verify_email

> <AuthTokenResponse> verify_email(verify_email_request)

Verify Email

Verifies a user's email address using the token from the verification email.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::AuthApi.new
verify_email_request = SmplkitGeneratedClient::App::VerifyEmailRequest.new({token: 'token_example'}) # VerifyEmailRequest | 

begin
  # Verify Email
  result = api_instance.verify_email(verify_email_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->verify_email: #{e}"
end
```

#### Using the verify_email_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuthTokenResponse>, Integer, Hash)> verify_email_with_http_info(verify_email_request)

```ruby
begin
  # Verify Email
  data, status_code, headers = api_instance.verify_email_with_http_info(verify_email_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuthTokenResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling AuthApi->verify_email_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **verify_email_request** | [**VerifyEmailRequest**](VerifyEmailRequest.md) |  |  |

### Return type

[**AuthTokenResponse**](AuthTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json

