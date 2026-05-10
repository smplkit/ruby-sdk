# SmplkitGeneratedClient::Audit::WipeResponse

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **wiped** | **Boolean** |  | [optional][default to true] |
| **tables** | [**WipeTablesSummary**](WipeTablesSummary.md) |  |  |
| **completed_at** | **Time** |  |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::WipeResponse.new(
  wiped: null,
  tables: null,
  completed_at: null
)
```

