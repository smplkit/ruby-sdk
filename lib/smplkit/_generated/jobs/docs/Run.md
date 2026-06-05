# SmplkitGeneratedClient::Jobs::Run

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job** | **String** | The id of the job this run belongs to. |  |
| **job_version** | **Integer** | The job&#39;s version at the time the run executed. | [optional] |
| **trigger** | **String** | Why the run exists: &#x60;SCHEDULE&#x60;, &#x60;MANUAL&#x60; (Run now), or &#x60;RERUN&#x60;. |  |
| **rerun_of** | **String** | The source run&#39;s id; set only when &#x60;trigger&#x60; is &#x60;RERUN&#x60;. | [optional] |
| **scheduled_for** | **Time** | The intended fire time for a scheduled run; &#x60;null&#x60; for manual / rerun runs. | [optional] |
| **status** | **String** | Lifecycle state of the run. |  |
| **started_at** | **Time** | When execution started. | [optional] |
| **finished_at** | **Time** | When execution finished. | [optional] |
| **pending_duration_ms** | **Integer** | Milliseconds the run waited as &#x60;PENDING&#x60; before starting. | [optional] |
| **run_duration_ms** | **Integer** | Milliseconds the run spent executing. | [optional] |
| **total_duration_ms** | **Integer** | Milliseconds from enqueue to finish. | [optional] |
| **failure_reason** | **String** | Why a &#x60;FAILED&#x60; run failed; &#x60;null&#x60; otherwise. | [optional] |
| **error** | **String** | Free-text failure detail, if any. | [optional] |
| **request** | **Hash&lt;String, Object&gt;** | Snapshot of the request that was sent (header values redacted). Forensics only. | [optional] |
| **result** | **Hash&lt;String, Object&gt;** | Outcome of the call. For &#x60;http&#x60;: &#x60;status&#x60;, &#x60;headers&#x60;, &#x60;body&#x60; (capped at 64 KiB), &#x60;body_truncated&#x60;, and the original &#x60;body_bytes&#x60;. | [optional] |
| **created_at** | **Time** | When the run was enqueued (became &#x60;PENDING&#x60;). | [optional] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::Run.new(
  job: null,
  job_version: null,
  trigger: null,
  rerun_of: null,
  scheduled_for: null,
  status: null,
  started_at: null,
  finished_at: null,
  pending_duration_ms: null,
  run_duration_ms: null,
  total_duration_ms: null,
  failure_reason: null,
  error: null,
  request: null,
  result: null,
  created_at: null
)
```

