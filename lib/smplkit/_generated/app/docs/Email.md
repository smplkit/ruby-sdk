# SmplkitGeneratedClient::App::Email

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **topic** | [**ContactTopic**](ContactTopic.md) |  |  |
| **body** | **String** | Free-form text of the message. Trimmed before validation. |  |
| **sent_at** | **Time** | When the message was accepted by the server. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Email.new(
  topic: null,
  body: null,
  sent_at: null
)
```

