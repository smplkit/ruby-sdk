# SmplkitGeneratedClient::Flags::FlagBulkItem

## Properties

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | Flag key as declared in code. URL-safe and stable for the lifetime of the flag. |  |
| **type** | **String** | Value type the SDK declared for the flag. Accepted case-insensitively. |  |
| **default** | **Object** |  |  |
| **service** | **String** | Service reporting the declaration. Defaults to &#x60;unknown&#x60;. | [optional] |
| **environment** | **String** | Environment reporting the declaration. Defaults to &#x60;unknown&#x60;. | [optional] |

## Example

```ruby
require 'smplkit_flags_client'

instance = SmplkitGeneratedClient::Flags::FlagBulkItem.new(
  id: null,
  type: null,
  default: null,
  service: null,
  environment: null
)
```

