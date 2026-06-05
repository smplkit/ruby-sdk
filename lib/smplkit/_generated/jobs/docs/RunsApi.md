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

List runs for this account, newest first (cursor paginated).  Use `filter[job]={id}` for a single job's run history.

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
  page_size: 56, # Integer | 
  page_after: 'page_after_example' # String | 
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
| **page_size** | **Integer** |  | [optional] |
| **page_after** | **String** |  | [optional] |

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

