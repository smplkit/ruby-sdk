# SmplkitGeneratedClient::Jobs::RunsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**cancel_run**](RunsApi.md#cancel_run) | **POST** /api/v1/runs/{run_id}/actions/cancel | Cancel Run |
| [**get_run**](RunsApi.md#get_run) | **GET** /api/v1/runs/{run_id} | Get Run |
| [**list_runs**](RunsApi.md#list_runs) | **GET** /api/v1/runs | List Runs |
| [**rerun_run**](RunsApi.md#rerun_run) | **POST** /api/v1/runs/{run_id}/actions/rerun | Rerun Run |


## cancel_run

> <RunResponse> cancel_run(run_id)

Cancel Run

Cancel a pending or running run.  Returns `409` if the run is already in a terminal state. Canceling a running run stops us tracking it, but the HTTP request may already be in flight — cancel means \"stop tracking,\" not \"guaranteed it didn't happen.\"

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RunsApi.new
run_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Cancel Run
  result = api_instance.cancel_run(run_id)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->cancel_run: #{e}"
end
```

#### Using the cancel_run_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RunResponse>, Integer, Hash)> cancel_run_with_http_info(run_id)

```ruby
begin
  # Cancel Run
  data, status_code, headers = api_instance.cancel_run_with_http_info(run_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RunResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->cancel_run_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **run_id** | **String** |  |  |

### Return type

[**RunResponse**](RunResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## get_run

> <RunResponse> get_run(run_id)

Get Run

Retrieve a single run by its id.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RunsApi.new
run_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Get Run
  result = api_instance.get_run(run_id)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->get_run: #{e}"
end
```

#### Using the get_run_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RunResponse>, Integer, Hash)> get_run_with_http_info(run_id)

```ruby
begin
  # Get Run
  data, status_code, headers = api_instance.get_run_with_http_info(run_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RunResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->get_run_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **run_id** | **String** |  |  |

### Return type

[**RunResponse**](RunResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_runs

> <RunListResponse> list_runs(opts)

List Runs

List runs for this account (cursor paginated).  Default sort is `-created_at` (newest first). Sort by `created_at`, `started_at`, `finished_at`, `scheduled_for`, `status`, `job`, or `total_duration_ms`, ascending or descending (prefix `-` for descending). Keep the same `sort` value across paginated requests so the cursor stays consistent. Runs that have not reached the relevant lifecycle point (`started_at`, `finished_at`, `scheduled_for`, `total_duration_ms` unset) sort to the end regardless of direction.  Filters compose with AND:  - `filter[job]={id}` — a single job's run history. - `filter[status]` — one state or a comma-separated list (any-of). - `filter[environment]` — one environment key or a comma-separated list   (any-of); omitted covers every environment you can access. - `filter[created_at]` / `filter[started_at]` / `filter[finished_at]` /   `filter[scheduled_for]` — half-open `[start,end)` date ranges (see each   parameter for the interval syntax).

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RunsApi.new
opts = {
  filter_job: 'filter_job_example', # String | 
  filter_status: 'filter_status_example', # String | Restrict to runs in the given lifecycle state. One of `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `CANCELED`, or a comma-separated list of them to match any (e.g. `SUCCEEDED,FAILED`).
  filter_environment: 'filter_environment_example', # String | Comma-separated list of environment keys to scope results to (e.g. `production,staging`). When omitted, results cover every environment you can access.
  filter_created_at: 'filter_created_at_example', # String | Restrict to runs whose `created_at` falls in a half-open `[start,end)` interval. Bounds are ISO-8601 timestamps; `*` leaves a bound open. The leading bracket is `[` (inclusive) or `(` (exclusive) and the trailing bracket is `]` (inclusive) or `)` (exclusive). Example: `[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)` selects the first week of June; `[2026-06-01T00:00:00Z,*)` is everything from then onward.
  filter_started_at: 'filter_started_at_example', # String | Restrict to runs whose `started_at` falls in a half-open `[start,end)` interval. Bounds are ISO-8601 timestamps; `*` leaves a bound open. The leading bracket is `[` (inclusive) or `(` (exclusive) and the trailing bracket is `]` (inclusive) or `)` (exclusive). Example: `[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)` selects the first week of June; `[2026-06-01T00:00:00Z,*)` is everything from then onward.
  filter_finished_at: 'filter_finished_at_example', # String | Restrict to runs whose `finished_at` falls in a half-open `[start,end)` interval. Bounds are ISO-8601 timestamps; `*` leaves a bound open. The leading bracket is `[` (inclusive) or `(` (exclusive) and the trailing bracket is `]` (inclusive) or `)` (exclusive). Example: `[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)` selects the first week of June; `[2026-06-01T00:00:00Z,*)` is everything from then onward.
  filter_scheduled_for: 'filter_scheduled_for_example', # String | Restrict to runs whose `scheduled_for` falls in a half-open `[start,end)` interval. Bounds are ISO-8601 timestamps; `*` leaves a bound open. The leading bracket is `[` (inclusive) or `(` (exclusive) and the trailing bracket is `]` (inclusive) or `)` (exclusive). Example: `[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)` selects the first week of June; `[2026-06-01T00:00:00Z,*)` is everything from then onward.
  page_size: 56, # Integer | Number of runs per page. Optional; defaults to `50` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  page_after: 'page_after_example', # String | 
  sort: 'created_at' # String | Field to sort by. Prefix with `-` for descending order. Default: `-created_at`. Allowed values: `created_at`, `-created_at`, `finished_at`, `-finished_at`, `job`, `-job`, `scheduled_for`, `-scheduled_for`, `started_at`, `-started_at`, `status`, `-status`, `total_duration_ms`, `-total_duration_ms`.
}

begin
  # List Runs
  result = api_instance.list_runs(opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->list_runs: #{e}"
end
```

#### Using the list_runs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RunListResponse>, Integer, Hash)> list_runs_with_http_info(opts)

```ruby
begin
  # List Runs
  data, status_code, headers = api_instance.list_runs_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RunListResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->list_runs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_job** | **String** |  | [optional] |
| **filter_status** | **String** | Restrict to runs in the given lifecycle state. One of &#x60;PENDING&#x60;, &#x60;RUNNING&#x60;, &#x60;SUCCEEDED&#x60;, &#x60;FAILED&#x60;, &#x60;CANCELED&#x60;, or a comma-separated list of them to match any (e.g. &#x60;SUCCEEDED,FAILED&#x60;). | [optional] |
| **filter_environment** | **String** | Comma-separated list of environment keys to scope results to (e.g. &#x60;production,staging&#x60;). When omitted, results cover every environment you can access. | [optional] |
| **filter_created_at** | **String** | Restrict to runs whose &#x60;created_at&#x60; falls in a half-open &#x60;[start,end)&#x60; interval. Bounds are ISO-8601 timestamps; &#x60;*&#x60; leaves a bound open. The leading bracket is &#x60;[&#x60; (inclusive) or &#x60;(&#x60; (exclusive) and the trailing bracket is &#x60;]&#x60; (inclusive) or &#x60;)&#x60; (exclusive). Example: &#x60;[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)&#x60; selects the first week of June; &#x60;[2026-06-01T00:00:00Z,*)&#x60; is everything from then onward. | [optional] |
| **filter_started_at** | **String** | Restrict to runs whose &#x60;started_at&#x60; falls in a half-open &#x60;[start,end)&#x60; interval. Bounds are ISO-8601 timestamps; &#x60;*&#x60; leaves a bound open. The leading bracket is &#x60;[&#x60; (inclusive) or &#x60;(&#x60; (exclusive) and the trailing bracket is &#x60;]&#x60; (inclusive) or &#x60;)&#x60; (exclusive). Example: &#x60;[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)&#x60; selects the first week of June; &#x60;[2026-06-01T00:00:00Z,*)&#x60; is everything from then onward. | [optional] |
| **filter_finished_at** | **String** | Restrict to runs whose &#x60;finished_at&#x60; falls in a half-open &#x60;[start,end)&#x60; interval. Bounds are ISO-8601 timestamps; &#x60;*&#x60; leaves a bound open. The leading bracket is &#x60;[&#x60; (inclusive) or &#x60;(&#x60; (exclusive) and the trailing bracket is &#x60;]&#x60; (inclusive) or &#x60;)&#x60; (exclusive). Example: &#x60;[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)&#x60; selects the first week of June; &#x60;[2026-06-01T00:00:00Z,*)&#x60; is everything from then onward. | [optional] |
| **filter_scheduled_for** | **String** | Restrict to runs whose &#x60;scheduled_for&#x60; falls in a half-open &#x60;[start,end)&#x60; interval. Bounds are ISO-8601 timestamps; &#x60;*&#x60; leaves a bound open. The leading bracket is &#x60;[&#x60; (inclusive) or &#x60;(&#x60; (exclusive) and the trailing bracket is &#x60;]&#x60; (inclusive) or &#x60;)&#x60; (exclusive). Example: &#x60;[2026-06-01T00:00:00Z,2026-06-08T00:00:00Z)&#x60; selects the first week of June; &#x60;[2026-06-01T00:00:00Z,*)&#x60; is everything from then onward. | [optional] |
| **page_size** | **Integer** | Number of runs per page. Optional; defaults to &#x60;50&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional] |
| **page_after** | **String** |  | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;-created_at&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;finished_at&#x60;, &#x60;-finished_at&#x60;, &#x60;job&#x60;, &#x60;-job&#x60;, &#x60;scheduled_for&#x60;, &#x60;-scheduled_for&#x60;, &#x60;started_at&#x60;, &#x60;-started_at&#x60;, &#x60;status&#x60;, &#x60;-status&#x60;, &#x60;total_duration_ms&#x60;, &#x60;-total_duration_ms&#x60;. | [optional][default to &#39;-created_at&#39;] |

### Return type

[**RunListResponse**](RunListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## rerun_run

> <RunResponse> rerun_run(run_id)

Rerun Run

Spawn a new run from a prior run, using the job's current configuration.  Returns `409` if the run's parent job has been deleted.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::RunsApi.new
run_id = '38400000-8cf0-11bd-b23e-10b96e4ef00d' # String | 

begin
  # Rerun Run
  result = api_instance.rerun_run(run_id)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->rerun_run: #{e}"
end
```

#### Using the rerun_run_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RunResponse>, Integer, Hash)> rerun_run_with_http_info(run_id)

```ruby
begin
  # Rerun Run
  data, status_code, headers = api_instance.rerun_run_with_http_info(run_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RunResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling RunsApi->rerun_run_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **run_id** | **String** |  |  |

### Return type

[**RunResponse**](RunResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json

