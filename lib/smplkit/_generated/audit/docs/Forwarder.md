# SmplkitGeneratedClient::Audit::Forwarder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the forwarder. Must contain at least one non-whitespace character. |  |
| **description** | **String** | Free-text description for the forwarder. | [optional] |
| **forwarder_type** | [**ForwarderType**](ForwarderType.md) | Destination type. |  |
| **enabled** | **Boolean** | Whether the forwarder is currently delivering events. Set to &#x60;false&#x60; to pause deliveries without deleting the forwarder. | [optional][default to true] |
| **filter** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against each event. The event is delivered only if the expression returns truthy. Omit to deliver every event. | [optional] |
| **transform_type** | **String** | Engine used to evaluate &#x60;&#x60;transform&#x60;&#x60;. Must be set whenever &#x60;&#x60;transform&#x60;&#x60; is set. Today only &#x60;JSONATA&#x60; is supported. | [optional] |
| **transform** | [**AnyOf**](AnyOf.md) | Template applied to each event before delivery. The shape depends on &#x60;&#x60;transform_type&#x60;&#x60;: for &#x60;JSONATA&#x60;, a string containing a JSONata expression. Omit to deliver the event JSON unchanged. | [optional] |
| **configuration** | [**HttpConfiguration**](HttpConfiguration.md) | Transport-specific delivery configuration. Shape is discriminated by &#x60;&#x60;forwarder_type&#x60;&#x60;; today all destination types use &#x60;&#x60;HttpConfiguration&#x60;&#x60;. Branded vendor types (everything except &#x60;http&#x60;) constrain the configuration against a per-vendor template — see &#x60;GET /api/v1/forwarder_types&#x60; for the URL pattern, fixed headers, and customer-supplied placeholders for each type. |  |
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
  created_at: null,
  updated_at: null,
  deleted_at: null,
  version: null
)
```

