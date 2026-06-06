# SmplkitGeneratedClient::Audit::ForwarderEnvironment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **enabled** | **Boolean** | Whether the forwarder delivers events in this environment. A forwarder is enabled in an environment only via this field — the base &#x60;enabled&#x60; is always false. | [optional][default to false] |
| **configuration** | [**HttpConfiguration**](HttpConfiguration.md) | Per-environment delivery configuration override. Omit to inherit the forwarder&#39;s base &#x60;configuration&#x60;. When present, it fully replaces the base configuration for this environment and is validated against the same per-vendor template. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderEnvironment.new(
  enabled: null,
  configuration: null
)
```

