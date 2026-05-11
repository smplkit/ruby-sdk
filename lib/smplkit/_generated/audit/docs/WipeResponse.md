# SmplkitGeneratedClient::Audit::WipeResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **wiped** | **Boolean** | Always &#x60;true&#x60; for a successful wipe. | [optional][default to true] |
| **tables** | [**WipeTablesSummary**](WipeTablesSummary.md) |  |  |
| **completed_at** | **Time** | When the wipe completed. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::WipeResponse.new(
  wiped: null,
  tables: null,
  completed_at: null
)
```

