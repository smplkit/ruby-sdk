# SmplkitGeneratedClient::Jobs::Usage

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **period** | **String** | The usage period this report covers, as &#x60;YYYY-MM&#x60; (UTC). |  |
| **runs_used** | **Integer** | Runs metered so far this period. |  |
| **runs_included** | **Integer** | Runs included in the plan this period (&#x60;-1&#x60; means unlimited). |  |
| **active_jobs** | **Integer** | Number of recurring (scheduled) jobs. |  |
| **active_jobs_limit** | **Integer** | Maximum recurring jobs the plan allows (&#x60;-1&#x60; means unlimited). |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::Usage.new(
  period: null,
  runs_used: null,
  runs_included: null,
  active_jobs: null,
  active_jobs_limit: null
)
```

