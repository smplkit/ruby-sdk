# SmplkitGeneratedClient::App::ProductsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_products**](ProductsApi.md#list_products) | **GET** /api/v1/products | List Products |


## list_products

> <ProductListResponse> list_products

List Products

Return all flag-enabled products with their plans and limits.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::ProductsApi.new

begin
  # List Products
  result = api_instance.list_products
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ProductsApi->list_products: #{e}"
end
```

#### Using the list_products_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ProductListResponse>, Integer, Hash)> list_products_with_http_info

```ruby
begin
  # List Products
  data, status_code, headers = api_instance.list_products_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ProductListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ProductsApi->list_products_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ProductListResponse**](ProductListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

