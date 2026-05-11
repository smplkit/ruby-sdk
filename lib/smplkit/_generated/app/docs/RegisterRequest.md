# SmplkitGeneratedClient::App::RegisterRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** |  |  |
| **password** | **String** |  |  |
| **entry_point** | **String** | Registration entry point. Allowed: LOGIN, GET_STARTED, LIVE_DEMO, UNKNOWN. Defaults to UNKNOWN when omitted. Case-insensitive. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::RegisterRequest.new(
  email: null,
  password: null,
  entry_point: null
)
```

