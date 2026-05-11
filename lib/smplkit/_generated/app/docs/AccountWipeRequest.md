# SmplkitGeneratedClient::App::AccountWipeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **confirm** | **Boolean** | Must be &#x60;true&#x60; for the wipe to proceed. Any other value returns 400. |  |
| **generate_sample_data** | **Boolean** | When &#x60;true&#x60;, re-seed the account with the standard sample dataset after wiping. Best-effort: any seeding failure is logged but does not fail the wipe. | [optional][default to false] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::AccountWipeRequest.new(
  confirm: null,
  generate_sample_data: null
)
```

