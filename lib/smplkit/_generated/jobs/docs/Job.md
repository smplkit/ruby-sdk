# SmplkitGeneratedClient::Jobs::Job

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the job. |  |
| **description** | **String** | Free-text description for the job. | [optional] |
| **type** | **String** | Job type. Only &#x60;http&#x60; is supported today. | [optional][default to &#39;http&#39;] |
| **schedule** | **String** | The base schedule every environment inherits unless it overrides it, and the field that determines the job&#39;s &#x60;kind&#x60;. Omit it (or send &#x60;null&#x60;) to create a permanent **manual** job that never auto-fires and runs only when triggered. Provide a 5-field cron expression evaluated in the job&#39;s &#x60;timezone&#x60; (UTC by default) for a **recurring** job, an ISO-8601 datetime for a **one-off** run at that instant, or the literal &#x60;now&#x60; for a one-off run as soon as possible. A datetime or &#x60;now&#x60; job disables itself after it fires. | [optional] |
| **timezone** | **String** | IANA timezone the cron &#x60;schedule&#x60; is evaluated in (e.g. &#x60;America/New_York&#x60;); null or omitted means UTC. The base every environment inherits unless it sets its own &#x60;timezone&#x60;. The cron fires on this zone&#39;s wall clock (DST-aware) while &#x60;next_run_at&#x60; is still reported as a UTC instant. Only valid on a recurring (cron) job — it cannot be set on a manual or one-off job. | [optional] |
| **configuration** | [**JobHttpConfiguration**](JobHttpConfiguration.md) | The HTTP request to perform, including method, url, headers, body, and timeout. |  |
| **environments** | [**Hash&lt;String, JobEnvironment&gt;**](JobEnvironment.md) | Per-environment overrides keyed by environment key (e.g. &#x60;production&#x60;, &#x60;staging&#x60;). Each entry sets &#x60;enabled&#x60; (whether the job is enabled — scheduled, for a recurring job, or triggerable, for a manual job — in that environment), an optional &#x60;schedule&#x60; override (a cron expression for recurring jobs; omit to inherit the base &#x60;schedule&#x60;), an optional &#x60;timezone&#x60; override (an IANA zone for recurring jobs; omit to inherit the base &#x60;timezone&#x60;, else UTC), and an optional &#x60;configuration&#x60; override (omit to inherit the base &#x60;configuration&#x60;); it also reports the read-only &#x60;next_run_at&#x60; for that environment. A job with no entry for an environment is disabled there. For a recurring or manual job, supply this map to choose where it runs. For a one-off job, the environment it is created in is recorded here automatically — name it with the &#x60;X-Smplkit-Environment&#x60; header. Every referenced environment must exist for the account. | [optional] |
| **concurrency_policy** | **String** | How overlapping runs are handled. &#x60;ALLOW&#x60; (the only value today) permits them. | [optional][default to &#39;ALLOW&#39;] |
| **kind** | **String** | How the job runs, derived from its base &#x60;schedule&#x60;: &#x60;recurring&#x60; for a cron schedule (fires on a repeating cadence), &#x60;manual&#x60; for no schedule (never auto-fires; runs only when triggered), or &#x60;one_off&#x60; for a &#x60;now&#x60; or datetime schedule (runs a single time, then is spent). | [optional][readonly] |
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
  type: null,
  schedule: null,
  timezone: null,
  configuration: null,
  environments: null,
  concurrency_policy: null,
  kind: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

