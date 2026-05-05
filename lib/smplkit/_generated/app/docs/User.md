# SmplkitGeneratedClient::App::User

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** | User&#39;s email address |  |
| **display_name** | **String** |  |  |
| **profile_pic** | **String** |  | [optional] |
| **avatar_url** | **String** | Server-computed &#x60;&#x60;data:&#x60;&#x60; URL when an OIDC provider supplied a profile picture. Null otherwise — callers should fall back to Gravatar or initials. | [optional][readonly] |
| **auth_provider** | **String** |  | [optional][readonly] |
| **email_verified** | **Boolean** |  | [optional][readonly][default to false] |
| **role** | **String** | Role in current account context | [optional] |
| **account** | **String** | Account UUID | [optional][readonly] |
| **created_at** | **Time** |  | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::User.new(
  email: null,
  display_name: null,
  profile_pic: null,
  avatar_url: null,
  auth_provider: null,
  email_verified: null,
  role: null,
  account: null,
  created_at: null
)
```

