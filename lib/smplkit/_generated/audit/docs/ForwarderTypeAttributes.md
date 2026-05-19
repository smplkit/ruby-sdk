# SmplkitGeneratedClient::Audit::ForwarderTypeAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable label shown in the type-picker. |  |
| **icon** | **String** | Absolute URL to the icon asset, served by audit at &#x60;/api/v1/forwarder_types/{id}/icon&#x60;. |  |
| **base_type** | **String** | Transport family — today only &#x60;HTTP&#x60;. New base types will add their own configuration shape and runtime handler. |  |
| **docs_url** | **String** | Link to the vendor&#39;s own documentation for this destination. | [optional] |
| **is_custom** | **Boolean** | True for the synthetic &#x60;http&#x60; Custom HTTP entry, which has no vendor template — the customer supplies URL, headers, and transform from scratch. False for branded types. |  |
| **configuration** | [**ForwarderTypeHttpConfiguration**](ForwarderTypeHttpConfiguration.md) | Delivery template. Shape depends on &#x60;base_type&#x60;. |  |
| **placeholders** | [**Hash&lt;String, ForwarderTypePlaceholder&gt;**](ForwarderTypePlaceholder.md) | UI metadata keyed by placeholder name. Each &#x60;{name}&#x60; token appearing in &#x60;configuration&#x60; (URL, header value) has a matching entry here describing how to prompt for it. |  |
| **transform** | [**ForwarderTypeTransform**](ForwarderTypeTransform.md) | Default transform shipped with the type, or &#x60;null&#x60; if none. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypeAttributes.new(
  name: null,
  icon: null,
  base_type: null,
  docs_url: null,
  is_custom: null,
  configuration: null,
  placeholders: null,
  transform: null
)
```

