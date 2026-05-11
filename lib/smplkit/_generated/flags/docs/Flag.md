# SmplkitGeneratedClient::Flags::Flag

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable display name for the flag. |  |
| **description** | **String** | Human-readable description of the flag&#39;s purpose. | [optional] |
| **type** | **String** | Value type of the flag. Accepted case-insensitively. Changing the type cascades to &#x60;values&#x60;, &#x60;default&#x60;, and every environment&#39;s rules and default. |  |
| **default** | **Object** |  |  |
| **values** | [**Array&lt;FlagValue&gt;**](FlagValue.md) | Ordered set of allowed values for a constrained flag, or &#x60;null&#x60; for an unconstrained flag. &#x60;BOOLEAN&#x60; flags, if constrained, must declare exactly two values. | [optional] |
| **environments** | [**Hash&lt;String, FlagEnvironment&gt;**](FlagEnvironment.md) | Per-environment configuration keyed by environment name (&#x60;production&#x60;, &#x60;staging&#x60;, etc.). Environments not listed fall back to the flag&#39;s global &#x60;default&#x60;. | [optional] |
| **managed** | **Boolean** | &#x60;true&#x60; when the flag was created through the API, &#x60;false&#x60; when it was auto-discovered from a bulk-register call. Auto-discovered flags can be edited and converted to managed by setting this to &#x60;true&#x60;. | [optional] |
| **sources** | [**Array&lt;FlagSource&gt;**](FlagSource.md) | SDK-reported observations of this flag, grouped by service and environment. Populated automatically by the bulk-register endpoint. | [optional][readonly] |
| **created_at** | **Time** | When the flag was created. | [optional][readonly] |
| **updated_at** | **Time** | When the flag was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::Flag.new(
  name: null,
  description: null,
  type: null,
  default: null,
  values: null,
  environments: null,
  managed: null,
  sources: null,
  created_at: null,
  updated_at: null
)
```

