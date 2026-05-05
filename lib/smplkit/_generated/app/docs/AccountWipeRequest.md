# SmplkitGeneratedClient::App::AccountWipeRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **confirm** | **Boolean** | Must be &#x60;&#x60;true&#x60;&#x60; to proceed. Anything else returns 400. The frontend gates the call behind a confirmation dialog; this field is the server-side seatbelt. |  |
| **generate_sample_data** | **Boolean** | When &#x60;&#x60;true&#x60;&#x60;, the wipe re-seeds the account with the same Acme Commerce sample dataset that new accounts are bootstrapped with. Best-effort: any seeding failures are logged but do not fail the wipe. | [optional][default to false] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::AccountWipeRequest.new(
  confirm: null,
  generate_sample_data: null
)
```

