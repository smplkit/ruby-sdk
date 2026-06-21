# SmplkitGeneratedClient::Jobs::RetryPolicy

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the policy. |  |
| **max_retries** | **Integer** | How many times a failed run is retried, after the initial attempt — so &#x60;max_retries&#x60; of 3 means up to 4 attempts in total. &#x60;0&#x60; disables retries. Maximum 10. |  |
| **backoff** | **String** | How the wait between retries grows. &#x60;fixed&#x60; waits &#x60;delay_seconds&#x60; before every retry. &#x60;exponential&#x60; doubles the wait each time — &#x60;delay_seconds&#x60;, then &#x60;2×&#x60;, &#x60;4×&#x60;, … — capped at &#x60;max_delay_seconds&#x60;. |  |
| **delay_seconds** | **Integer** | The wait before a retry, in seconds. For &#x60;fixed&#x60; backoff it is the constant wait before every retry; for &#x60;exponential&#x60; it is the base wait that doubles each retry. |  |
| **max_delay_seconds** | **Integer** | The ceiling on the wait between retries, in seconds, for &#x60;exponential&#x60; backoff — once the doubling reaches it, every subsequent retry waits this long. Only valid with &#x60;exponential&#x60; backoff; omit it for &#x60;fixed&#x60;. | [optional] |
| **retry_on_timeout** | **Boolean** | Retry a run that failed because the request did not complete within the job&#39;s timeout. Defaults to &#x60;false&#x60; (timeouts are not retried). | [optional][default to false] |
| **retry_on_connection_error** | **Boolean** | Retry a run that failed because the destination could not be reached (DNS, connection refused, TLS, or transport error). Defaults to &#x60;false&#x60; (connection errors are not retried). | [optional][default to false] |
| **retry_statuses** | **Array&lt;String&gt;** | Allowlist of response status patterns to retry when a run fails because the response did not match the job&#39;s success status. Each element is either an exact 3-digit HTTP code (e.g. &#x60;429&#x60;) or a status class (&#x60;1xx&#x60;, &#x60;2xx&#x60;, &#x60;3xx&#x60;, &#x60;4xx&#x60;, &#x60;5xx&#x60;) — for example &#x60;[\&quot;429\&quot;, \&quot;5xx\&quot;]&#x60; to retry on rate-limit and any server error. Empty (the default) matches no status, so nothing is retried on a non-success response. | [optional] |
| **retry_statuses_except** | **Array&lt;String&gt;** | Subtractions from &#x60;retry_statuses&#x60;, using the same exact-code or class syntax. A status that matches both lists is not retried — &#x60;except&#x60; wins on overlap — so &#x60;retry_statuses&#x60; of &#x60;[\&quot;5xx\&quot;]&#x60; with &#x60;retry_statuses_except&#x60; of &#x60;[\&quot;501\&quot;]&#x60; retries every server error except &#x60;501&#x60;. An element that does not overlap &#x60;retry_statuses&#x60; is allowed and simply has no effect. Empty (the default) subtracts nothing. | [optional] |
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
  retry_on_timeout: null,
  retry_on_connection_error: null,
  retry_statuses: null,
  retry_statuses_except: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

