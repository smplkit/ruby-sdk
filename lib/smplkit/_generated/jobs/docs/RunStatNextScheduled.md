# SmplkitGeneratedClient::Jobs::RunStatNextScheduled

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **job** | **String** | Key of the job the run belongs to. |  |
| **job_name** | **String** | Display name of that job, resolved at read time; &#x60;null&#x60; when the job no longer exists. | [optional] |
| **scheduled_for** | **Time** | The intended fire time. |  |
| **environment** | **String** | Environment the run will execute in. |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunStatNextScheduled.new(
  job: null,
  job_name: null,
  scheduled_for: null,
  environment: null
)
```

