# SmplkitGeneratedClient::App::SSOApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**claim_sso_domain**](SSOApi.md#claim_sso_domain) | **PUT** /api/v1/accounts/current/sso_domains/{domain} | Claim SSO Domain |
| [**delete_sso_connection**](SSOApi.md#delete_sso_connection) | **DELETE** /api/v1/accounts/current/sso_connection | Delete SSO Connection |
| [**get_sso_connection**](SSOApi.md#get_sso_connection) | **GET** /api/v1/accounts/current/sso_connection | Get SSO Connection |
| [**list_sso_domains**](SSOApi.md#list_sso_domains) | **GET** /api/v1/accounts/current/sso_domains | List SSO Domains |
| [**put_sso_connection**](SSOApi.md#put_sso_connection) | **PUT** /api/v1/accounts/current/sso_connection | Create or Replace SSO Connection |
| [**release_sso_domain**](SSOApi.md#release_sso_domain) | **DELETE** /api/v1/accounts/current/sso_domains/{domain} | Release SSO Domain |
| [**verify_sso_domain**](SSOApi.md#verify_sso_domain) | **POST** /api/v1/accounts/current/sso_domains/{domain}/actions/verify | Verify SSO Domain |


## claim_sso_domain

> <SSODomainResponse> claim_sso_domain(domain, sso_domain_request)

Claim SSO Domain

Claim a domain for SSO routing. Idempotent — re-claiming a domain already held by the account is a no-op success. The response includes the DNS TXT token to publish.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new
domain = 'domain_example' # String | 
sso_domain_request = SmplkitGeneratedClient::App::SSODomainRequest.new({data: SmplkitGeneratedClient::App::SSODomainResource.new({type: 'sso_domain', attributes: SmplkitGeneratedClient::App::SSODomain.new})}) # SSODomainRequest | 

begin
  # Claim SSO Domain
  result = api_instance.claim_sso_domain(domain, sso_domain_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->claim_sso_domain: #{e}"
end
```

#### Using the claim_sso_domain_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SSODomainResponse>, Integer, Hash)> claim_sso_domain_with_http_info(domain, sso_domain_request)

```ruby
begin
  # Claim SSO Domain
  data, status_code, headers = api_instance.claim_sso_domain_with_http_info(domain, sso_domain_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SSODomainResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->claim_sso_domain_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **domain** | **String** |  |  |
| **sso_domain_request** | [**SSODomainRequest**](SSODomainRequest.md) |  |  |

### Return type

[**SSODomainResponse**](SSODomainResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_sso_connection

> delete_sso_connection

Delete SSO Connection

Soft-delete the account's SSO connection. Domains are preserved.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new

begin
  # Delete SSO Connection
  api_instance.delete_sso_connection
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->delete_sso_connection: #{e}"
end
```

#### Using the delete_sso_connection_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_sso_connection_with_http_info

```ruby
begin
  # Delete SSO Connection
  data, status_code, headers = api_instance.delete_sso_connection_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->delete_sso_connection_with_http_info: #{e}"
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


## get_sso_connection

> <SSOConnectionResponse> get_sso_connection

Get SSO Connection

Return the SSO connection for the current account, including computed Service Provider metadata. Returns `404` when no connection has been configured.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new

begin
  # Get SSO Connection
  result = api_instance.get_sso_connection
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->get_sso_connection: #{e}"
end
```

#### Using the get_sso_connection_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SSOConnectionResponse>, Integer, Hash)> get_sso_connection_with_http_info

```ruby
begin
  # Get SSO Connection
  data, status_code, headers = api_instance.get_sso_connection_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SSOConnectionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->get_sso_connection_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SSOConnectionResponse**](SSOConnectionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_sso_domains

> <SSODomainListResponse> list_sso_domains

List SSO Domains

List the domains claimed by the current account, including each row's verification status.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new

begin
  # List SSO Domains
  result = api_instance.list_sso_domains
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->list_sso_domains: #{e}"
end
```

#### Using the list_sso_domains_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SSODomainListResponse>, Integer, Hash)> list_sso_domains_with_http_info

```ruby
begin
  # List SSO Domains
  data, status_code, headers = api_instance.list_sso_domains_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SSODomainListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->list_sso_domains_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SSODomainListResponse**](SSODomainListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## put_sso_connection

> <SSOConnectionResponse> put_sso_connection(sso_connection_request)

Create or Replace SSO Connection

Create-or-replace the account's SSO connection. The OIDC `client_secret` is write-only; supply it on first creation, omit on subsequent updates to retain the stored value.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new
sso_connection_request = SmplkitGeneratedClient::App::SSOConnectionRequest.new({data: SmplkitGeneratedClient::App::SSOConnectionResource.new({type: 'sso_connection', attributes: SmplkitGeneratedClient::App::SSOConnection.new({protocol: 'saml'})})}) # SSOConnectionRequest | 

begin
  # Create or Replace SSO Connection
  result = api_instance.put_sso_connection(sso_connection_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->put_sso_connection: #{e}"
end
```

#### Using the put_sso_connection_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SSOConnectionResponse>, Integer, Hash)> put_sso_connection_with_http_info(sso_connection_request)

```ruby
begin
  # Create or Replace SSO Connection
  data, status_code, headers = api_instance.put_sso_connection_with_http_info(sso_connection_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SSOConnectionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->put_sso_connection_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sso_connection_request** | [**SSOConnectionRequest**](SSOConnectionRequest.md) |  |  |

### Return type

[**SSOConnectionResponse**](SSOConnectionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## release_sso_domain

> release_sso_domain(domain)

Release SSO Domain

Release a previously-claimed SSO domain.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new
domain = 'domain_example' # String | 

begin
  # Release SSO Domain
  api_instance.release_sso_domain(domain)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->release_sso_domain: #{e}"
end
```

#### Using the release_sso_domain_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> release_sso_domain_with_http_info(domain)

```ruby
begin
  # Release SSO Domain
  data, status_code, headers = api_instance.release_sso_domain_with_http_info(domain)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->release_sso_domain_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **domain** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## verify_sso_domain

> <SSODomainResponse> verify_sso_domain(domain)

Verify SSO Domain

Run the DNS TXT check for a claimed domain. Returns the updated resource on success. Returns `409` if a different account has already verified this domain. Returns `422` when the DNS TXT record has not yet been published or does not match the expected token.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SSOApi.new
domain = 'domain_example' # String | 

begin
  # Verify SSO Domain
  result = api_instance.verify_sso_domain(domain)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->verify_sso_domain: #{e}"
end
```

#### Using the verify_sso_domain_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SSODomainResponse>, Integer, Hash)> verify_sso_domain_with_http_info(domain)

```ruby
begin
  # Verify SSO Domain
  data, status_code, headers = api_instance.verify_sso_domain_with_http_info(domain)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SSODomainResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SSOApi->verify_sso_domain_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **domain** | **String** |  |  |

### Return type

[**SSODomainResponse**](SSODomainResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

