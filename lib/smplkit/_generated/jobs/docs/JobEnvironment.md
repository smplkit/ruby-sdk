# SmplkitGeneratedClient::Jobs::JobEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether the job schedules runs in this environment. A job runs in an environment only via this field; it is disabled in every environment by default. | [optional][default to false] |
| **schedule** | **String** | Per-environment schedule override. Omit to inherit the job&#39;s base &#x60;schedule&#x60;. When present, it must be a 5-field cron expression evaluated in **UTC** (e.g. &#x60;0 3 * * *&#x60;), and is only allowed on a recurring (cron) job — it varies the cadence within that environment. It cannot appear on a manual or one-off job, and cannot change a job&#39;s kind. | [optional] |
| **configuration** | [**JobHttpConfiguration**](JobHttpConfiguration.md) | Per-environment HTTP request override. Omit to inherit the job&#39;s base &#x60;configuration&#x60;. When present, it fully replaces the base configuration for runs in this environment. | [optional] |
| **next_run_at** | **Time** | The next scheduled fire time in this environment. &#x60;null&#x60; when the environment is not enabled, or once a one-off run has fired. | [optional][readonly] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::JobEnvironment.new(
  enabled: null,
  schedule: null,
  configuration: null,
  next_run_at: null
)
```

