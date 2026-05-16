# SmplkitGeneratedClient::App::ContextValuesApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_context_values**](ContextValuesApi.md#list_context_values) | **GET** /api/v1/context_values | List Context Values |


## list_context_values

> <ContextValueListResponse> list_context_values(opts)

List Context Values

Return distinct values observed for a single attribute across context instances of one context type. The intended use case is a typeahead picker in a rule-building UI: the customer chooses a context type and an attribute name, then this endpoint streams back the distinct values matching what they've typed so far.  `filter[context_type]` and `filter[attribute]` are required. `filter[attribute]` accepts any attribute name — including the two first-class columns `key` and `name` — and is treated uniformly from the customer's perspective; the server adjusts the underlying query accordingly.  `filter[search]` does a case-insensitive starts-with match. The returned set excludes empty strings and NULL values.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::ContextValuesApi.new
opts = {
  filter_context_type: 'filter_context_type_example', # String | Context type key whose instances should be searched (e.g. `user`).
  filter_attribute: 'filter_attribute_example', # String | Attribute name whose distinct values should be returned (e.g. `first_name`). Accepts `key` and `name` as well as any attribute key stored on the context instance.
  filter_search: 'filter_search_example', # String | Optional case-insensitive starts-with match against the projected attribute value. When omitted, all distinct values are returned in the page.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Context Values
  result = api_instance.list_context_values(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextValuesApi->list_context_values: #{e}"
end
```

#### Using the list_context_values_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ContextValueListResponse>, Integer, Hash)> list_context_values_with_http_info(opts)

```ruby
begin
  # List Context Values
  data, status_code, headers = api_instance.list_context_values_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ContextValueListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling ContextValuesApi->list_context_values_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_context_type** | **String** | Context type key whose instances should be searched (e.g. &#x60;user&#x60;). | [optional] |
| **filter_attribute** | **String** | Attribute name whose distinct values should be returned (e.g. &#x60;first_name&#x60;). Accepts &#x60;key&#x60; and &#x60;name&#x60; as well as any attribute key stored on the context instance. | [optional] |
| **filter_search** | **String** | Optional case-insensitive starts-with match against the projected attribute value. When omitted, all distinct values are returned in the page. | [optional] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**ContextValueListResponse**](ContextValueListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

