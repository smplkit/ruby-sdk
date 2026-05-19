# SmplkitGeneratedClient::Audit::ForwarderTypePlaceholder

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **label** | **String** | Human-readable label for the input. |  |
| **secret** | **Boolean** | If true, mask the value in the UI and treat as a credential. | [optional][default to false] |
| **enum** | **Array&lt;String&gt;** | If set, the value must be one of the listed strings — render as a dropdown. | [optional] |
| **default** | **String** | Pre-selected value when &#x60;enum&#x60; is set, or the default for a free-text field. | [optional] |
| **placeholder** | **String** | HTML-input hint text shown when the field is empty. | [optional] |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ForwarderTypePlaceholder.new(
  label: null,
  secret: null,
  enum: null,
  default: null,
  placeholder: null
)
```

