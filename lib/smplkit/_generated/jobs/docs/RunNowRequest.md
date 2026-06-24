# SmplkitGeneratedClient::Jobs::RunNowRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **environment** | **String** | The environment to run the job in. Must be one the job is **enabled** in (otherwise the request is rejected). Optional when the target is unambiguous: when the job is enabled in exactly one environment, or your credential is scoped to a single environment, that environment is used. | [optional] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::RunNowRequest.new(
  environment: null
)
```

