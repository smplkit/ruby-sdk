# SmplkitGeneratedClient::Jobs::RunRetry

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **of** | **String** | The id of the chain&#39;s original run — the first attempt that failed and started the chain. |  |
| **attempt** | **Integer** | Which retry this run is: &#x60;1&#x60; for the first retry, &#x60;2&#x60; for the second, and so on. |  |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunRetry.new(
  of: null,
  attempt: null
)
```

