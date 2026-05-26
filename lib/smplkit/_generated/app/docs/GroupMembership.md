# SmplkitGeneratedClient::App::GroupMembership

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **user** | **String** | UUID of the user this membership links. Required on create; immutable thereafter. |  |
| **group** | **String** | Key (id) of the group this membership links. Required on create; immutable thereafter. |  |
| **created_at** | **Time** | When the membership was created. | [optional][readonly] |
| **updated_at** | **Time** | When the membership record was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::GroupMembership.new(
  user: null,
  group: null,
  created_at: null,
  updated_at: null
)
```

