# SmplkitGeneratedClient::Flags::ManualReviewItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **flag** | **String** | Key of the flag containing the rule. |  |
| **environment** | **String** | Environment containing the rule. |  |
| **rule_index** | **Integer** | Position of the rule within the environment&#39;s &#x60;rules&#x60; array. |  |
| **reason** | **String** | Why the rule needs manual review. |  |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::ManualReviewItem.new(
  flag: null,
  environment: null,
  rule_index: null,
  reason: null
)
```

