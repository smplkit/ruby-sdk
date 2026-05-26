# SmplkitGeneratedClient::App::Group

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Human-readable name for the group. |  |
| **description** | **String** | Free-text description shown on the group&#39;s detail page. | [optional] |
| **managed_environments** | **Array&lt;String&gt;** | The set of environments members of this group may manage. Either the exact value &#x60;[\&quot;*\&quot;]&#x60; to grant every standard environment, or an explicit array of standard environment keys. Ad-hoc environments are never listed here — they are exempt from group governance and remain manageable by every member of the account. | [optional] |
| **system** | **Boolean** | True for built-in groups the platform reserves. The &#x60;default&#x60; group has &#x60;system&#x3D;true&#x60;; it cannot be deleted or renamed, though its &#x60;managed_environments&#x60; may be narrowed. | [optional][readonly][default to false] |
| **created_at** | **Time** | When the group was created. | [optional][readonly] |
| **updated_at** | **Time** | When the group was last modified. | [optional][readonly] |

## Example

```ruby
require 'smplkit_app_client'

instance = SmplkitGeneratedClient::App::Group.new(
  name: null,
  description: null,
  managed_environments: null,
  system: null,
  created_at: null,
  updated_at: null
)
```

