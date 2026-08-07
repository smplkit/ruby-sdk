# SmplkitGeneratedClient::Jobs::RunStat

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **total** | **Integer** | Runs matching the filters. |  |
| **tally** | [**RunStatTally**](RunStatTally.md) | Those runs counted by lifecycle state. |  |
| **buckets** | [**Array&lt;RunStatBucket&gt;**](RunStatBucket.md) | Run counts over time at the requested &#x60;bucket&#x60; granularity, ordered by bucket start. Only buckets containing at least one run are listed — treat missing buckets as zero. &#x60;null&#x60; when the request did not include the &#x60;bucket&#x60; directive. | [optional] |
| **recent_failures** | [**Array&lt;RunStatFailure&gt;**](RunStatFailure.md) | The most recently created &#x60;FAILED&#x60; runs matching the filters, newest first — at most 3. |  |
| **next_scheduled** | [**RunStatNextScheduled**](RunStatNextScheduled.md) | The soonest &#x60;PENDING&#x60; run with a fire time at or after the request, or &#x60;null&#x60; when nothing upcoming is scheduled. The &#x60;filter[created_at]&#x60; range does not apply here — a run scheduled long ago for a future fire time is still next. | [optional] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunStat.new(
  total: null,
  tally: null,
  buckets: null,
  recent_failures: null,
  next_scheduled: null
)
```

