# SmplkitGeneratedClient::App::Environment

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the environment. |  |
| **color** | **String** | Display color used by the console to badge the environment. Accepts any CSS color string. | [optional] |
| **classification** | **String** | &#x60;STANDARD&#x60; for environments deliberately created (and shown by default in the environment grid); &#x60;AD_HOC&#x60; for auto-discovered environments seen in SDK traffic (hidden from the default view). Case-insensitive on input. Independent of the &#x60;managed&#x60; flag. | [optional][default to &#39;STANDARD&#39;] |
| **managed** | **Boolean** | When &#x60;true&#x60;, per-environment resource values can be set against this environment and it counts toward the account&#39;s managed-environments quota. When &#x60;false&#x60;, the environment is view-only: existing values are displayed for comparison but no new values can be written. Promotion and demotion flip this boolean via &#x60;PUT /api/v1/environments/{id}&#x60;; promotion is subject to the quota. | [optional][default to false] |
| **created_at** | **Time** | When the environment was created. | [optional][readonly] |
| **updated_at** | **Time** | When the environment was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Environment.new(
  name: null,
  color: null,
  classification: null,
  managed: null,
  created_at: null,
  updated_at: null
)
```

