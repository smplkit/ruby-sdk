# SmplkitGeneratedClient::App::InvitationsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**accept_invitation**](InvitationsApi.md#accept_invitation) | **POST** /api/v1/invitations/accept | Accept Invitation |
| [**create_invitations**](InvitationsApi.md#create_invitations) | **POST** /api/v1/invitations | Bulk Create Invitations |
| [**list_invitations**](InvitationsApi.md#list_invitations) | **GET** /api/v1/invitations | List Invitations |
| [**resend_invitation**](InvitationsApi.md#resend_invitation) | **POST** /api/v1/invitations/{id}/actions/resend | Resend Invitation |
| [**revoke_invitation**](InvitationsApi.md#revoke_invitation) | **POST** /api/v1/invitations/{id}/actions/revoke | Revoke Invitation |


## accept_invitation

> <InvitationResponse> accept_invitation(invitation_accept_request)

Accept Invitation

Accept an invitation using a token from the invitation email.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::InvitationsApi.new
invitation_accept_request = SmplkitGeneratedClient::App::InvitationAcceptRequest.new({token: 'token_example'}) # InvitationAcceptRequest | 

begin
  # Accept Invitation
  result = api_instance.accept_invitation(invitation_accept_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->accept_invitation: #{e}"
end
```

#### Using the accept_invitation_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvitationResponse>, Integer, Hash)> accept_invitation_with_http_info(invitation_accept_request)

```ruby
begin
  # Accept Invitation
  data, status_code, headers = api_instance.accept_invitation_with_http_info(invitation_accept_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvitationResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->accept_invitation_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **invitation_accept_request** | [**InvitationAcceptRequest**](InvitationAcceptRequest.md) |  |  |

### Return type

[**InvitationResponse**](InvitationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## create_invitations

> <InvitationListResponse> create_invitations(invitation_bulk_create_request)

Bulk Create Invitations

Send one or more invitations to join the account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::InvitationsApi.new
invitation_bulk_create_request = SmplkitGeneratedClient::App::InvitationBulkCreateRequest.new({invitations: [SmplkitGeneratedClient::App::InvitationCreateItem.new({email: 'email_example'})]}) # InvitationBulkCreateRequest | 

begin
  # Bulk Create Invitations
  result = api_instance.create_invitations(invitation_bulk_create_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->create_invitations: #{e}"
end
```

#### Using the create_invitations_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvitationListResponse>, Integer, Hash)> create_invitations_with_http_info(invitation_bulk_create_request)

```ruby
begin
  # Bulk Create Invitations
  data, status_code, headers = api_instance.create_invitations_with_http_info(invitation_bulk_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvitationListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->create_invitations_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **invitation_bulk_create_request** | [**InvitationBulkCreateRequest**](InvitationBulkCreateRequest.md) |  |  |

### Return type

[**InvitationListResponse**](InvitationListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## list_invitations

> <InvitationListResponse> list_invitations(opts)

List Invitations

List invitations. Authenticated admins list invitations for their own account and may narrow by status. Unauthenticated callers must pass ``filter[token]`` to look up a specific invitation by its token — used to render the invitation preview before sign-in. The token-filter path always returns an array of 0 or 1 elements.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::InvitationsApi.new
opts = {
  filter_status: 'filter_status_example', # String | 
  filter_token: 'filter_token_example' # String | 
}

begin
  # List Invitations
  result = api_instance.list_invitations(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->list_invitations: #{e}"
end
```

#### Using the list_invitations_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvitationListResponse>, Integer, Hash)> list_invitations_with_http_info(opts)

```ruby
begin
  # List Invitations
  data, status_code, headers = api_instance.list_invitations_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvitationListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->list_invitations_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_status** | **String** |  | [optional] |
| **filter_token** | **String** |  | [optional] |

### Return type

[**InvitationListResponse**](InvitationListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## resend_invitation

> <InvitationResponse> resend_invitation(id)

Resend Invitation

Resend a pending invitation email by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::InvitationsApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Resend Invitation
  result = api_instance.resend_invitation(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->resend_invitation: #{e}"
end
```

#### Using the resend_invitation_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvitationResponse>, Integer, Hash)> resend_invitation_with_http_info(id)

```ruby
begin
  # Resend Invitation
  data, status_code, headers = api_instance.resend_invitation_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvitationResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->resend_invitation_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**InvitationResponse**](InvitationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## revoke_invitation

> <InvitationResponse> revoke_invitation(id)

Revoke Invitation

Revoke a pending invitation by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::InvitationsApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Revoke Invitation
  result = api_instance.revoke_invitation(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->revoke_invitation: #{e}"
end
```

#### Using the revoke_invitation_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvitationResponse>, Integer, Hash)> revoke_invitation_with_http_info(id)

```ruby
begin
  # Revoke Invitation
  data, status_code, headers = api_instance.revoke_invitation_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvitationResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling InvitationsApi->revoke_invitation_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**InvitationResponse**](InvitationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

