# SmplkitGeneratedClient::Jobs::RunStatTally

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pending** | **Integer** | Runs in status &#x60;PENDING&#x60;. |  |
| **running** | **Integer** | Runs in status &#x60;RUNNING&#x60;. |  |
| **succeeded** | **Integer** | Runs in status &#x60;SUCCEEDED&#x60;. |  |
| **failed** | **Integer** | Runs in status &#x60;FAILED&#x60;. |  |
| **canceled** | **Integer** | Runs in status &#x60;CANCELED&#x60;. |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunStatTally.new(
  pending: null,
  running: null,
  succeeded: null,
  failed: null,
  canceled: null
)
```

