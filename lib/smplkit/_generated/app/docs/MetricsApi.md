# SmplkitGeneratedClient::App::MetricsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**bulk_ingest_metrics**](MetricsApi.md#bulk_ingest_metrics) | **POST** /api/v1/metrics/bulk | Bulk Ingest Metrics |
| [**list_metric_names**](MetricsApi.md#list_metric_names) | **GET** /api/v1/metric_names | List Metric Names |
| [**list_metric_rollups**](MetricsApi.md#list_metric_rollups) | **GET** /api/v1/metric_rollups | List Metric Rollups |
| [**list_metrics**](MetricsApi.md#list_metrics) | **GET** /api/v1/metrics | List Metrics |


## bulk_ingest_metrics

> bulk_ingest_metrics(metric_bulk_request)

Bulk Ingest Metrics

Ingest pre-aggregated metric data points. Returns 202 Accepted with no response body.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::MetricsApi.new
metric_bulk_request = SmplkitGeneratedClient::App::MetricBulkRequest.new({data: [SmplkitGeneratedClient::App::MetricResource.new({type: 'metric', attributes: SmplkitGeneratedClient::App::MetricAttributes.new({name: 'name_example', value: SmplkitGeneratedClient::App::Value.new, period_seconds: 37, recorded_at: Time.now})})]}) # MetricBulkRequest | 

begin
  # Bulk Ingest Metrics
  api_instance.bulk_ingest_metrics(metric_bulk_request)
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->bulk_ingest_metrics: #{e}"
end
```

#### Using the bulk_ingest_metrics_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> bulk_ingest_metrics_with_http_info(metric_bulk_request)

```ruby
begin
  # Bulk Ingest Metrics
  data, status_code, headers = api_instance.bulk_ingest_metrics_with_http_info(metric_bulk_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->bulk_ingest_metrics_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **metric_bulk_request** | [**MetricBulkRequest**](MetricBulkRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## list_metric_names

> <MetricNamesResponse> list_metric_names

List Metric Names

Return distinct metric names (with a representative unit) for this account.  Used by the dashboard to discover which product sections to render. Plain JSON response (not JSON:API) — this is metadata, not a metric resource.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::MetricsApi.new

begin
  # List Metric Names
  result = api_instance.list_metric_names
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metric_names: #{e}"
end
```

#### Using the list_metric_names_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<MetricNamesResponse>, Integer, Hash)> list_metric_names_with_http_info

```ruby
begin
  # List Metric Names
  data, status_code, headers = api_instance.list_metric_names_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <MetricNamesResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metric_names_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**MetricNamesResponse**](MetricNamesResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_metric_rollups

> <MetricRollupListResponse> list_metric_rollups(filter_name, filter_rollup, opts)

List Metric Rollups

Query aggregated metric rollups. Requires filter[rollup] for the aggregation interval.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::MetricsApi.new
filter_name = 'filter_name_example' # String | 
filter_rollup = 'filter_rollup_example' # String | 
opts = {
  filter_recorded_at: 'filter_recorded_at_example' # String | 
}

begin
  # List Metric Rollups
  result = api_instance.list_metric_rollups(filter_name, filter_rollup, opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metric_rollups: #{e}"
end
```

#### Using the list_metric_rollups_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<MetricRollupListResponse>, Integer, Hash)> list_metric_rollups_with_http_info(filter_name, filter_rollup, opts)

```ruby
begin
  # List Metric Rollups
  data, status_code, headers = api_instance.list_metric_rollups_with_http_info(filter_name, filter_rollup, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <MetricRollupListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metric_rollups_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_name** | **String** |  |  |
| **filter_rollup** | **String** |  |  |
| **filter_recorded_at** | **String** |  | [optional] |

### Return type

[**MetricRollupListResponse**](MetricRollupListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_metrics

> <MetricListResponse> list_metrics(filter_name, opts)

List Metrics

Query raw metric rows with filtering by name, time range, and dimensions.

### Examples

```ruby
require 'time'
require 'smplkit_app_client'
# setup authorization
SmplkitGeneratedClient::App.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::App::MetricsApi.new
filter_name = 'filter_name_example' # String | 
opts = {
  filter_recorded_at: 'filter_recorded_at_example' # String | 
}

begin
  # List Metrics
  result = api_instance.list_metrics(filter_name, opts)
  p result
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metrics: #{e}"
end
```

#### Using the list_metrics_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<MetricListResponse>, Integer, Hash)> list_metrics_with_http_info(filter_name, opts)

```ruby
begin
  # List Metrics
  data, status_code, headers = api_instance.list_metrics_with_http_info(filter_name, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <MetricListResponse>
rescue SmplkitGeneratedClient::App::ApiError => e
  puts "Error when calling MetricsApi->list_metrics_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_name** | **String** |  |  |
| **filter_recorded_at** | **String** |  | [optional] |

### Return type

[**MetricListResponse**](MetricListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

