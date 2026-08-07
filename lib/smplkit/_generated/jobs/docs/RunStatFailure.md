# SmplkitGeneratedClient::Jobs::RunStatFailure

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job** | **String** | Key of the job the failed run belongs to. |  |
| **job_name** | **String** | Display name of that job, resolved at read time; &#x60;null&#x60; when the job no longer exists. | [optional] |
| **failure_reason** | **String** | Why the run failed; &#x60;null&#x60; when unrecorded. | [optional] |
| **created_at** | **Time** | When the failed run was created. |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunStatFailure.new(
  job: null,
  job_name: null,
  failure_reason: null,
  created_at: null
)
```

