# SmplkitGeneratedClient::Jobs::RetryPolicy

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the policy. |  |
| **max_retries** | **Integer** | How many times a failed run is retried, after the initial attempt — so &#x60;max_retries&#x60; of 3 means up to 4 attempts in total. &#x60;0&#x60; disables retries. Maximum 10. |  |
| **backoff** | **String** | How the wait between retries grows. &#x60;fixed&#x60; waits &#x60;delay_seconds&#x60; before every retry. &#x60;exponential&#x60; doubles the wait each time — &#x60;delay_seconds&#x60;, then &#x60;2×&#x60;, &#x60;4×&#x60;, … — capped at &#x60;max_delay_seconds&#x60;. |  |
| **delay_seconds** | **Integer** | The wait before a retry, in seconds. For &#x60;fixed&#x60; backoff it is the constant wait before every retry; for &#x60;exponential&#x60; it is the base wait that doubles each retry. |  |
| **max_delay_seconds** | **Integer** | The ceiling on the wait between retries, in seconds, for &#x60;exponential&#x60; backoff — once the doubling reaches it, every subsequent retry waits this long. Only valid with &#x60;exponential&#x60; backoff; omit it for &#x60;fixed&#x60;. | [optional] |
| **retry_on** | [**RetryOn**](RetryOn.md) | Which failures are retried. A run is retried only when its failure matches this set; an empty set retries nothing. Some failures are never retried regardless of this value. | [optional] |
| **created_at** | **Time** | When the policy was created. | [optional][readonly] |
| **updated_at** | **Time** | When the policy was last modified. | [optional][readonly] |
| **deleted_at** | **Time** | When the policy was deleted. &#x60;null&#x60; for active policies. | [optional][readonly] |
| **version** | **Integer** | Monotonic counter incremented on every update, starting at 1. | [optional][readonly] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RetryPolicy.new(
  name: null,
  max_retries: null,
  backoff: null,
  delay_seconds: null,
  max_delay_seconds: null,
  retry_on: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

