# SmplkitGeneratedClient::Audit::Forwarder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the forwarder. Must contain at least one non-whitespace character. |  |
| **description** | **String** | Free-text description for the forwarder. | [optional] |
| **forwarder_type** | [**ForwarderType**](ForwarderType.md) | Destination type. |  |
| **enabled** | **Boolean** | Always false. Enablement is per-environment: a forwarder delivers in an environment only when that environment&#39;s entry in &#x60;environments&#x60; sets &#x60;enabled&#x60; to true. The base value is pinned false and cannot be set. | [optional][readonly][default to false] |
| **forward_smplkit_events** | **Boolean** | When true, this forwarder also receives platform change events that smplkit records about your own resources (flag, configuration, and similar changes). Each such event is delivered through every environment this forwarder is enabled in, using that environment&#39;s resolved configuration. Defaults to false — platform change events are not forwarded unless you opt in. Independent of the per-environment &#x60;enabled&#x60; settings, since platform change events are not tied to a deployment environment. | [optional][default to false] |
| **filter** | **Hash&lt;String, Object&gt;** | JSON Logic expression evaluated against each event. The event is delivered only if the expression returns truthy. Omit to deliver every event. | [optional] |
| **transform_type** | **String** | Engine used to evaluate &#x60;&#x60;transform&#x60;&#x60;. Must be set whenever &#x60;&#x60;transform&#x60;&#x60; is set. Today only &#x60;JSONATA&#x60; is supported. | [optional] |
| **transform** | [**AnyOf**](AnyOf.md) | Template applied to each event before delivery. The shape depends on &#x60;&#x60;transform_type&#x60;&#x60;: for &#x60;JSONATA&#x60;, a string containing a JSONata expression. Omit to deliver the event JSON unchanged. | [optional] |
| **configuration** | [**HttpConfiguration**](HttpConfiguration.md) | Base delivery configuration template. Shape is discriminated by &#x60;&#x60;forwarder_type&#x60;&#x60;; today all destination types use &#x60;&#x60;HttpConfiguration&#x60;&#x60;. Branded vendor types (everything except &#x60;http&#x60;) constrain the configuration against a per-vendor template — see &#x60;GET /api/v1/forwarder_types&#x60; for the URL pattern, fixed headers, and customer-supplied placeholders for each type. A per-environment entry in &#x60;environments&#x60; overrides individual fields of this template for that environment; fields it omits are inherited from here. |  |
| **environments** | **Hash&lt;String, Hash&lt;String, Object&gt;&gt;** | Per-environment overrides keyed by environment key (e.g. &#x60;production&#x60;, &#x60;staging&#x60;). Each entry is a sparse map of only the fields that differ in that environment: &#x60;enabled&#x60; (whether the forwarder delivers there) plus any of &#x60;url&#x60;, &#x60;method&#x60;, &#x60;success_status&#x60;, &#x60;tls_verify&#x60;, &#x60;ca_cert&#x60;, and individual headers as &#x60;headers.&lt;name&gt;&#x60; (e.g. &#x60;headers.Authorization&#x60;). Fields you omit are inherited from the base &#x60;configuration&#x60;; an entry never needs to repeat the whole configuration. A forwarder with no entry for an environment is disabled there. Every referenced environment must exist and be managed for the account. | [optional] |
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
  forward_smplkit_events: null,
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

