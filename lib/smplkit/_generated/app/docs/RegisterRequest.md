# SmplkitGeneratedClient::App::RegisterRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** |  |  |
| **password** | **String** |  |  |
| **entry_point** | **String** | Registration entry point. Allowed: login, get_started, live_demo, unknown. Defaults to unknown when omitted. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::RegisterRequest.new(
  email: null,
  password: null,
  entry_point: null
)
```

