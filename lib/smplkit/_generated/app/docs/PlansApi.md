# SmplkitGeneratedClient::App::PlansApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_plans**](PlansApi.md#list_plans) | **GET** /api/v1/plans | List Plans |


## list_plans

> <PlanListResponse> list_plans(opts)

List Plans

Return all plan tier definitions as JSON:API resources.  Default sort is `sort_order` ascending — the natural ladder defined in `plans.yaml`. Pass `sort=display_name` for an alphabetical view.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::PlansApi.new
opts = {
  sort: 'display_name' # String | Field to sort by. Prefix with `-` for descending order. Default: `sort_order`. Allowed values: `display_name`, `-display_name`, `id`, `-id`, `sort_order`, `-sort_order`.
}

begin
  # List Plans
  result = api_instance.list_plans(opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling PlansApi->list_plans: #{e}"
end
```

#### Using the list_plans_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PlanListResponse>, Integer, Hash)> list_plans_with_http_info(opts)

```ruby
begin
  # List Plans
  data, status_code, headers = api_instance.list_plans_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PlanListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling PlansApi->list_plans_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;sort_order&#x60;. Allowed values: &#x60;display_name&#x60;, &#x60;-display_name&#x60;, &#x60;id&#x60;, &#x60;-id&#x60;, &#x60;sort_order&#x60;, &#x60;-sort_order&#x60;. | [optional][default to &#39;sort_order&#39;] |

### Return type

[**PlanListResponse**](PlanListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

