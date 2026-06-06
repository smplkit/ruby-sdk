# SmplkitGeneratedClient::Audit::Forwarder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the forwarder. Must contain at least one non-whitespace character. |  |
| **description** | **String** | Free-text description for the forwarder. | [optional] |
| **forwarder_type** | [**ForwarderType**](ForwarderType.md) | Destination type. |  |
| **enabled** | **Boolean** | Always false. Enablement is per-environment: a forwarder delivers in an environment only when &#x60;environments[&lt;env&gt;].enabled&#x60; is true. The base value is pinned false and cannot be set. | [optional][readonly][default to false] |
| **filter** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against each event. The event is delivered only if the expression returns truthy. Omit to deliver every event. | [optional] |
| **transform_type** | **String** | Engine used to evaluate &#x60;&#x60;transform&#x60;&#x60;. Must be set whenever &#x60;&#x60;transform&#x60;&#x60; is set. Today only &#x60;JSONATA&#x60; is supported. | [optional] |
| **transform** | [**AnyOf**](AnyOf.md) | Template applied to each event before delivery. The shape depends on &#x60;&#x60;transform_type&#x60;&#x60;: for &#x60;JSONATA&#x60;, a string containing a JSONata expression. Omit to deliver the event JSON unchanged. | [optional] |
| **configuration** | [**HttpConfiguration**](HttpConfiguration.md) | Base delivery configuration template. Shape is discriminated by &#x60;&#x60;forwarder_type&#x60;&#x60;; today all destination types use &#x60;&#x60;HttpConfiguration&#x60;&#x60;. Branded vendor types (everything except &#x60;http&#x60;) constrain the configuration against a per-vendor template — see &#x60;GET /api/v1/forwarder_types&#x60; for the URL pattern, fixed headers, and customer-supplied placeholders for each type. A per-environment override in &#x60;environments&#x60; replaces this template for that environment. |  |
| **environments** | [**Hash&lt;String, ForwarderEnvironment&gt;**](ForwarderEnvironment.md) | Per-environment overrides keyed by environment key (e.g. &#x60;production&#x60;, &#x60;staging&#x60;). Each entry sets &#x60;enabled&#x60; (whether the forwarder delivers in that environment) and an optional &#x60;configuration&#x60; override (omit to inherit the base &#x60;configuration&#x60;). A forwarder with no entry for an environment is disabled there. Every referenced environment must exist and be managed for the account. | [optional] |
| **created_at** | **Time** | When the forwarder was created. | [optional][readonly] |
| **updated_at** | **Time** | When the forwarder was last modified. | [optional][readonly] |
| **deleted_at** | **Time** | When the forwarder was deleted. &#x60;null&#x60; for active forwarders. | [optional][readonly] |
| **version** | **Integer** | Monotonic counter incremented on every update, starting at 1. | [optional][readonly] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::Forwarder.new(
  name: null,
  description: null,
  forwarder_type: null,
  enabled: null,
  filter: null,
  transform_type: null,
  transform: null,
  configuration: null,
  environments: null,
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

