# SmplkitGeneratedClient::Audit::EventTypeAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **event_type** | **String** | The event_type slug. Same as the JSON:API &#x60;&#x60;id&#x60;&#x60;. |  |
| **created_at** | **Time** | First sighting of this event_type for the account. When the request includes &#x60;&#x60;filter[resource_type]&#x60;&#x60;, this is the first sighting of the (event_type, resource_type) triple rather than the event_type overall. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::EventTypeAttributes.new(
  event_type: null,
  created_at: null
)
```

