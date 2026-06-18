# SmplkitGeneratedClient::Jobs::JobEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether the job schedules runs in this environment. A job runs in an environment only via this field; it is disabled in every environment by default. | [optional][default to false] |
| **configuration** | [**JobHttpConfiguration**](JobHttpConfiguration.md) | Per-environment HTTP request override. Omit to inherit the job&#39;s base &#x60;configuration&#x60;. When present, it fully replaces the base configuration for runs in this environment. | [optional] |

## Example

```ruby
require 'smplkit_jobs_client'

instance = SmplkitGeneratedClient::Jobs::JobEnvironment.new(
  enabled: null,
  configuration: null
)
```

