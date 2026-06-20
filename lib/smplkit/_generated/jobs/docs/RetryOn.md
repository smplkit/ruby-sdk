# SmplkitGeneratedClient::Jobs::RetryOn

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **statuses** | **Array&lt;Integer&gt;** | Response status codes that should be retried when a run fails because the response did not match the job&#39;s success status (for example &#x60;[429, 503]&#x60; to retry on rate-limit and unavailable). Each is a 3-digit HTTP status code. Empty matches no status. | [optional] |
| **reasons** | **Array&lt;String&gt;** | Failure reasons that should be retried: &#x60;TIMEOUT&#x60; (the run did not complete in time), &#x60;CONNECTION_ERROR&#x60; (the endpoint could not be reached), or &#x60;NON_SUCCESS_STATUS&#x60; (any non-success response, regardless of &#x60;statuses&#x60;). Empty matches no reason. | [optional] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RetryOn.new(
  statuses: null,
  reasons: null
)
```

