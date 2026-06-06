# SmplkitGeneratedClient::Audit::CategoriesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_categories**](CategoriesApi.md#list_categories) | **GET** /api/v1/categories | List Categories |


## list_categories

> <CategoryListResponse> list_categories(opts)

List Categories

List the distinct `category` values recorded for this account.  The resource `id` is the category value itself. Default sort is `key` ascending; pass `sort=-key` for descending. Scoped to the resolved environment. Useful for populating filter dropdowns in a UI.

### Examples

```ruby
require 'time'
require 'smplkit_audit_client'
# setup authorization
SmplkitGeneratedClient::Audit.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Audit::CategoriesApi.new
opts = {
  sort: 'key', # String | Field to sort by. Prefix with `-` for descending order. Default: `key`. Allowed values: `key`, `-key`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Categories
  result = api_instance.list_categories(opts)
  p result
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling CategoriesApi->list_categories: #{e}"
end
```

#### Using the list_categories_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CategoryListResponse>, Integer, Hash)> list_categories_with_http_info(opts)

```ruby
begin
  # List Categories
  data, status_code, headers = api_instance.list_categories_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CategoryListResponse>
rescue SmplkitGeneratedClient::Audit::ApiError => e
  puts "Error when calling CategoriesApi->list_categories_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;key&#x60;. Allowed values: &#x60;key&#x60;, &#x60;-key&#x60;. | [optional][default to &#39;key&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**CategoryListResponse**](CategoryListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

