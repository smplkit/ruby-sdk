# SmplkitGeneratedClient::App::Invitation

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **email** | **String** | Email address the invitation was sent to. | [optional][readonly] |
| **role** | **String** | Role to assign on acceptance. One of &#x60;ADMIN&#x60;, &#x60;MEMBER&#x60;, or &#x60;VIEWER&#x60;. | [optional][readonly] |
| **status** | **String** | Lifecycle state of the invitation. One of &#x60;PENDING&#x60;, &#x60;ACCEPTED&#x60;, &#x60;REVOKED&#x60;, or &#x60;EXPIRED&#x60;. | [optional][readonly] |
| **invited_by** | **String** | UUID of the user who sent the invitation. | [optional][readonly] |
| **account_name** | **String** | Name of the account the recipient is being invited to join. | [optional][readonly] |
| **inviter_display_name** | **String** | Display name of the user who sent the invitation. | [optional][readonly] |
| **token** | **String** | Single-use token that the recipient redeems to accept the invitation. Echoed on responses so the inviting client can construct the acceptance link. | [optional][readonly] |
| **expires_at** | **Time** | When the invitation token stops being redeemable. | [optional][readonly] |
| **created_at** | **Time** | When the invitation was issued. | [optional][readonly] |
| **updated_at** | **Time** | When the invitation record was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Invitation.new(
  email: null,
  role: null,
  status: null,
  invited_by: null,
  account_name: null,
  inviter_display_name: null,
  token: null,
  expires_at: null,
  created_at: null,
  updated_at: null
)
```

