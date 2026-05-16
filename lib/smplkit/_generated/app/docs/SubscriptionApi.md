# SmplkitGeneratedClient::App::SubscriptionApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**admin_put_account_subscription**](SubscriptionApi.md#admin_put_account_subscription) | **PUT** /api/v1/accounts/{account_id}/subscription | Replace Account Subscription (admin) |
| [**get_current_subscription**](SubscriptionApi.md#get_current_subscription) | **GET** /api/v1/accounts/current/subscription | Get Current Subscription |
| [**preview_current_subscription**](SubscriptionApi.md#preview_current_subscription) | **POST** /api/v1/accounts/current/subscription/actions/preview | Preview Subscription Change |
| [**put_current_subscription**](SubscriptionApi.md#put_current_subscription) | **PUT** /api/v1/accounts/current/subscription | Replace Current Subscription |


## admin_put_account_subscription

> <SubscriptionResponse> admin_put_account_subscription(account_id, admin_subscription_request)

Replace Account Subscription (admin)

Admin replacement of a specific account's subscription.  Accepts the same body shape as the customer endpoint plus ``discount_override_pct``. Setting the override to 100 skips the billing provider entirely; lowering it below 100 requires a payment method on file for the target account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SubscriptionApi.new
account_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
admin_subscription_request = SmplkitGeneratedClient::App::AdminSubscriptionRequest.new({data: SmplkitGeneratedClient::App::AdminSubscriptionRequestResource.new({type: 'subscription', attributes: SmplkitGeneratedClient::App::AdminSubscriptionRequestAttributes.new({items: [SmplkitGeneratedClient::App::SubscriptionItemRequest.new({product: 'product_example', plan: 'plan_example'})]})})}) # AdminSubscriptionRequest | 

begin
  # Replace Account Subscription (admin)
  result = api_instance.admin_put_account_subscription(account_id, admin_subscription_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->admin_put_account_subscription: #{e}"
end
```

#### Using the admin_put_account_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> admin_put_account_subscription_with_http_info(account_id, admin_subscription_request)

```ruby
begin
  # Replace Account Subscription (admin)
  data, status_code, headers = api_instance.admin_put_account_subscription_with_http_info(account_id, admin_subscription_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->admin_put_account_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **account_id** | **String** |  |  |
| **admin_subscription_request** | [**AdminSubscriptionRequest**](AdminSubscriptionRequest.md) |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## get_current_subscription

> <SubscriptionResponse> get_current_subscription

Get Current Subscription

Return the authenticated account's subscription, or 404 if none exists.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SubscriptionApi.new

begin
  # Get Current Subscription
  result = api_instance.get_current_subscription
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->get_current_subscription: #{e}"
end
```

#### Using the get_current_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> get_current_subscription_with_http_info

```ruby
begin
  # Get Current Subscription
  data, status_code, headers = api_instance.get_current_subscription_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->get_current_subscription_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## preview_current_subscription

> <SubscriptionPreviewResponse> preview_current_subscription(subscription_request)

Preview Subscription Change

Project the result of replacing the subscription with the desired state.  No database or billing-provider changes are made; safe to call as the customer iterates on a plan picker.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SubscriptionApi.new
subscription_request = SmplkitGeneratedClient::App::SubscriptionRequest.new({data: SmplkitGeneratedClient::App::SubscriptionRequestResource.new({type: 'subscription', attributes: SmplkitGeneratedClient::App::SubscriptionRequestAttributes.new({items: [SmplkitGeneratedClient::App::SubscriptionItemRequest.new({product: 'product_example', plan: 'plan_example'})]})})}) # SubscriptionRequest | 

begin
  # Preview Subscription Change
  result = api_instance.preview_current_subscription(subscription_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->preview_current_subscription: #{e}"
end
```

#### Using the preview_current_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionPreviewResponse>, Integer, Hash)> preview_current_subscription_with_http_info(subscription_request)

```ruby
begin
  # Preview Subscription Change
  data, status_code, headers = api_instance.preview_current_subscription_with_http_info(subscription_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionPreviewResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->preview_current_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **subscription_request** | [**SubscriptionRequest**](SubscriptionRequest.md) |  |  |

### Return type

[**SubscriptionPreviewResponse**](SubscriptionPreviewResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## put_current_subscription

> <SubscriptionResponse> put_current_subscription(subscription_request)

Replace Current Subscription

Replace the authenticated account's subscription with the desired state.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::SubscriptionApi.new
subscription_request = SmplkitGeneratedClient::App::SubscriptionRequest.new({data: SmplkitGeneratedClient::App::SubscriptionRequestResource.new({type: 'subscription', attributes: SmplkitGeneratedClient::App::SubscriptionRequestAttributes.new({items: [SmplkitGeneratedClient::App::SubscriptionItemRequest.new({product: 'product_example', plan: 'plan_example'})]})})}) # SubscriptionRequest | 

begin
  # Replace Current Subscription
  result = api_instance.put_current_subscription(subscription_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->put_current_subscription: #{e}"
end
```

#### Using the put_current_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> put_current_subscription_with_http_info(subscription_request)

```ruby
begin
  # Replace Current Subscription
  data, status_code, headers = api_instance.put_current_subscription_with_http_info(subscription_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling SubscriptionApi->put_current_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **subscription_request** | [**SubscriptionRequest**](SubscriptionRequest.md) |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

