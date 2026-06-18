# SmplkitGeneratedClient::Jobs::JobsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**create_job**](JobsApi.md#create_job) | **POST** /api/v1/jobs | Create Job |
| [**delete_job**](JobsApi.md#delete_job) | **DELETE** /api/v1/jobs/{job_id} | Delete Job |
| [**get_job**](JobsApi.md#get_job) | **GET** /api/v1/jobs/{job_id} | Get Job |
| [**list_jobs**](JobsApi.md#list_jobs) | **GET** /api/v1/jobs | List Jobs |
| [**run_job_now**](JobsApi.md#run_job_now) | **POST** /api/v1/jobs/{job_id}/actions/run | Run Job Now |
| [**update_job**](JobsApi.md#update_job) | **PUT** /api/v1/jobs/{job_id} | Update Job |


## create_job

> <JobResponse> create_job(job_create_request, opts)

Create Job

Create a job for this account.  The caller supplies the job's id as `data.id`. Ids are unique within an account and immutable. A recurring job supplies `environments` to choose where it runs and begins scheduling immediately in each enabled environment. A one-off job is created in the environment named by the `X-Smplkit-Environment` header (implied when the credential is scoped to a single environment).

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
job_create_request = SmplkitGeneratedClient::Jobs::JobCreateRequest.new({data: SmplkitGeneratedClient::Jobs::JobCreateResource.new({id: 'id_example', attributes: SmplkitGeneratedClient::Jobs::Job.new({name: 'name_example', schedule: 'schedule_example', configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new({url: 'url_example'})})})}) # JobCreateRequest | 
opts = {
  x_smplkit_environment: 'x_smplkit_environment_example' # String | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its `environments` map.
}

begin
  # Create Job
  result = api_instance.create_job(job_create_request, opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->create_job: #{e}"
end
```

#### Using the create_job_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<JobResponse>, Integer, Hash)> create_job_with_http_info(job_create_request, opts)

```ruby
begin
  # Create Job
  data, status_code, headers = api_instance.create_job_with_http_info(job_create_request, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <JobResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->create_job_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job_create_request** | [**JobCreateRequest**](JobCreateRequest.md) |  |  |
| **x_smplkit_environment** | **String** | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its &#x60;environments&#x60; map. | [optional] |

### Return type

[**JobResponse**](JobResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json


## delete_job

> delete_job(job_id)

Delete Job

Delete a job. Its run history is retained; the id may be reused later.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
job_id = 'job_id_example' # String | 

begin
  # Delete Job
  api_instance.delete_job(job_id)
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->delete_job: #{e}"
end
```

#### Using the delete_job_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> delete_job_with_http_info(job_id)

```ruby
begin
  # Delete Job
  data, status_code, headers = api_instance.delete_job_with_http_info(job_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->delete_job_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job_id** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## get_job

> <JobResponse> get_job(job_id)

Get Job

Retrieve a single job by its id.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
job_id = 'job_id_example' # String | 

begin
  # Get Job
  result = api_instance.get_job(job_id)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->get_job: #{e}"
end
```

#### Using the get_job_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<JobResponse>, Integer, Hash)> get_job_with_http_info(job_id)

```ruby
begin
  # Get Job
  data, status_code, headers = api_instance.get_job_with_http_info(job_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <JobResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->get_job_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job_id** | **String** |  |  |

### Return type

[**JobResponse**](JobResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## list_jobs

> <JobListResponse> list_jobs(opts)

List Jobs

List this account's jobs.  Default sort is `name` ascending. Sort by `name`, `created_at`, or `updated_at`, ascending or descending (prefix `-` for descending). Filter with `filter[recurring]` and `filter[name]` (case-insensitive substring match on the name); filters compose with AND. Each job reports its per-environment enablement and `next_run_at` inside its `environments` map; a scoped caller sees that map narrowed to the environments it may access.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
opts = {
  filter_recurring: true, # Boolean | 
  filter_name: 'filter_name_example', # String | Case-insensitive substring match on the job `name` (matches when the name contains the given text).
  sort: 'created_at', # String | Field to sort by. Prefix with `-` for descending order. Default: `name`. Allowed values: `created_at`, `-created_at`, `name`, `-name`, `updated_at`, `-updated_at`.
  page_number: 56, # Integer | 1-based page number to return. Optional; defaults to `1` when omitted. Must be `>= 1` — requests with a smaller value are rejected with a 400 error.
  page_size: 56, # Integer | Number of items per page. Optional; defaults to `1000` when omitted. Must be between `1` and `1000` inclusive — requests outside that range are rejected with a 400 error.
  meta_total: true # Boolean | When `true`, the response's `meta.pagination` block includes `total` (the total number of matching items across all pages) and `total_pages`. Computing these requires an extra `COUNT` query, so omit (or pass `false`) when the totals are not needed. Defaults to `false`.
}

begin
  # List Jobs
  result = api_instance.list_jobs(opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->list_jobs: #{e}"
end
```

#### Using the list_jobs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<JobListResponse>, Integer, Hash)> list_jobs_with_http_info(opts)

```ruby
begin
  # List Jobs
  data, status_code, headers = api_instance.list_jobs_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <JobListResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->list_jobs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **filter_recurring** | **Boolean** |  | [optional] |
| **filter_name** | **String** | Case-insensitive substring match on the job &#x60;name&#x60; (matches when the name contains the given text). | [optional] |
| **sort** | **String** | Field to sort by. Prefix with &#x60;-&#x60; for descending order. Default: &#x60;name&#x60;. Allowed values: &#x60;created_at&#x60;, &#x60;-created_at&#x60;, &#x60;name&#x60;, &#x60;-name&#x60;, &#x60;updated_at&#x60;, &#x60;-updated_at&#x60;. | [optional][default to &#39;name&#39;] |
| **page_number** | **Integer** | 1-based page number to return. Optional; defaults to &#x60;1&#x60; when omitted. Must be &#x60;&gt;&#x3D; 1&#x60; — requests with a smaller value are rejected with a 400 error. | [optional][default to 1] |
| **page_size** | **Integer** | Number of items per page. Optional; defaults to &#x60;1000&#x60; when omitted. Must be between &#x60;1&#x60; and &#x60;1000&#x60; inclusive — requests outside that range are rejected with a 400 error. | [optional][default to 1000] |
| **meta_total** | **Boolean** | When &#x60;true&#x60;, the response&#39;s &#x60;meta.pagination&#x60; block includes &#x60;total&#x60; (the total number of matching items across all pages) and &#x60;total_pages&#x60;. Computing these requires an extra &#x60;COUNT&#x60; query, so omit (or pass &#x60;false&#x60;) when the totals are not needed. Defaults to &#x60;false&#x60;. | [optional][default to false] |

### Return type

[**JobListResponse**](JobListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## run_job_now

> <RunResponse> run_job_now(job_id, opts)

Run Job Now

Trigger one immediate run of the job (a `MANUAL` run).  The job's schedule and enabled state are untouched. The run executes in the environment named by the `X-Smplkit-Environment` header; when the job is enabled in exactly one environment that environment is used, and a single-environment credential implies it. The run executes the job's effective configuration for that environment. It is enqueued and executed by the worker; if the account is over its run allotment the run will fail with reason `QUOTA_EXCEEDED` rather than being rejected here.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
job_id = 'job_id_example' # String | 
opts = {
  x_smplkit_environment: 'x_smplkit_environment_example' # String | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its `environments` map.
}

begin
  # Run Job Now
  result = api_instance.run_job_now(job_id, opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->run_job_now: #{e}"
end
```

#### Using the run_job_now_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RunResponse>, Integer, Hash)> run_job_now_with_http_info(job_id, opts)

```ruby
begin
  # Run Job Now
  data, status_code, headers = api_instance.run_job_now_with_http_info(job_id, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RunResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->run_job_now_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job_id** | **String** |  |  |
| **x_smplkit_environment** | **String** | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its &#x60;environments&#x60; map. | [optional] |

### Return type

[**RunResponse**](RunResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/vnd.api+json


## update_job

> <JobResponse> update_job(job_id, job_request, opts)

Update Job

Replace an existing job. Every writable field is overwritten.  Set enablement per environment via the `environments` map (a recurring job), or by recreating a one-off job in the desired environment. Each environment may carry its own cron `schedule` override. Editing an environment's effective schedule recomputes its next fire time; an edit that leaves an environment's schedule unchanged preserves its existing cadence.

### Examples

```ruby
require 'time'
require 'smplkit_jobs_client'
# setup authorization
SmplkitGeneratedClient::Jobs.configure do |config|
  # Configure Bearer authorization: HTTPBearer
  config.access_token = 'YOUR_BEARER_TOKEN'
end

api_instance = SmplkitGeneratedClient::Jobs::JobsApi.new
job_id = 'job_id_example' # String | 
job_request = SmplkitGeneratedClient::Jobs::JobRequest.new({data: SmplkitGeneratedClient::Jobs::JobResource.new({attributes: SmplkitGeneratedClient::Jobs::Job.new({name: 'name_example', schedule: 'schedule_example', configuration: SmplkitGeneratedClient::Jobs::JobHttpConfiguration.new({url: 'url_example'})})})}) # JobRequest | 
opts = {
  x_smplkit_environment: 'x_smplkit_environment_example' # String | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its `environments` map.
}

begin
  # Update Job
  result = api_instance.update_job(job_id, job_request, opts)
  p result
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->update_job: #{e}"
end
```

#### Using the update_job_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<JobResponse>, Integer, Hash)> update_job_with_http_info(job_id, job_request, opts)

```ruby
begin
  # Update Job
  data, status_code, headers = api_instance.update_job_with_http_info(job_id, job_request, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <JobResponse>
rescue SmplkitGeneratedClient::Jobs::ApiError => e
  puts "Error when calling JobsApi->update_job_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job_id** | **String** |  |  |
| **job_request** | [**JobRequest**](JobRequest.md) |  |  |
| **x_smplkit_environment** | **String** | The environment to operate in. Names the single environment a one-off job is born in (or a manual run executes in). Optional when the credential is scoped to a single environment (which is then implied); required when the credential can reach several environments and the choice is otherwise ambiguous. Ignored for a recurring job, whose environments come from its &#x60;environments&#x60; map. | [optional] |

### Return type

[**JobResponse**](JobResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

- **Content-Type**: application/vnd.api+json
- **Accept**: application/vnd.api+json

