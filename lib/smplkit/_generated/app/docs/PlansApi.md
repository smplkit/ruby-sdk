# SmplkitGeneratedClient::App::PlansApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**list_plans**](PlansApi.md#list_plans) | **GET** /api/v1/plans | List Plans |


## list_plans

> <PlanListResponse> list_plans

List Plans

Return all plan tier definitions as JSON:API resources.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'

api_instance = SmplkitGeneratedClient::App::PlansApi.new

begin
  # List Plans
  result = api_instance.list_plans
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling PlansApi->list_plans: #{e}"
end
```

#### Using the list_plans_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PlanListResponse>, Integer, Hash)> list_plans_with_http_info

```ruby
begin
  # List Plans
  data, status_code, headers = api_instance.list_plans_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PlanListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling PlansApi->list_plans_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**PlanListResponse**](PlanListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

