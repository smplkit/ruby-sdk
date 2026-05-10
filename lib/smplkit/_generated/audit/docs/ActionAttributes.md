# SmplkitGeneratedClient::Audit::ActionAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **action** | **String** | The action slug. Same as the JSON:API &#x60;&#x60;id&#x60;&#x60;. |  |
| **created_at** | **Time** | First sighting of this action for the account. When the request includes &#x60;&#x60;filter[resource_type]&#x60;&#x60;, this is the first sighting of the (action, resource_type) triple rather than the action overall. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::ActionAttributes.new(
  action: null,
  created_at: null
)
```

