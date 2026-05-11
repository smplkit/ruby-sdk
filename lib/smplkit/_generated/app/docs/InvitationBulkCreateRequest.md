# SmplkitGeneratedClient::App::InvitationBulkCreateRequest

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **invitations** | [**Array&lt;InvitationCreateItem&gt;**](InvitationCreateItem.md) | One to fifty invitations to send in a single request. |  |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::InvitationBulkCreateRequest.new(
  invitations: null
)
```

