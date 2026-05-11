# SmplkitGeneratedClient::App::RegisterRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** | Email address that becomes the new user&#39;s login identifier. |  |
| **password** | **String** | Password for the new account. Must be at least 8 characters. |  |
| **entry_point** | **String** | How the customer arrived at the registration page. Allowed values: &#x60;LOGIN&#x60;, &#x60;GET_STARTED&#x60;, &#x60;LIVE_DEMO&#x60;, &#x60;UNKNOWN&#x60;. Defaults to &#x60;UNKNOWN&#x60; when omitted. Case-insensitive on input. | [optional] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::RegisterRequest.new(
  email: null,
  password: null,
  entry_point: null
)
```

