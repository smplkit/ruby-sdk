# SmplkitGeneratedClient::Flags::RemoveReferencesAttributes

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **flags_modified** | **Array&lt;String&gt;** | Keys of flags whose rules were modified. |  |
| **rules_removed** | **Integer** | Total number of rules removed across all flags. |  |
| **rules_needing_manual_review** | [**Array&lt;ManualReviewItem&gt;**](ManualReviewItem.md) | Rules that referenced the context but could not be removed automatically (typically because the reference is inside an &#x60;and&#x60; expression where removal would broaden the rule). |  |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::RemoveReferencesAttributes.new(
  flags_modified: null,
  rules_removed: null,
  rules_needing_manual_review: null
)
```

