# SmplkitGeneratedClient::Jobs::JobEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether the job schedules runs in this environment. A job runs in an environment only via this field; it is disabled in every environment by default. | [optional][default to false] |
| **schedule** | **String** | Per-environment schedule override. Omit to inherit the job&#39;s base &#x60;schedule&#x60;. When present, it must be a 5-field cron expression (e.g. &#x60;0 3 * * *&#x60;), evaluated in this environment&#39;s effective &#x60;timezone&#x60; (the per-environment override, else the base, else UTC), and is only allowed on a recurring (cron) job — it varies the cadence within that environment. It cannot appear on a manual or one-off job, and cannot change a job&#39;s kind. | [optional] |
| **timezone** | **String** | Per-environment timezone override for evaluating this environment&#39;s cron &#x60;schedule&#x60;. Omit to inherit the base &#x60;timezone&#x60; (else UTC). When present, it must be a valid IANA timezone key (e.g. &#x60;America/New_York&#x60;). Only valid on a recurring (cron) job; it may be set on an environment that inherits the base schedule (it need not also override &#x60;schedule&#x60;). | [optional] |
| **configuration** | [**JobHttpConfiguration**](JobHttpConfiguration.md) | Per-environment HTTP request override. Omit to inherit the job&#39;s base &#x60;configuration&#x60;. When present, it fully replaces the base configuration for runs in this environment. | [optional] |
| **next_run_at** | **Time** | The next scheduled fire time in this environment. &#x60;null&#x60; when the environment is not enabled, or once a one-off run has fired. | [optional][readonly] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::JobEnvironment.new(
  enabled: null,
  schedule: null,
  timezone: null,
  configuration: null,
  next_run_at: null
)
```

