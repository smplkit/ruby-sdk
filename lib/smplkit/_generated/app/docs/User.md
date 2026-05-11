# SmplkitGeneratedClient::App::User

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** | Email address used to sign in to the user account. | [optional][readonly] |
| **display_name** | **String** | Human-readable display name shown in the console and on shared resources. |  |
| **profile_pic** | **String** | URL of an external profile picture (e.g. the value supplied by the user&#39;s identity provider). | [optional] |
| **avatar_url** | **String** | Server-generated &#x60;data:&#x60; URL containing the user&#39;s avatar image bytes when one has been captured. &#x60;null&#x60; when no avatar is available — callers should fall back to Gravatar or initials. | [optional][readonly] |
| **auth_provider** | **String** | Identity provider that authenticates the user, e.g. &#x60;google&#x60;, &#x60;microsoft&#x60;, or &#x60;email&#x60;. | [optional][readonly] |
| **email_verified** | **Boolean** | Whether the user has completed email verification. | [optional][readonly][default to false] |
| **role** | **String** | Role the user holds in the current account context. One of &#x60;OWNER&#x60;, &#x60;ADMIN&#x60;, &#x60;MEMBER&#x60;, or &#x60;VIEWER&#x60;. | [optional] |
| **account** | **String** | UUID of the account the user is acting within. | [optional][readonly] |
| **created_at** | **Time** | When the user record was created. | [optional][readonly] |

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

