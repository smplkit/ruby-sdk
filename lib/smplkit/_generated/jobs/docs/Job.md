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
| **environments** | **Hash&lt;String, Hash&lt;String, Object&gt;&gt;** | Per-environment overrides keyed by environment key (e.g. &#x60;production&#x60;, &#x60;staging&#x60;). Each entry is a flat, sparse overlay: only the leaves that differ from the base definition are present, and everything absent is inherited. Set &#x60;enabled&#x60; to &#x60;true&#x60; to run the job in that environment (the base is disabled everywhere; an environment with no entry, or an entry without &#x60;enabled: true&#x60;, does not run). Overridable leaves are &#x60;url&#x60;, &#x60;method&#x60;, &#x60;timeout&#x60;, &#x60;body&#x60;, &#x60;success_status&#x60;, &#x60;tls_verify&#x60;, &#x60;ca_cert&#x60;, &#x60;schedule&#x60; and &#x60;timezone&#x60; (recurring jobs only), &#x60;retry_policy&#x60; (the &#x60;id&#x60; of a retry policy, or &#x60;Default&#x60;), and an individual header as &#x60;headers.&lt;name&gt;&#x60; (e.g. &#x60;headers.Authorization&#x60;). On read, each entry also reports the read-only &#x60;next_run_at&#x60; for that environment (the next fire time, or &#x60;null&#x60;). For a recurring or manual job, supply this map to choose where it runs. For a one-off job, the environment it is created in is recorded here automatically — name it with the &#x60;X-Smplkit-Environment&#x60; header. Every referenced environment must exist for the account. | [optional] |
| **concurrency_policy** | **String** | How overlapping runs are handled. &#x60;ALLOW&#x60; (the only value today) permits them. | [optional][default to &#39;ALLOW&#39;] |
| **retry_policy** | **String** | The base retry policy for failed runs — the &#x60;id&#x60; of a retry policy (or the built-in &#x60;Default&#x60;), overridable per environment. Omit (or send &#x60;null&#x60;) to use &#x60;Default&#x60;, which never retries — so a job that sets nothing behaves exactly as before retries existed. | [optional] |
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
  retry_policy: null,
  kind: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

