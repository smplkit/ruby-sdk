# SmplkitGeneratedClient::App::ProductsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_products**](ProductsApi.md#list_products) | **GET** /api/v1/products | List Products |


## list_products

> <ProductListResponse> list_products(opts)

List Products

Return all flag-enabled products with their plans, limits, and marketing content.  Default sort is `display_name` ascending.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::ProductsApi.new
opts = {
  sort: 'display_name' # String | Field to sort by. Prefix with `-` for descending order. Default: `display_name`. Allowed values: `display_name`, `-display_name`, `id`, `-id`.
}

begin
  # List Products
  result = api_instance.list_products(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ProductsApi->list_products: #{e}"
end
```

#### Using the list_products_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ProductListResponse>, Integer, Hash)> list_products_with_http_info(opts)

```ruby
begin
  # List Products
  data, status_code, headers = api_instance.list_products_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ProductListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ProductsApi->list_products_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;display_name&#x60;. Allowed values: &#x60;display_name&#x60;, &#x60;-display_name&#x60;, &#x60;id&#x60;, &#x60;-id&#x60;. | [optional][default to &#39;display_name&#39;] |

### Return type

[**ProductListResponse**](ProductListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

