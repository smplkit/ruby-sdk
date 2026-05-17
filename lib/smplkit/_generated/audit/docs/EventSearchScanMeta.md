# SmplkitGeneratedClient::Audit::EventSearchScanMeta

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **scanned** | **Integer** | Rows scanned after column filters narrowed the candidate set, before the JSON Logic expression was applied. |  |
| **matched** | **Integer** | Rows the JSON Logic expression matched. Equal to &#x60;len(data)&#x60; for the page being returned plus any matches found beyond the page size. |  |
| **exhausted** | **Boolean** | &#x60;true&#x60; if the server hit the per-request scan ceiling before finding &#x60;page[size]&#x60; matches. When true, paginate again with the returned &#x60;links.next&#x60; cursor to continue scanning past the ceiling. |  |

## Example

```ruby
require 'smplkit_audit_client'

instance = SmplkitGeneratedClient::Audit::EventSearchScanMeta.new(
  scanned: null,
  matched: null,
  exhausted: null
)
```

