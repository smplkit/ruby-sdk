# SmplkitGeneratedClient::App::InvitationCreateItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** | Email address to send the invitation to. |  |
| **role** | **String** | Role to assign on acceptance. One of &#x60;ADMIN&#x60;, &#x60;MEMBER&#x60;, or &#x60;VIEWER&#x60;. &#x60;OWNER&#x60; cannot be assigned via invitation. Case-insensitive on input. | [optional][default to &#39;MEMBER&#39;] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::InvitationCreateItem.new(
  email: null,
  role: null
)
```

