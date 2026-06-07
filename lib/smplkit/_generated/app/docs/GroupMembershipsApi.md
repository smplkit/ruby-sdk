# SmplkitGeneratedClient::App::GroupMembershipsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_group_membership**](GroupMembershipsApi.md#create_group_membership) | **POST** /api/v1/group_memberships | Create Group Membership |
| [**delete_group_membership**](GroupMembershipsApi.md#delete_group_membership) | **DELETE** /api/v1/group_memberships/{id} | Delete Group Membership |
| [**get_group_membership**](GroupMembershipsApi.md#get_group_membership) | **GET** /api/v1/group_memberships/{id} | Get Group Membership |
| [**list_group_memberships**](GroupMembershipsApi.md#list_group_memberships) | **GET** /api/v1/group_memberships | List Group Memberships |


## create_group_membership

> <GroupMembershipResponse> create_group_membership(group_membership_request)

Create Group Membership

Add a user to a group. The body references the user (UUID) and the group (key) in the resource attributes. Returns `409` if this user is already a member of this group, or `422` if either the user is not a member of the account or the group does not exist.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupMembershipsApi.new
group_membership_request = SmplkitGeneratedClient::App::GroupMembershipRequest.new({data: SmplkitGeneratedClient::App::GroupMembershipResource.new({type: 'group_membership', attributes: SmplkitGeneratedClient::App::GroupMembership.new({user: 'user_example', group: 'group_example'})})}) # GroupMembershipRequest | 

begin
  # Create Group Membership
  result = api_instance.create_group_membership(group_membership_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->create_group_membership: #{e}"
end
```

#### Using the create_group_membership_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupMembershipResponse>, Integer, Hash)> create_group_membership_with_http_info(group_membership_request)

```ruby
begin
  # Create Group Membership
  data, status_code, headers = api_instance.create_group_membership_with_http_info(group_membership_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupMembershipResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->create_group_membership_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_membership_request** | [**GroupMembershipRequest**](GroupMembershipRequest.md) |  |  |

### Return type

[**GroupMembershipResponse**](GroupMembershipResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_group_membership

> delete_group_membership(id)

Delete Group Membership

Remove a user from a group. Returns `409` when removing the membership would leave the user with no group memberships in this account — every user must belong to at least one group.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupMembershipsApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Delete Group Membership
  api_instance.delete_group_membership(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->delete_group_membership: #{e}"
end
```

#### Using the delete_group_membership_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_group_membership_with_http_info(id)

```ruby
begin
  # Delete Group Membership
  data, status_code, headers = api_instance.delete_group_membership_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->delete_group_membership_with_http_info: #{e}"
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


## get_group_membership

> <GroupMembershipResponse> get_group_membership(id)

Get Group Membership

Return a single membership by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupMembershipsApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get Group Membership
  result = api_instance.get_group_membership(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->get_group_membership: #{e}"
end
```

#### Using the get_group_membership_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupMembershipResponse>, Integer, Hash)> get_group_membership_with_http_info(id)

```ruby
begin
  # Get Group Membership
  data, status_code, headers = api_instance.get_group_membership_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupMembershipResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->get_group_membership_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**GroupMembershipResponse**](GroupMembershipResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_group_memberships

> <GroupMembershipListResponse> list_group_memberships(opts)

List Group Memberships

List group memberships in the authenticated account. Pass `filter[group]` (a group key) to list members of a single group, or `filter[user]` (a UUID) to list a single user's memberships. The two filters may be combined to look up a specific (user, group) pair.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::GroupMembershipsApi.new
opts = {
  filter_group: 'filter_group_example', # String | Group key to narrow the result to memberships in that group.
  filter_user: 'filter_user_example', # String | User UUID to narrow the result to memberships for that user.
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `created_at`. Allowed values: `created_at`, `-created_at`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Group Memberships
  result = api_instance.list_group_memberships(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->list_group_memberships: #{e}"
end
```

#### Using the list_group_memberships_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GroupMembershipListResponse>, Integer, Hash)> list_group_memberships_with_http_info(opts)

```ruby
begin
  # List Group Memberships
  data, status_code, headers = api_instance.list_group_memberships_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GroupMembershipListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling GroupMembershipsApi->list_group_memberships_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_group** | **String** | Group key to narrow the result to memberships in that group. | [optional] |
| **filter_user** | **String** | User UUID to narrow the result to memberships for that user. | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;created_at&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;created_at&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**GroupMembershipListResponse**](GroupMembershipListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

