# SmplkitGeneratedClient::App::DiscountTiersApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_discount_tiers**](DiscountTiersApi.md#list_discount_tiers) | **GET** /api/v1/discount_tiers | List Discount Tiers |


## list_discount_tiers

> <DiscountTierListResponse> list_discount_tiers(opts)

List Discount Tiers

Return the multi-product volume discount schedule.  Each tier is identified by the minimum number of paid products at which the discount applies. The first tier (1 product) carries no discount; subsequent tiers grant a progressively larger percent off every paid subscription item. Default sort is `products_count` ascending, which is the natural ladder customers traverse as they add products.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::DiscountTiersApi.new
opts = {
  sort: 'percent_off', # String | Field to sort by. Prefix with `-` for descending order. Default: `products_count`. Allowed values: `percent_off`, `-percent_off`, `products_count`, `-products_count`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Discount Tiers
  result = api_instance.list_discount_tiers(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling DiscountTiersApi->list_discount_tiers: #{e}"
end
```

#### Using the list_discount_tiers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<DiscountTierListResponse>, Integer, Hash)> list_discount_tiers_with_http_info(opts)

```ruby
begin
  # List Discount Tiers
  data, status_code, headers = api_instance.list_discount_tiers_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <DiscountTierListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling DiscountTiersApi->list_discount_tiers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;products_count&#x60;. Allowed values: &#x60;percent_off&#x60;, &#x60;-percent_off&#x60;, &#x60;products_count&#x60;, &#x60;-products_count&#x60;. | [optional][default to &#39;products_count&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**DiscountTierListResponse**](DiscountTierListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

