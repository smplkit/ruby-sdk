# SmplkitGeneratedClient::App::EnvironmentUsage

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **flag_rules** | **Integer** | Number of feature-flag targeting rules scoped to this environment. Each flag may contribute multiple rules. |  |
| **flag_env_defaults** | **Integer** | Number of feature flags that declare an environment-level default value for this environment. |  |
| **config_overrides** | **Integer** | Number of config-item overrides keyed to this environment, summed across all configs. |  |
| **logger_overrides** | **Integer** | Number of loggers with an environment-level level override for this environment. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::EnvironmentUsage.new(
  flag_rules: null,
  flag_env_defaults: null,
  config_overrides: null,
  logger_overrides: null
)
```

