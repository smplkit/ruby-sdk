# SmplkitGeneratedClient::App::BillingApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**cancel_subscription**](BillingApi.md#cancel_subscription) | **POST** /api/v1/subscriptions/{id}/actions/cancel | Cancel Subscription |
| [**create_bundle**](BillingApi.md#create_bundle) | **POST** /api/v1/bundles | Create Bundle Subscription |
| [**create_payment_method**](BillingApi.md#create_payment_method) | **POST** /api/v1/payment_methods | Add Payment Method |
| [**create_subscription**](BillingApi.md#create_subscription) | **POST** /api/v1/subscriptions | Create Subscription |
| [**delete_payment_method**](BillingApi.md#delete_payment_method) | **DELETE** /api/v1/payment_methods/{id} | Delete Payment Method |
| [**downgrade_subscription**](BillingApi.md#downgrade_subscription) | **POST** /api/v1/subscriptions/{id}/actions/downgrade | Downgrade Subscription |
| [**execute_setup_intent**](BillingApi.md#execute_setup_intent) | **POST** /api/v1/functions/setup_intent/actions/execute | Execute Setup Intent |
| [**get_invoice**](BillingApi.md#get_invoice) | **GET** /api/v1/invoices/{invoice_id} | Get Invoice |
| [**get_payment_method**](BillingApi.md#get_payment_method) | **GET** /api/v1/payment_methods/{id} | Get Payment Method |
| [**list_bundles**](BillingApi.md#list_bundles) | **GET** /api/v1/bundles | List Bundles |
| [**list_invoices**](BillingApi.md#list_invoices) | **GET** /api/v1/invoices | List Invoices |
| [**list_payment_methods**](BillingApi.md#list_payment_methods) | **GET** /api/v1/payment_methods | List Payment Methods |
| [**list_subscriptions**](BillingApi.md#list_subscriptions) | **GET** /api/v1/subscriptions | List Subscriptions |
| [**set_default_payment_method**](BillingApi.md#set_default_payment_method) | **POST** /api/v1/payment_methods/{id}/actions/set_default | Set Default Payment Method |
| [**uncancel_subscription**](BillingApi.md#uncancel_subscription) | **POST** /api/v1/subscriptions/{id}/actions/uncancel | Undo Cancellation |
| [**undowngrade_subscription**](BillingApi.md#undowngrade_subscription) | **POST** /api/v1/subscriptions/{id}/actions/undowngrade | Undo Pending Downgrade |
| [**update_payment_method**](BillingApi.md#update_payment_method) | **PUT** /api/v1/payment_methods/{id} | Update Payment Method |
| [**upgrade_subscription**](BillingApi.md#upgrade_subscription) | **POST** /api/v1/subscriptions/{id}/actions/upgrade | Upgrade Subscription |


## cancel_subscription

> <SubscriptionResponse> cancel_subscription(id)

Cancel Subscription

Cancel a subscription at end of the current billing period.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Cancel Subscription
  result = api_instance.cancel_subscription(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->cancel_subscription: #{e}"
end
```

#### Using the cancel_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> cancel_subscription_with_http_info(id)

```ruby
begin
  # Cancel Subscription
  data, status_code, headers = api_instance.cancel_subscription_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->cancel_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## create_bundle

> <BundleResponse> create_bundle(create_bundle_body)

Create Bundle Subscription

Create a bundle subscription covering all three products at a shared plan tier.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
create_bundle_body = SmplkitGeneratedClient::App::CreateBundleBody.new({data: SmplkitGeneratedClient::App::CreateBundleData.new({type: 'bundle', attributes: SmplkitGeneratedClient::App::CreateBundleAttributes.new({bundle: 'bundle_example'})})}) # CreateBundleBody | 

begin
  # Create Bundle Subscription
  result = api_instance.create_bundle(create_bundle_body)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_bundle: #{e}"
end
```

#### Using the create_bundle_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<BundleResponse>, Integer, Hash)> create_bundle_with_http_info(create_bundle_body)

```ruby
begin
  # Create Bundle Subscription
  data, status_code, headers = api_instance.create_bundle_with_http_info(create_bundle_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <BundleResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_bundle_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **create_bundle_body** | [**CreateBundleBody**](CreateBundleBody.md) |  |  |

### Return type

[**BundleResponse**](BundleResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## create_payment_method

> <PaymentMethodResponse> create_payment_method(add_payment_method_body)

Add Payment Method

Register a Stripe payment method (``pm_...``) as a persistent resource. The frontend obtains the Stripe ID via SetupIntent + Stripe Elements, then POSTs it here. Body shape and server behavior per ADR-044 §5.1.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
add_payment_method_body = SmplkitGeneratedClient::App::AddPaymentMethodBody.new({data: SmplkitGeneratedClient::App::AddPaymentMethodData.new({type: 'payment_method', attributes: SmplkitGeneratedClient::App::AddPaymentMethodAttributes.new({stripe_payment_method_id: 'stripe_payment_method_id_example'})})}) # AddPaymentMethodBody | 

begin
  # Add Payment Method
  result = api_instance.create_payment_method(add_payment_method_body)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_payment_method: #{e}"
end
```

#### Using the create_payment_method_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PaymentMethodResponse>, Integer, Hash)> create_payment_method_with_http_info(add_payment_method_body)

```ruby
begin
  # Add Payment Method
  data, status_code, headers = api_instance.create_payment_method_with_http_info(add_payment_method_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PaymentMethodResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_payment_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **add_payment_method_body** | [**AddPaymentMethodBody**](AddPaymentMethodBody.md) |  |  |

### Return type

[**PaymentMethodResponse**](PaymentMethodResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## create_subscription

> <SubscriptionResponse> create_subscription(create_subscription_body)

Create Subscription

Create a new paid subscription for a product.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
create_subscription_body = SmplkitGeneratedClient::App::CreateSubscriptionBody.new({data: SmplkitGeneratedClient::App::CreateSubscriptionData.new({type: 'type_example', attributes: SmplkitGeneratedClient::App::CreateSubscriptionAttributes.new({product: 'product_example', plan: 'plan_example'})})}) # CreateSubscriptionBody | 

begin
  # Create Subscription
  result = api_instance.create_subscription(create_subscription_body)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_subscription: #{e}"
end
```

#### Using the create_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> create_subscription_with_http_info(create_subscription_body)

```ruby
begin
  # Create Subscription
  data, status_code, headers = api_instance.create_subscription_with_http_info(create_subscription_body)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->create_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **create_subscription_body** | [**CreateSubscriptionBody**](CreateSubscriptionBody.md) |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_payment_method

> delete_payment_method(id)

Delete Payment Method

Detach the payment method from Stripe and soft-delete the local row. Returns 409 if this is the only PM and the account has an active paid subscription. If the deleted row was default, the oldest remaining row is promoted.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Delete Payment Method
  api_instance.delete_payment_method(id)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->delete_payment_method: #{e}"
end
```

#### Using the delete_payment_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_payment_method_with_http_info(id)

```ruby
begin
  # Delete Payment Method
  data, status_code, headers = api_instance.delete_payment_method_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->delete_payment_method_with_http_info: #{e}"
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


## downgrade_subscription

> <SubscriptionResponse> downgrade_subscription(id, plan_change_request)

Downgrade Subscription

Downgrade an existing paid subscription to a lower plan.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
plan_change_request = SmplkitGeneratedClient::App::PlanChangeRequest.new({plan: 'plan_example'}) # PlanChangeRequest | 

begin
  # Downgrade Subscription
  result = api_instance.downgrade_subscription(id, plan_change_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->downgrade_subscription: #{e}"
end
```

#### Using the downgrade_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> downgrade_subscription_with_http_info(id, plan_change_request)

```ruby
begin
  # Downgrade Subscription
  data, status_code, headers = api_instance.downgrade_subscription_with_http_info(id, plan_change_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->downgrade_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **plan_change_request** | [**PlanChangeRequest**](PlanChangeRequest.md) |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## execute_setup_intent

> <SetupIntentResponse> execute_setup_intent

Execute Setup Intent

Create a Stripe SetupIntent for saving a payment method.  Returns a ``client_secret`` that the frontend passes to Stripe's Payment Element so the customer can securely enter card details without an immediate charge.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new

begin
  # Execute Setup Intent
  result = api_instance.execute_setup_intent
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->execute_setup_intent: #{e}"
end
```

#### Using the execute_setup_intent_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SetupIntentResponse>, Integer, Hash)> execute_setup_intent_with_http_info

```ruby
begin
  # Execute Setup Intent
  data, status_code, headers = api_instance.execute_setup_intent_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SetupIntentResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->execute_setup_intent_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SetupIntentResponse**](SetupIntentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_invoice

> <InvoiceSingleResponse> get_invoice(invoice_id)

Get Invoice

Return a single invoice by ID. Supports content negotiation via Accept header:  - ``application/pdf`` — PDF bytes proxy-streamed from Stripe - ``application/vnd.api+json`` / ``application/json`` / absent — JSON:API resource - Any other value — 406 Not Acceptable

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
invoice_id = 'invoice_id_example' # String | 

begin
  # Get Invoice
  result = api_instance.get_invoice(invoice_id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->get_invoice: #{e}"
end
```

#### Using the get_invoice_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvoiceSingleResponse>, Integer, Hash)> get_invoice_with_http_info(invoice_id)

```ruby
begin
  # Get Invoice
  data, status_code, headers = api_instance.get_invoice_with_http_info(invoice_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvoiceSingleResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->get_invoice_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **invoice_id** | **String** |  |  |

### Return type

[**InvoiceSingleResponse**](InvoiceSingleResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_payment_method

> <PaymentMethodResponse> get_payment_method(id)

Get Payment Method

Return a payment method by id.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get Payment Method
  result = api_instance.get_payment_method(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->get_payment_method: #{e}"
end
```

#### Using the get_payment_method_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PaymentMethodResponse>, Integer, Hash)> get_payment_method_with_http_info(id)

```ruby
begin
  # Get Payment Method
  data, status_code, headers = api_instance.get_payment_method_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PaymentMethodResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->get_payment_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**PaymentMethodResponse**](PaymentMethodResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_bundles

> <BundleListResponse> list_bundles

List Bundles

Return all bundle definitions as JSON:API resources. Public, unauthenticated.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::BillingApi.new

begin
  # List Bundles
  result = api_instance.list_bundles
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_bundles: #{e}"
end
```

#### Using the list_bundles_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<BundleListResponse>, Integer, Hash)> list_bundles_with_http_info

```ruby
begin
  # List Bundles
  data, status_code, headers = api_instance.list_bundles_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <BundleListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_bundles_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**BundleListResponse**](BundleListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_invoices

> <InvoiceListResponse> list_invoices

List Invoices

Return invoice history for the account from Stripe.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new

begin
  # List Invoices
  result = api_instance.list_invoices
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_invoices: #{e}"
end
```

#### Using the list_invoices_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InvoiceListResponse>, Integer, Hash)> list_invoices_with_http_info

```ruby
begin
  # List Invoices
  data, status_code, headers = api_instance.list_invoices_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InvoiceListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_invoices_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InvoiceListResponse**](InvoiceListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_payment_methods

> <PaymentMethodListResponse> list_payment_methods

List Payment Methods

List all payment methods for the account. Default is returned first, then newest first.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new

begin
  # List Payment Methods
  result = api_instance.list_payment_methods
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_payment_methods: #{e}"
end
```

#### Using the list_payment_methods_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PaymentMethodListResponse>, Integer, Hash)> list_payment_methods_with_http_info

```ruby
begin
  # List Payment Methods
  data, status_code, headers = api_instance.list_payment_methods_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PaymentMethodListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_payment_methods_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**PaymentMethodListResponse**](PaymentMethodListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_subscriptions

> <SubscriptionListResponse> list_subscriptions

List Subscriptions

Return subscription rows for the authenticated account.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new

begin
  # List Subscriptions
  result = api_instance.list_subscriptions
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_subscriptions: #{e}"
end
```

#### Using the list_subscriptions_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionListResponse>, Integer, Hash)> list_subscriptions_with_http_info

```ruby
begin
  # List Subscriptions
  data, status_code, headers = api_instance.list_subscriptions_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->list_subscriptions_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SubscriptionListResponse**](SubscriptionListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## set_default_payment_method

> <PaymentMethodResponse> set_default_payment_method(id)

Set Default Payment Method

Mark this payment method as the account's default. Idempotent — a no-op 200 if already default.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Set Default Payment Method
  result = api_instance.set_default_payment_method(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->set_default_payment_method: #{e}"
end
```

#### Using the set_default_payment_method_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PaymentMethodResponse>, Integer, Hash)> set_default_payment_method_with_http_info(id)

```ruby
begin
  # Set Default Payment Method
  data, status_code, headers = api_instance.set_default_payment_method_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PaymentMethodResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->set_default_payment_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**PaymentMethodResponse**](PaymentMethodResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## uncancel_subscription

> <SubscriptionResponse> uncancel_subscription(id)

Undo Cancellation

Reverse a pending cancellation; subscription will renew as normal.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Undo Cancellation
  result = api_instance.uncancel_subscription(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->uncancel_subscription: #{e}"
end
```

#### Using the uncancel_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> uncancel_subscription_with_http_info(id)

```ruby
begin
  # Undo Cancellation
  data, status_code, headers = api_instance.uncancel_subscription_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->uncancel_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## undowngrade_subscription

> <SubscriptionResponse> undowngrade_subscription(id)

Undo Pending Downgrade

Reverse a pending downgrade scheduled for end of the current billing period.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Undo Pending Downgrade
  result = api_instance.undowngrade_subscription(id)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->undowngrade_subscription: #{e}"
end
```

#### Using the undowngrade_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> undowngrade_subscription_with_http_info(id)

```ruby
begin
  # Undo Pending Downgrade
  data, status_code, headers = api_instance.undowngrade_subscription_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->undowngrade_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_payment_method

> <PaymentMethodResponse> update_payment_method(id, payment_method_response)

Update Payment Method

Update the mutable fields (``billing_details``, ``exp_month``, ``exp_year``). The ``default`` field is not mutable via PUT — see ADR-044 §5.2; use the ``set_default`` action instead.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
payment_method_response = SmplkitGeneratedClient::App::PaymentMethodResponse.new({data: SmplkitGeneratedClient::App::PaymentMethodResource.new({type: 'payment_method', attributes: SmplkitGeneratedClient::App::PaymentMethod.new})}) # PaymentMethodResponse | 

begin
  # Update Payment Method
  result = api_instance.update_payment_method(id, payment_method_response)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->update_payment_method: #{e}"
end
```

#### Using the update_payment_method_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PaymentMethodResponse>, Integer, Hash)> update_payment_method_with_http_info(id, payment_method_response)

```ruby
begin
  # Update Payment Method
  data, status_code, headers = api_instance.update_payment_method_with_http_info(id, payment_method_response)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PaymentMethodResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->update_payment_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **payment_method_response** | [**PaymentMethodResponse**](PaymentMethodResponse.md) |  |  |

### Return type

[**PaymentMethodResponse**](PaymentMethodResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## upgrade_subscription

> <SubscriptionResponse> upgrade_subscription(id, plan_change_request)

Upgrade Subscription

Upgrade an existing paid subscription to a higher plan.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::BillingApi.new
id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 
plan_change_request = SmplkitGeneratedClient::App::PlanChangeRequest.new({plan: 'plan_example'}) # PlanChangeRequest | 

begin
  # Upgrade Subscription
  result = api_instance.upgrade_subscription(id, plan_change_request)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->upgrade_subscription: #{e}"
end
```

#### Using the upgrade_subscription_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SubscriptionResponse>, Integer, Hash)> upgrade_subscription_with_http_info(id, plan_change_request)

```ruby
begin
  # Upgrade Subscription
  data, status_code, headers = api_instance.upgrade_subscription_with_http_info(id, plan_change_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SubscriptionResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling BillingApi->upgrade_subscription_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** |  |  |
| **plan_change_request** | [**PlanChangeRequest**](PlanChangeRequest.md) |  |  |

### Return type

[**SubscriptionResponse**](SubscriptionResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

