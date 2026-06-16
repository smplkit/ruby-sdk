# SmplkitGeneratedClient::Jobs::Job

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the job. |  |
| **description** | **String** | Free-text description for the job. | [optional] |
| **enabled** | **Boolean** | Whether the job is scheduling runs. Set to &#x60;false&#x60; to pause without deleting. | [optional][default to true] |
| **type** | **String** | Job type. Only &#x60;http&#x60; is supported today. | [optional][default to &#39;http&#39;] |
| **schedule** | **String** | When the job runs. One of: an ISO-8601 datetime (a one-off run at that instant), a 5-field cron expression evaluated in **UTC** (recurring), or the literal &#x60;now&#x60; (run once, as soon as possible). A datetime or &#x60;now&#x60; job disables itself after it fires. |  |
| **configuration** | [**JobHttpConfiguration**](JobHttpConfiguration.md) | The HTTP request to perform, including method, url, headers, body, and timeout. |  |
| **concurrency_policy** | **String** | How overlapping runs are handled. &#x60;ALLOW&#x60; (the only value today) permits them. | [optional][default to &#39;ALLOW&#39;] |
| **next_run_at** | **Time** | The next scheduled fire time. &#x60;null&#x60; once a one-off job has fired. | [optional][readonly] |
| **recurring** | **Boolean** | Whether the job runs on a repeating schedule. &#x60;true&#x60; for a cron schedule; &#x60;false&#x60; for a one-off datetime or &#x60;now&#x60; schedule, which runs a single time. Derived from &#x60;schedule&#x60;. | [optional][readonly] |
| **created_at** | **Time** | When the job was created. | [optional][readonly] |
| **updated_at** | **Time** | When the job was last modified. | [optional][readonly] |
| **deleted_at** | **Time** | When the job was deleted. &#x60;null&#x60; for active jobs. | [optional][readonly] |
| **version** | **Integer** | Monotonic counter incremented on every update, starting at 1. | [optional][readonly] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::Job.new(
  name: null,
  description: null,
  enabled: null,
  type: null,
  schedule: null,
  configuration: null,
  concurrency_policy: null,
  next_run_at: null,
  recurring: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

